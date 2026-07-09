# Tutorial 01 — Encoding Tetrominoes

## One Shape, One Word

Each tetromino rotation state is a 4x4 grid — 16 cells, each either filled
or empty. Sixteen bits is exactly one MSP430 `.word`. That's not a
coincidence this course is exploiting cleverly — it's the reason a 4x4
bounding box is the standard choice for tetromino encoding in the first
place: it's the smallest square grid that fits every standard tetromino in
every rotation, and it happens to map perfectly onto this CPU's native word
size.

The convention is the same one Lesson 19 used for the board, applied to a
4x4 grid instead of a 20x10 one:

- **Row-major**: cell `(row, col)` within the 4x4 grid has
  `bit_index_in_word = row*4 + col`, ranging 0-15.
- **MSB-first**: bit 15 of the word holds bit_index_in_word 0 (the grid's
  top-left cell); bit 0 holds bit_index_in_word 15 (the grid's
  bottom-right cell).

## Encoding the T-Piece by Hand

Take the T-piece's spawn orientation from this lesson's reference table:

```
. . . .
. X . .
X X X .
. . . .
```

Read row by row, left to right, `X` = 1 and `.` = 0:

```
row 0: 0 0 0 0
row 1: 0 1 0 0
row 2: 1 1 1 0
row 3: 0 0 0 0
```

Concatenated MSB-first (row 0 is the most significant nibble, row 3 the
least):

```
0000 0100 1110 0000
```

Grouped into hex nibbles: `0`, `4`, `E`, `0` → **`0x04E0`**. That's the
entire rotation-0 shape of the T-piece, in one 16-bit constant.

## The Flash Table Layout

A piece has 4 rotation states, each one `.word` (2 bytes). That's:

```
.equ ROTATIONS_PER_PIECE, 4
.equ BYTES_PER_ROTATION,  2               ; one .word
.equ BYTES_PER_PIECE,     (ROTATIONS_PER_PIECE * BYTES_PER_ROTATION)  ; 8
```

For a table holding multiple pieces back to back, the address of a specific
`(piece_index, rotation)` pair is:

```
address = piece_table + piece_index*BYTES_PER_PIECE + rotation*BYTES_PER_ROTATION
        = piece_table + piece_index*8 + rotation*2
```

Both multiplications are by compile-time constants (8 and 2), so — same as
Lesson 19's `row*10` — they're shifts: `*8` is three left-shifts,
`*2` is one. In GAS, this table address arithmetic can be written directly
using `.equ`-derived constants and indexed addressing once `piece_index*8 +
rotation*2` has been computed into a register:

```asm
mov.w   piece_index, R14
; ... multiply R14 by 8 (three RLA.w) ...
mov.w   rotation, R15
rla.w   R15                    ; rotation*2
add.w   R15, R14               ; R14 = combined byte offset into the table
mov.w   piece_table(R14), R15  ; R15 = the 16-bit rotation word
```

`examples/piece_demo.s` only encodes one piece (the T), so its version of
this is simpler — just `rotation*2` — but the full `piece*8 + rotation*2`
formula above is what Exercise 3's milestone needs once all 7 pieces share
one table.

## The T-Piece's Four Rotation Words, Worked Out

Rotating the T-piece's 4 cells 90 degrees clockwise around the center of
the 4x4 grid, one step at a time, produces these four shapes (the math
behind exactly how each cell maps to its rotated position is a coordinate
transform — `(row, col) -> (col, 3-row)` for a 4x4 grid — but the shapes
below are what matters for this lesson; tutorial-02 traces the sequence
step by step):

```
rotation 0:      rotation 1:      rotation 2:      rotation 3:
. . . .          . X . .          . . . .          . . . .
. X . .          . X X .          . X X X          . . X .
X X X .          . X . .          . . X .          . X X .
. . . .          . . . .          . . . .          . . X .
```

Encoded the same way as rotation 0 above:

```
rotation 0: 0000 0100 1110 0000 = 0x04E0
rotation 1: 0100 0110 0100 0000 = 0x4640
rotation 2: 0000 0111 0010 0000 = 0x0720
rotation 3: 0000 0010 0110 0010 = 0x0262
```

These four words are exactly what `examples/piece_demo.s` stores in
`piece_table`, and exactly what its self-test checks `piece_cell` against,
cell by cell, across all 4 rotations.

Tutorial 02 picks up from here: the rotation *state machine* — how a piece
advances from one of these words to the next, what "rotate" actually means
as an operation on a rotation index, and why index 4 has to become index 0
instead of falling off the end of the table.
