# Lesson 20 — Tetrominoes & Rotation

## Topic

Lesson 19 built a place to put filled cells. This lesson builds the thing
that gets stamped into it: the 7 standard tetrominoes (I, O, T, S, Z, J, L),
each as a 4x4 grid, each with 4 rotation states. Encoded as 16-bit words —
one `.word` per rotation, packed exactly the way a 4x4 grid of bits fits
exactly one 16-bit register — this is 8 bytes of Flash per piece, 56 bytes
for all 7 shapes, entirely in Flash (not RAM, since these shapes never
change at runtime).

Like Lesson 19, this lesson introduces no new peripheral. It's addressing
math again, applied to a Flash lookup table instead of a RAM bit array, plus
a new idea on top: a **rotation state machine** — a piece doesn't just have
one shape, it cycles through 4, and "rotate" has to mean "advance to the
next one, wrapping back to the first after the fourth."

## Learning Objectives

By the end of this lesson you will be able to:

- Encode a 4x4 tetromino shape as a single 16-bit word, using this course's
  row-major, MSB-first convention
- Compute a Flash table address for `(piece, rotation)` using indexed
  addressing (`table + piece*8 + rotation*2`)
- Extract a single cell's bit from a 16-bit rotation word at runtime, using
  the same shift-and-mask technique from Lesson 19
- Trace a piece through all 4 rotation states in sequence and explain why
  the 4th rotation must wrap back to the 1st (rotation index mod 4)
- Explain the difference between computing a rotation live vs. looking one
  up from a precomputed table, and why this course uses a table

## What You'll Build

`examples/piece_demo.s` — encodes the T-piece's 4 rotations as a Flash
table, implements `piece_cell(rotation, row, col)` extracting a single cell
via bit math, and self-tests all 64 cell/rotation combinations. Solid LED1
for all-pass, blinking LED1 for any failure.

`exercises/ex1` — encode all 7 tetrominoes yourself, and build a rotation
function for one of them.

`exercises/ex2` — a complete program with a real, observable rotation bug
baked in; you have to explain why.

`exercises/ex3` — the milestone: extend `handheld/game/tetris.s` (created
in Lesson 19) with `piece_rotation_cw` and `piece_cell`, alongside the
existing `board_*` functions.

## Reference: The 7 Tetrominoes (Spawn Orientation)

This is public-domain game-design knowledge — the shapes themselves are not
the exercise. The exercise is encoding and addressing them. Each grid below
is 4 columns x 4 rows; `X` marks a filled cell, `.` an empty one.

```
I:  . . . .     O:  . . . .     T:  . . . .     S:  . . . .
    X X X X         . X X .         . X . .         . X X .
    . . . .         . X X .         X X X .         X X . .
    . . . .         . . . .         . . . .         . . . .

Z:  . . . .     J:  . . . .     L:  . . . .
    X X . .         X . . .         . . X .
    . X X .         X X X .         X X X .
    . . . .         . . . .         . . . .
```

## How This Connects to the Handheld

Every tetromino the player ever sees is one of these 7 shapes in one of its
4 rotation states, positioned somewhere over the board Lesson 19 built.
Lesson 21 will take a `(piece, rotation, row, col)` and ask "does this
collide with anything already on the board, or with the walls?" — a
question that's only answerable once a piece's cells can be enumerated
cheaply, which is exactly what `piece_cell` gives it. The rotation state
machine here is what turns a single static shape into "the player pressed
rotate" — the mechanic every Tetris player expects.

## Read First

1. `tutorial-01-encoding-tetrominoes.md` — encoding one piece as 16-bit
   words, the Flash table layout, the T-piece worked out by hand
2. `tutorial-02-rotation-state-machine.md` — table lookup vs. computing
   rotation live, tracing the T-piece through all 4 states, wraparound
3. **Datasheet:** no new peripheral chapter this lesson (same as Lesson 19)
   — this is addressing math applied to Flash instead of RAM.

## Then

Attempt the exercises before flashing `examples/piece_demo.s`. The example
is the working reference — study it *after* you've built your own.

## Exercises

See `exercises/README.md`.

## Success Criteria

- [ ] I can encode any of the 7 reference shapes above as a 16-bit word
      using row-major, MSB-first packing
- [ ] I can compute the Flash address of `(piece, rotation)` given the
      table layout `table + piece*8 + rotation*2`
- [ ] I can trace the T-piece through all 4 rotation states in sequence and
      draw the resulting 4x4 grid at each step
- [ ] I can explain why rotation state 4 must be rotation state 0, not an
      invalid or unhandled state
- [ ] `examples/piece_demo.s` builds, flashes, and lights LED1 solid (all
      64 cell/rotation checks pass)
- [ ] `exercises/ex1` and `exercises/ex2` each build, flash, and behave per
      their own success criteria (see `exercises/README.md`)
- [ ] `exercises/ex3`'s milestone spec is met: `handheld/game/tetris.s` now
      has `piece_rotation_cw`/`piece_cell` alongside the Lesson 19 board
      functions, and `cd handheld && make` builds cleanly
