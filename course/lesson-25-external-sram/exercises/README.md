# Lesson 25 Exercises

Read both tutorials first. Wire the 23LC1024 SRAM onto the existing SPI bus
(SCLK = P1.5, MOSI = P1.7, SOMI = P1.6) with its chip-select line on
**P2.5** (new this lesson — see the lesson `README.md`). Attempt Exercise 1
before looking at `examples/sram_test.s` — it's the reference, not the
starting point.

---

## Exercise 1 — Explore: SRAM Read/Write Round Trip

**Directory:** `ex1/`

**File:** `ex1/sram_roundtrip.s`

Write a byte pattern of your choosing to an address of your choosing on the
23LC1024, read it back, and verify the two match — light LED1 solid on a
match, leave it off otherwise.

**What to look up:**
- The 23LC1024 datasheet's instruction set: the opcode bytes for its READ
  and WRITE operations, and the format of the address field that follows
  each one (Tutorial 01 covers the shape of the transaction; the exact
  opcode values are also documented directly in Tutorial 01)
- Your own Lesson 12 `spi_init`/`spi_tx_byte` — this exercise reuses that
  transport exactly as-is; nothing about the SPI peripheral configuration
  changes for a second device on the same bus, only the bytes you choose to
  send over it and which chip-select pin you drive

**Success criteria:**
- [ ] `SRAM_CS` (P2.5) is configured as an output and idles HIGH
      (deasserted) before any transaction begins
- [ ] Your address is split into 3 bytes (MSB first) using `.equ`
      arithmetic, not hand-computed and pasted in as bare hex bytes
- [ ] CS is asserted once at the start of each transaction and deasserted
      once at the end — not toggled in between the opcode, address, and
      data bytes
- [ ] LED1 lights solid when the byte you wrote and the byte you read back
      match

---

## Exercise 2 — Challenge: Intermittent Round-Trip Failures

**Directory:** `ex2/`

**File:** `ex2/sram_intermittent.s`

This file configures the SPI bus, writes a handful of test bytes to a
handful of different SRAM addresses, reads each one back, and reports the
number of addresses that matched by blinking LED1 that many times, then
repeating. Build it, flash it, and watch the blink count.

**Observable failure:** the blink count isn't consistent with "everything
works." Some addresses read back the value that was written; most don't.
There's no obvious pattern to which ones succeed — it isn't the first
address, or the last, or every other one, or anything else you can predict
in advance. Re-flashing and re-running doesn't make it any more consistent.

Your job: figure out what's structurally different about this file's SRAM
transaction handling compared to a working round trip, and explain what
about that difference would produce results that look effectively random
per address rather than uniformly broken or uniformly correct.

**Success criteria:**
- [ ] I can describe the observed behavior precisely (which addresses
      matched on a given run, and that a re-run doesn't reliably reproduce
      the same pattern)
- [ ] I can point to the specific place in the SRAM read/write routines
      where the code's behavior diverges from "CS stays low for one
      continuous opcode+address+data sequence"
- [ ] After my fix, every test address matches, every run, consistently

---

## Exercise 3 — Milestone: `handheld/gfx/framebuf.s` → SRAM-Backed

**Directory:** `ex3/`

**What to change:** `handheld/gfx/framebuf.s` — this is a conversion of the
module you already wrote for the Lesson 14 milestone, not a rewrite from
scratch.

See `ex3/README.md` for the full spec.

**Build & test:** `cd handheld && make && make flash`

**Success criteria:** compiles cleanly as part of the handheld build; every
pixel-level call your Lesson 14 module already exposed still behaves the
same way externally; `framebuf_flush_dirty` exists and demonstrably syncs
less data than a full-buffer push when only a small region changed.
