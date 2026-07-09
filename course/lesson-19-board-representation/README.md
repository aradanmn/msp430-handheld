# Lesson 19 — Board Representation

## Topic

Every Tetris game needs to answer one question, over and over, dozens of
times per frame: *is this cell filled?* This lesson builds the data
structure that answers it — the 10x20 playing field, packed into RAM as one
bit per cell rather than one byte per cell. That difference (25 bytes vs.
200 bytes) is not a micro-optimization; on a chip with 512 bytes of RAM
total, it's the difference between a board that fits comfortably alongside
everything else the handheld needs to keep in memory, and one that doesn't.

This lesson has no new peripheral. There's no GPIO, no timer, no SPI. It's
pure data-structure and addressing-math work: how do you compute *which
byte, which bit* a given `(row, col)` lives in, using only the instructions
you already know (shifts, adds, `AND`, `BIS`/`BIC`/`BIT`) — because the
MSP430G2553 has no hardware multiply instruction to lean on.

## Learning Objectives

By the end of this lesson you will be able to:

- Explain, with real numbers, why a packed 1-bit-per-cell board costs 25
  bytes against this chip's 512 bytes of RAM, versus 200 bytes for a
  byte-per-cell board
- Compute `bit_index`, `byte_offset`, and `bit_within_byte` by hand for any
  `(row, col)` pair, given a stated row-major, MSB-first convention
- Explain why row-major layout (not column-major) matters for a
  full-row-clear check that a later lesson will need
- Compute `row * 10` (or any compile-time constant multiply) using shifts
  and adds, with no multiply instruction available
- Explain, from first principles, why calling a bit-addressed accessor with
  an out-of-range index can silently corrupt unrelated memory instead of
  crashing

## What You'll Build

`examples/board_demo.s` — a standalone program that implements
`board_init`/`board_get`/`board_set` inline and self-tests them against
known cells (including two edge cases and a byte-boundary straddle), solid
LED1 for all-pass, blinking LED1 for any failure.

`exercises/ex1` — the same idea, built by you from the spec.

`exercises/ex2` — a complete program with a real, observable failure baked
into how it's used; you have to explain why.

`exercises/ex3` — the milestone: `handheld/game/tetris.s` is created for the
first time, with the board's `board_init`/`board_get`/`board_set`. Lessons
20-22 all extend this same file.

## How This Connects to the Handheld

Every rule Tetris has — can this piece move here, is this row full, did the
stack reach the top — ultimately comes down to reading and writing this
board. Lesson 20 encodes the pieces that get stamped onto it. Lesson 21
checks whether a piece's cells collide with cells this board already has
marked filled. Lesson 22 scans rows of it looking for lines to clear. None
of that is possible without a board representation that's both compact
enough to fit in 512 bytes of RAM and cheap enough to query many times per
frame — which is exactly what this lesson builds.

## Read First

1. `tutorial-01-packed-bit-arrays.md` — the RAM budget argument, the bit
   convention, worked `(row, col)` → bit-index examples
2. `tutorial-02-addressing-and-row-major.md` — tracing `board_get`/`board_set`
   through the math step by step, and why row-major beats column-major for
   this game
3. **Datasheet:** there is no new peripheral chapter this lesson. Reread
   SLAU144 Ch. 3 (CPU) for the instruction set if the shift/rotate
   instructions (`RLA`, `RRA`) feel rusty — Lessons 02-03 covered them.

## Then

Attempt the exercises before flashing `examples/board_demo.s`. The example
is the working reference — study it *after* you've built your own.

## Exercises

See `exercises/README.md`.

## Success Criteria

- [ ] I can state, from memory, the byte cost of a packed board (25 bytes)
      vs. a byte-per-cell board (200 bytes) and why that difference matters
      on this chip
- [ ] I can compute `bit_index`, `byte_offset`, and `bit_within_byte` by
      hand for any `(row, col)` I'm given, using this lesson's convention
- [ ] I can explain, without looking it up, why `row * 10` needs shifts and
      adds instead of a single multiply instruction on this CPU
- [ ] I can explain in my own words why row-major (not column-major) layout
      makes a full-row-clear check cheap
- [ ] `examples/board_demo.s` builds, flashes, and lights LED1 solid (every
      internal check passes)
- [ ] `exercises/ex1` and `exercises/ex2` each build, flash, and behave per
      their own success criteria (see `exercises/README.md`)
- [ ] `exercises/ex3`'s milestone spec is met: `handheld/game/tetris.s`
      exists with `board_init`/`board_get`/`board_set` and `cd handheld &&
      make` builds cleanly
