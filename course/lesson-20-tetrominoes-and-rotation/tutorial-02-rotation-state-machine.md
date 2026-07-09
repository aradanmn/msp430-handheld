# Tutorial 02 — The Rotation State Machine

## Table Lookup vs. Computing Rotation Live

There are two ways a game could handle "rotate this piece":

1. **Compute it live.** Store only one shape per piece (rotation 0), and
   when the player rotates, transform the current shape's cells
   mathematically (the `(row, col) -> (col, 3-row)` rule from tutorial-01)
   to produce the next shape, on the fly, every time.

2. **Look it up.** Precompute and store all 4 rotation words for every
   piece (56 bytes total, in Flash, done once at build time — not
   recomputed at runtime), and "rotate" becomes nothing more than advancing
   an index and reading a different `.word`.

This course uses **table lookup**. The reasons: 56 bytes of Flash is
negligible against 16 KB total, whereas the *code* to do a live 4x4-grid
rotation transform (extract each of 16 bits, recompute its new position,
re-pack the result) costs far more Flash than the data it would save, and
it costs CPU cycles every single rotation, every single frame it happens
in. Reading a `.word` from a table costs one indexed load. On a chip this
constrained, "do the expensive part once, at compile time, and make the
runtime path a lookup" is a pattern you'll see again — it's exactly what
Lesson 19's row-major layout does for line-clear checks, and what `main.s`'s
DCO calibration constants (Lesson 01) do for clock tuning.

## Rotation as an Index, Not a Shape

Once the 4 words for a piece are sitting in a table, "what shape is this
piece in right now" stops being a question about the shape itself and
becomes a question about a single small integer: **which rotation index,
0-3, is current.** Rotating clockwise is:

```
new_rotation = (current_rotation + 1) mod 4
```

That `mod 4` is doing real work. Without it, incrementing rotation 3 would
produce rotation 4 — which doesn't exist. `piece_table + 4*2` (using the
per-rotation stride from tutorial-01) reads 2 bytes *past* the last valid
rotation word for this piece — memory that belongs to whatever is stored
next in Flash, not a 5th rotation state (there isn't one). Whatever bit
pattern happens to live there gets interpreted as if it were a legitimate
tetromino shape, with no indication anything went wrong.

In practice, `mod 4` on a 2-bit-wide range is just a mask:

```
new_rotation = (current_rotation + 1) & 0x03
```

`AND #0x03` clears every bit except the low two, which is exactly
equivalent to "wrap back to 0 after 3" for a counter that only ever holds
0-3 — the moment the increment would produce a 3rd bit (value 4, binary
`100`), the mask clears it, leaving 0.

## Tracing the T-Piece Through All 4 States

Starting at rotation 0 and applying `new_rotation = (rotation + 1) & 0x03`
repeatedly, using the four words from tutorial-01:

```
step 0 -> rotation 0 -> 0x04E0 -> . . . .      step 1 -> rotation 1 -> 0x4640 -> . X . .
                                    . X . .                                       . X X .
                                    X X X .                                       . X . .
                                    . . . .                                       . . . .

step 2 -> rotation 2 -> 0x0720 -> . . . .      step 3 -> rotation 3 -> 0x0262 -> . . . .
                                    . X X X                                       . . X .
                                    . . X .                                       . X X .
                                    . . . .                                       . . X .

step 4 -> (3 + 1) & 0x03 = 0 -> rotation 0 -> 0x04E0 -> back to the start
```

Step 4 lands exactly back on step 0's shape — `(3 + 1) & 0x03` computes `4 &
0x03`, and `4` in binary is `100`; masking with `0x03` (`011`) clears the
bit that made it 4, leaving `00` — rotation 0. This is what "rotation always
wraps, it never produces an invalid state" (from Exercise 3's spec) means
concretely: no matter how many times `piece_rotation_cw` is called in a
row, the sequence cycles 0, 1, 2, 3, 0, 1, 2, 3, ... forever, and every one
of those values is a valid index into the table.

## What Exercise 2 Is Probing

`exercises/ex2/piece_rotate_probe.s` advances a rotation index through
several steps and checks, after each one, whether the resulting word
matches one of the four valid encodings. The wraparound reasoning above —
what has to be true about a rotation index for it to *stay* valid no matter
how many times it advances — is exactly the reasoning that exercise is
asking you to apply to a program that doesn't behave the way its header
comment says it should.
