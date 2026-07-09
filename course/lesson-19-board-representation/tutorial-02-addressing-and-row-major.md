# Tutorial 02 — Addressing in Practice, and Why Row-Major Wins

## Tracing `board_set(5, 3, 1)` End to End

Tutorial 01 worked the bit-index arithmetic by hand for fixed cells. Here's
the same math traced through as `board_set` actually executes it, for
`row=5, col=3, val=1` (fill the cell at row 5, column 3).

**Step 1 — bit index:**
```
bit_index = row*10 + col = 5*10 + 3 = 53
```

**Step 2 — byte offset and bit position:**
```
byte_offset      = 53 / 8 = 6            (53 = 6*8 + 5)
bit_within_byte  = 7 - (53 mod 8) = 7 - 5 = 2
```
So this cell lives in byte 6, bit 2.

**Step 3 — build a bit mask.** Unlike a GPIO register write, where the bit
you want is known at compile time (`BIT0`, `BIT3`, ...), `bit_within_byte`
here is a **runtime value** — it depends on `row` and `col`, which are
subroutine arguments. You can't write `bis.b #BIT2, ...` when you don't know
until the function runs whether it's bit 2, bit 5, or any other bit. So the
mask has to be built at runtime, by starting at bit 0 and shifting left
`bit_within_byte` times:

```
mask = 0x01
shift left twice (bit_within_byte = 2)
mask = 0x04
```

**Step 4 — apply it.** `val` is nonzero (fill), so the mask is OR'd into
byte 6 of the board array: `board[6] |= 0x04`. Every other bit in byte 6 —
which holds seven *other* cells' state — is left untouched, because `BIS`
only ever sets the bits that are 1 in its mask (the same non-destructive
idiom from Lesson 03's GPIO work, just applied to a byte you're addressing
yourself instead of a fixed peripheral register).

## Tracing `board_get(5, 3)` — Same Math, Read Instead of Write

`board_get` computes the identical `bit_index = 53`, `byte_offset = 6`,
`bit_within_byte = 2`, and builds the identical `mask = 0x04`. The only
difference is the last step: instead of `BIS`/`BIC` (write), it's `BIT`
(test) — `BIT` computes `board[6] AND mask` and sets the Zero flag without
modifying `board[6]` at all. If the result is nonzero (Z clear), the cell is
filled; if it's zero (Z set), the cell is empty. The addressing math that
finds *which* bit is completely shared between the read path and the write
path — only the final instruction differs.

## Why Row-Major, Not Column-Major

The layout choice — number cells row-by-row (row-major) versus
column-by-column (column-major) — doesn't affect how many bytes the board
needs, or how expensive a single `board_get`/`board_set` call is. Where it
matters is a query Lesson 22 needs constantly: **is this entire row full?**

With **row-major** layout, a row's 10 cells are 10 *consecutive* bit
indices: row 5's cells are bit indices 50 through 59. Consecutive bit
indices land in a small, predictable span of bytes — bit index 50 is in
byte 6, bit index 59 is in byte 7 — so "is this row full" is a check against
at most two bytes, with a fixed mask, regardless of which row it is (only
which two bytes, and where the row starts within the first one, changes).

With **column-major** layout, bit_index would instead be
`col * BOARD_ROWS + row`. Row 5's 10 cells (col 0 through col 9, row fixed
at 5) would land at bit indices `5, 25, 45, 65, 85, 105, 125, 145, 165, 185`
— each one landing in a *different* byte, 20 bits apart. Checking whether
that row is full would mean testing 10 separate bits in 10 separate bytes,
one `BIT` instruction (and one mask-build) per cell, with no way to collapse
it into a single masked comparison.

Column-major would still work, functionally — `board_get`/`board_set`
would just use a different formula for `bit_index`. But every full-row scan
in Lesson 22 (and there's one per piece landing, at minimum) would cost
roughly 10x the instructions that row-major costs for the same check. This
lesson's board is row-major specifically because a Tetris board's most
frequent bulk query is "is this whole row filled," and row-major is the
layout that makes that query cheap.

## What Ex1 and Ex3 Ask You to Decide

The row-major, MSB-first convention above is what `examples/board_demo.s`
uses, worked out in full so you can see every step. `exercises/ex1` asks you
to build the same two subroutines from scratch — you may use this exact
convention or a different internally-consistent one (LSB-first, for
instance), as long as `board_get` always reads back exactly what the
matching `board_set` wrote, for every cell, including the edges.

`exercises/ex3` (the milestone) asks the same thing of
`handheld/game/tetris.s`: the spec there leaves the entire bit layout —
row-major vs. column-major, MSB-first vs. LSB-first — up to you, as long as
it's internally consistent and documented. Nothing forces you to use
row-major for the milestone. But the row-vs-column argument above is the
same argument Lesson 22 (line-clear) will make again when it needs to scan
whole rows, so it's worth weighing now rather than re-deriving under
pressure two milestones from now.
