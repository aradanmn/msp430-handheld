# Tutorial 01 — Packed Bit Arrays

## Why Not Just One Byte Per Cell?

A Tetris board is 10 columns wide and 20 rows tall — 200 cells. The obvious
representation is an array of 200 bytes, one per cell, each holding 0
(empty) or 1 (filled). It's simple, and every cell is trivially addressable:
`cell[row * 10 + col]`.

It also costs 200 bytes. The MSP430G2553 has **512 bytes of RAM, total** —
not per-program, not "plenty," the entire chip. Before you've allocated a
stack, a frame counter, input state, piece position, score, or anything else
the rest of the game needs, a byte-per-cell board has already eaten:

```
200 bytes / 512 bytes = 39.1%
```

Nearly 40% of all RAM on this chip, gone, just to say "filled or not" about
200 cells that only ever hold one of two values. That's the entire problem
this lesson solves: each cell needs exactly **one bit**, not one byte.

## Packing 8 Cells Into Every Byte

If each cell is a single bit, one byte holds 8 cells' worth of state. The
board needs:

```
.equ BOARD_ROWS,  20
.equ BOARD_COLS,  10
.equ BOARD_BITS,  (BOARD_ROWS * BOARD_COLS)        ; 200
.equ BOARD_BYTES, ((BOARD_BITS + 7) / 8)           ; 25
```

`(BOARD_BITS + 7) / 8` is the standard "round up when dividing" trick for
integer division: adding 7 before dividing by 8 guarantees any remainder
bits still get a whole byte to live in. Here it doesn't even matter — 200 is
exactly divisible by 8 — but writing it as `(bits + 7) / 8` rather than a
bare `25` documents *why* 25 is the right number, and it keeps working
correctly if `BOARD_BITS` ever changes to something not cleanly divisible by
8.

25 bytes instead of 200:

```
25 bytes / 512 bytes = 4.9%
```

Under 5% of RAM, for the exact same information. That's the trade this
lesson is teaching: a few extra instructions per access (to find the right
bit) in exchange for an 8x reduction in the memory footprint of the single
largest piece of persistent game state this project has.

## The Convention: Row-Major, MSB-First

"Packed 1 bit per cell" doesn't by itself tell you *which* bit holds *which*
cell — you need a convention, and it has to be the same convention
everywhere `board_get`/`board_set` (and, in Lesson 20, the tetromino tables)
are used. This course uses:

- **Row-major layout.** Cells are numbered left-to-right, then top-to-bottom
  — row 0's 10 cells first, then row 1's 10 cells, and so on. The formula
  for a cell's position in that numbering (its **bit index**) is:

  ```
  bit_index = row * BOARD_COLS + col
  ```

- **MSB-first within each byte.** Bit 7 (the most-significant bit) of byte 0
  holds bit_index 0; bit 0 (least-significant) of byte 0 holds bit_index 7.
  Byte 1 picks up at bit_index 8, same pattern. In general:

  ```
  byte_offset      = bit_index / 8
  bit_within_byte  = 7 - (bit_index mod 8)
  ```

  The `7 -` is what makes it MSB-first: without it, bit_index 0 would map to
  bit 0 (LSB-first), which is an equally valid convention — just a different
  one, and this course picks MSB-first and uses it consistently in both this
  lesson and Lesson 20's tetromino encoding.

## Worked Examples

Four concrete `(row, col)` pairs, computed by hand:

**`(row=0, col=0)`** — the first cell.
```
bit_index = 0*10 + 0 = 0
byte_offset = 0 / 8 = 0
bit_within_byte = 7 - (0 mod 8) = 7 - 0 = 7
```
→ byte 0, bit 7 (the MSB of the very first byte).

**`(row=0, col=9)`** — end of the first row.
```
bit_index = 0*10 + 9 = 9
byte_offset = 9 / 8 = 1
bit_within_byte = 7 - (9 mod 8) = 7 - 1 = 6
```
→ byte 1, bit 6. Notice this cell is in **row 0** but already lives in
**byte 1** — rows don't align to byte boundaries, because 10 isn't a
multiple of 8. That's expected and fine; the addressing math doesn't care.

**`(row=1, col=0)`** — start of the second row.
```
bit_index = 1*10 + 0 = 10
byte_offset = 10 / 8 = 1
bit_within_byte = 7 - (10 mod 8) = 7 - 2 = 5
```
→ byte 1, bit 5 — sharing byte 1 with `(row=0, col=9)` above. One byte can
straddle a row boundary just as easily as it can straddle within a row.

**`(row=19, col=9)`** — the very last cell.
```
bit_index = 19*10 + 9 = 199
byte_offset = 199 / 8 = 24
bit_within_byte = 7 - (199 mod 8) = 7 - 7 = 0
```
→ byte 24, bit 0 — the last bit of the last byte. This confirms
`BOARD_BYTES = 25` (bytes 0 through 24) is exactly enough, with no wasted
byte and no cell left unaddressable.

## Multiplying Without a Multiply Instruction

`row * 10` shows up in every one of those calculations, and the
MSP430G2553's base instruction set has no single-cycle multiply. What it
does have is shifts, and `10 = 8 + 2`, so:

```
row * 10 = (row * 8) + (row * 2)
```

Both `row * 8` and `row * 2` are left shifts — `row * 2` is one shift,
`row * 8` is three shifts (each shift doubles the value: `x2, x4, x8`). In
assembly, using the `RLA` (left-shift) instruction from Lessons 02-03:

```asm
mov.w   row, R14        ; R14 = row (a working copy)
rla.w   row              ; row = row*2
rla.w   R14              ; R14 = row*2
rla.w   R14              ; R14 = row*4
rla.w   R14              ; R14 = row*8
add.w   R14, row         ; row = row*2 + row*8 = row*10
```

This is the general technique for multiplying by any compile-time constant
when there's no multiply instruction: decompose the constant into a sum of
powers of two (its binary representation, effectively), and shift-and-add
for each set bit. `10 = 0b1010` has two set bits (8 and 2), so this takes
one working copy and four shift/add instructions total — cheap, and exactly
as precise as a real multiply for these small values.

Tutorial 02 traces `board_get`/`board_set` through this full pipeline —
bit-index arithmetic, byte offset, bit position, and the mask-building step
needed to actually test or set a bit at a position that's only known at
runtime (not a compile-time constant) — and looks at why row-major layout,
not column-major, is the right choice for a game that needs to check whole
rows at once.
