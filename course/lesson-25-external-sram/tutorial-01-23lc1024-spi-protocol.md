# Tutorial 01 — The 23LC1024's SPI Instruction Protocol

## A Second Device, the Same Bus

Lesson 12 built one transport primitive, `spi_tx_byte`, and Tutorial 02 of
that lesson made a point of it: `spi_tx_byte` doesn't know or care what the
bytes flowing through it mean. That design pays off directly here. The
23LC1024 wants Mode 0, MSB-first, same as the OLED — the exact SPI mode
`spi_init` from Lesson 12 already configures. Nothing about USCI_B0's setup
changes. What's new is entirely at the *device protocol* level: what bytes
to send, in what order, to make this specific chip do what you want.

Every device sharing the bus gets its own chip-select line so only one of
them is "listening" at a time (Lesson 12, Tutorial 01). The OLED's CS is
P2.0. The SRAM needs a CS pin of its own — P2.0 through P2.4 are already
spoken for by the OLED (CS/DC/RST) and the shift-register/audio hardware
from Phase 4, so this lesson claims **P2.5** as `SRAM_CS`. It's a brand-new
GPIO assignment: it isn't in `msp430g2553-defs.s`, because this chip didn't
exist in the course before this lesson. Define it yourself:

```asm
.equ    SRAM_CS,    BIT5      ; P2.5 — new in Lesson 25: 23LC1024 chip select
```

## The Instruction Format

Every 23LC1024 transaction has the same three-part shape:

```
CS low
  → opcode byte      (what operation: READ or WRITE)
  → 3 address bytes   (24-bit field, MSB first; only the low 17 bits matter)
  → data byte(s)      (written out on WRITE, clocked in on READ)
CS high
```

Two opcodes matter for this lesson:

| Opcode | Value | Operation |
|--------|-------|-----------|
| READ   | `0x03` | Read one or more bytes starting at the given address |
| WRITE  | `0x02` | Write one or more bytes starting at the given address |

## The Address Field

The chip's instruction format reserves a full 24 bits (3 bytes) for the
address, sent MSB first — same big-endian-over-the-wire convention as every
other multi-byte value this course has sent over SPI. But the 23LC1024 only
has 128 KB (2^17 bytes) of actual memory, so only the **low 17 bits** of
that 24-bit field are meaningful. The upper 7 bits of the address field
don't correspond to any real memory location on this chip — send them as 0.

Splitting a 24-bit address into the 3 bytes the chip expects is exactly the
kind of thing this course has done with `.equ` arithmetic since Lesson 04:

```asm
.equ    SOME_ADDR,      0x01A2B         ; a 17-bit address (0x00000-0x1FFFF)
.equ    SOME_ADDR_HI,   (SOME_ADDR >> 16) & 0xFF   ; bits 23-16 (always 0 here)
.equ    SOME_ADDR_MID,  (SOME_ADDR >> 8)  & 0xFF   ; bits 15-8
.equ    SOME_ADDR_LO,   SOME_ADDR & 0xFF           ; bits 7-0
```

Each of those three bytes goes out over `spi_tx_byte`, MSB-first byte order,
right after the opcode.

## Why CS Must Stay Low for the Whole Transaction

This is the detail that trips people up, and it's worth understanding *why*,
not just *that*. The 23LC1024 doesn't parse "a READ command" as a single
atomic unit the instant it sees `0x03`. Internally, it's a state machine:
seeing CS go low resets it to an "expecting an opcode" state; each
subsequent bit it clocks in on MOSI advances it through
opcode → address-byte-1 → address-byte-2 → address-byte-3 → data, in strict
order. The chip has no other way of knowing "which byte of the address is
this" or "are we still in the address field or already at data" — the
*only* thing telling it where it is in that sequence is how many clock
edges it has counted since CS last went low.

If CS goes high in the middle — say, right after the address bytes, before
the data byte — the chip's state machine resets back to "expecting an
opcode" the moment CS is deasserted. Reasserting CS and clocking out what
you intended as the data byte doesn't resume the interrupted transaction;
it starts a brand new one, with that byte now being interpreted as a fresh
opcode. Whatever you meant to write never happens, and depending on what
that stray byte looks like to the chip, the "new" instruction it thinks
it just received may do nothing recognizable at all. There is no partial
transaction, no resume-where-you-left-off — CS-low *is* the transaction
boundary, full stop.

This is why `spi_tx_byte` itself has no idea CS exists (Lesson 12): holding
CS low across an opcode, three address bytes, and one or more data bytes
is a decision that belongs entirely to the SRAM-specific code layered on
top of the shared transport, not to the transport itself.

## What's Next

Tutorial 02 covers why this chip needs to exist in the design at all — the
framebuffer's actual size problem — and the dirty-region strategy for
syncing it without paying SPI's per-byte overhead on every single pixel,
every single frame.
