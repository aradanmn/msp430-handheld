# Lesson 25 — External SRAM

## Topic

Every drawing primitive since Lesson 14 has written into a framebuffer that
lives in the MSP430's own 512 B of RAM. That was fine for a border and a
single tetromino. It stops being fine once the game needs a full-screen
buffer, a growing board array, a stack, and I/O scratch space all competing
for the same 512 bytes — the display alone can easily need more bytes than
the whole chip has to offer. This lesson adds a second SPI device, a
23LC1024 128 KB serial SRAM chip, and moves the framebuffer off-chip onto it.

Talking to the SRAM means learning a second SPI *protocol* on top of the
transport layer you already built in Lesson 12 — same wires, same
`spi_tx_byte`, different device-specific conversation. You'll also confront
a real systems problem: shipping the *entire* framebuffer over SPI every
single frame is wasteful once only a few pixels changed. The dirty-region
strategy in Tutorial 2 is how you avoid paying for that every tick.

## Learning Objectives

By the end of this lesson you will be able to:

- Describe the 23LC1024's SPI transaction format: opcode byte, 3-byte
  address, data byte(s), all under one continuous CS-low window
- Explain *why* chip select must stay asserted for an entire multi-byte
  transaction, in terms of the chip's internal state machine
- Reuse an established SPI transport (`spi_tx_byte`) to drive a second,
  independent device on the same bus with its own chip-select line
- Explain why a real display's framebuffer usually can't fit in an MSP430's
  on-chip RAM budget once the rest of the program's state is accounted for
- Explain the dirty-region sync strategy and why it amortizes SPI's
  per-transaction overhead better than a byte-at-a-time or whole-buffer sync

## What You'll Build

`examples/sram_test.s` — writes a test byte to a chosen SRAM address, reads
it back, and lights LED1 solid on a match (blinks on a mismatch).

`exercises/ex1` — the same round-trip test, with your own address and byte
pattern, built from the protocol description in Tutorial 1 rather than
copied from the example.

`exercises/ex2` — a working round-trip tester whose pass/fail behavior looks
inconsistent from address to address, with no obvious pattern to it.

`exercises/ex3` (**Milestone**) — converts `handheld/gfx/framebuf.s` (from
the Lesson 14 milestone) to store its pixel data in SRAM instead of on-chip
RAM, while keeping its existing pixel-level interface's observable behavior
unchanged. Adds a new `framebuf_flush_dirty` entry point that syncs only
what actually changed. See `exercises/ex3/README.md`.

## New Hardware This Lesson

A 23LC1024 SPI SRAM chip joins the bus already carrying the OLED
(SCLK = P1.5, MOSI = P1.7, SOMI = P1.6 — see Lesson 12). It needs its own
chip-select line. P2.0–P2.4 are already claimed (OLED CS/DC/RST, the
shift-register's PL, and PWM audio, per `ROADMAP.md`), so this lesson
introduces **P2.5 as `SRAM_CS`** — a brand-new GPIO assignment, not
something that existed in any earlier lesson. You'll define it yourself as
a local `.equ` in every file that needs it (it isn't in
`msp430g2553-defs.s` — this chip is new to the course).

## Game Connection

Once the framebuffer moves to SRAM, the OLED's pixel data has effectively
unlimited headroom compared to the 512 B budget every earlier lesson had to
respect. That's what makes room for the rest of the game's state — the
board array, piece state, score, sound sequencer — to coexist comfortably
in on-chip RAM without the framebuffer crowding everything else out.

## Datasheet Reference

- **Microchip 23LC1024 datasheet** — instruction set (READ/WRITE opcodes),
  addressing (24-bit field, only the low 17 bits significant for 128 KB),
  timing (CS must remain asserted for the whole instruction)
- **SLAU144, Chapter 16** — USCI SPI Mode (review from Lesson 12 — the
  transport layer doesn't change, only what you send over it)

## Read First

1. `tutorial-01-23lc1024-spi-protocol.md` — the SRAM's SPI instruction
   format and why CS must stay low for the whole transaction
2. `tutorial-02-dirty-region-sync.md` — why the framebuffer has to move
   off-chip, and the dirty-region strategy for syncing it efficiently

## Then

Attempt the exercises before studying `examples/sram_test.s` — it's the
reference, not the starting point.

## Exercises

See `exercises/README.md`.

## Success Criteria

- [ ] I can describe the 23LC1024's READ and WRITE transaction format:
      opcode byte, 3 address bytes (MSB first), then data — all under one
      continuous CS-low window
- [ ] I can explain, in terms of the chip's internal state machine, why
      deasserting CS in the middle of a transaction breaks it
- [ ] `examples/sram_test.s` builds, flashes, and lights LED1 solid when the
      byte written matches the byte read back
- [ ] I can explain why the framebuffer eventually outgrows on-chip RAM, and
      what a dirty-region sync buys you over syncing the whole buffer every
      frame
- [ ] `exercises/ex3`: `handheld/gfx/framebuf.s` is SRAM-backed, its existing
      pixel-level calls still behave the same way externally, and
      `framebuf_flush_dirty` exists and only syncs changed regions
