# Lesson 22 — Line Clear & Scoring

## Topic

`piece_place` (Lesson 21) can now stamp a piece permanently onto the board.
The instant that happens, the board might contain one or more completely
full rows — ten occupied columns in a row — and Tetris rules say those rows
disappear, everything above them drops down by one, and the player is
rewarded with points. This lesson builds that: a routine that scans the
board for full rows, a routine that removes one and shifts everything above
it down, and the scoring/leveling arithmetic that turns "N lines cleared at
once" into points and, eventually, a faster game.

The interesting engineering wrinkle this lesson: Lesson 19's board packs 10
bits per row with no padding, and 10 doesn't divide 8. That means a row's
bits routinely straddle a byte boundary — "is this row full" can't always
be answered by looking at one byte. Tutorial 01 works through exactly how
to read across that boundary correctly.

## Learning Objectives

By the end of this lesson you will be able to:

- Compute a packed board's bit offset for a given row (`row * 10`) and
  split that into a byte index and a bit-within-byte offset
- Explain why a row's 10 bits can straddle two bytes, read both bytes,
  combine them into a 16-bit window, and extract exactly that row's bits
  with a shift and a mask
- Determine whether an extracted row value represents a "full" row by
  comparing it against an all-ones mask for the column count
- Explain the shift-down operation a cleared line requires: every row above
  the cleared one moves down by one, and the top row becomes empty
- Compute Tetris line-clear scores (100/300/500/800 for 1/2/3/4 lines) with
  `.equ` arithmetic, and describe the "every 10 lines, level up" rule and
  why leveling up means handing a new, shorter period to the timer module

## What You'll Build

`examples/lineclear_demo.s` — a hardcoded test board with one deliberately
full row among several partial rows (including a row that straddles a byte
boundary). Detects the full row, clears it, shifts everything above it
down, and checks the resulting bytes against a hand-computed expected
result. LED1 solid on all-pass, blinking on any mismatch.

`exercises/ex1` — the same detection step, on a different board: is one
specific row full?

`exercises/ex2` — a working full-row detector and a shift-down routine that
clears a line correctly for the rows above it, but leaves the rows below
the cleared line in a state that matches neither their original content nor
an empty row. Find out why.

`exercises/ex3` (**Milestone**) — extend `handheld/game/tetris.s` with
`board_check_lines`, `board_clear_line`, and `score_add_lines`, on top of
everything Lessons 19–21 already built there. See `exercises/ex3/README.md`.

## Game Connection

This is the payoff mechanic of Tetris — the moment a stack of careful (or
lucky) placements turns into cleared lines and rising points, and the
moment the game starts getting harder in response to how well you're doing.
Every piece from here to the end of the course eventually funnels through
this lesson's logic: placed, checked for full lines, scored, and — if
enough lines have accumulated — handed off to a faster gravity tick.

## Datasheet Reference

No new peripheral this lesson — it's bit-packing and arithmetic on top of
the board representation from Lesson 19.

- **SLAU144, Chapter 3** — status register flags, relevant again for the
  shift/mask sequence this lesson's row-extraction needs

## Success Criteria

- [ ] I can compute, for any row index, the byte index and bit-within-byte
      offset its 10 packed bits start at
- [ ] I can explain why a two-byte read is always enough here (never a
      third byte) — specifically, what property of "10 bits per row" makes
      the bit-within-byte offset only ever land on an even value
- [ ] I can describe the shift-down step: rows above the cleared line each
      move down by one, the top row becomes empty, rows below the cleared
      line are untouched
- [ ] I can compute the Tetris scoring table (100/300/500/800) and state
      the level-up rule (every 10 lines) using `.equ` arithmetic
- [ ] `examples/lineclear_demo.s` builds and flashes; LED1 lands solid,
      confirming the full row is correctly identified, cleared, and
      shifted to match the hand-computed expected board
- [ ] `exercises/ex1`, `ex2`, and `ex3` each meet their own success criteria
      (see `exercises/README.md` and `exercises/ex3/README.md`)
