# Tutorial 01 — Checking Whether a Move Is Legal

## What `piece_can_move` Has to Answer

A tetromino is a 4×4 cell mask (Lesson 20) sitting at some position on the
board — call that position the mask's **top-left row and column**. A
candidate move is a pair `(dx, dy)`: how many columns to shift horizontally
and how many rows to shift vertically. `piece_can_move(dx, dy)` has to
answer one question: *if every occupied cell of the piece were moved by
`(dx, dy)`, would every one of those cells land on a valid, empty board
square?*

That means checking **all 16 cells of the 4×4 mask**, not just the piece's
outline or its corners. A piece's mask has holes in it — most tetromino
shapes only occupy 4 of the 16 cells — and only the occupied ones matter.
For each occupied cell:

1. Compute where that cell would land on the board if the move happened.
2. Check whether that landing square is inside the board at all.
3. If it is, check whether the board already has a block there.

If *any* occupied cell fails either check, the whole move is illegal — one
bad cell condemns the entire move, even if the other three would have been
fine.

## From Piece-Local to Board-Absolute Coordinates

Say the piece's current top-left position is `(piece_row, piece_col)`, and
you're examining the mask cell at relative position `(cell_row, cell_col)`
— each in `0..3`, since the mask is 4×4. For a candidate move `(dx, dy)`,
that cell's board-absolute coordinate is:

```
board_row = piece_row + dy + cell_row
board_col = piece_col + dx + cell_col
```

`piece_cell(piece_id, rotation, cell_row, cell_col)` (Lesson 20) tells you
whether that mask cell is occupied at all — you only need to bother
computing `board_row`/`board_col` and checking the board for cells where
`piece_cell` says "occupied."

## Worked Example: A Piece Near a Wall

Picture a piece whose occupied mask cells (relative to its own 4×4 grid)
are `(0,1)`, `(0,2)`, `(1,0)`, `(1,1)` — an S-shaped piece sitting in the
top two rows of its bounding box. Suppose its current top-left position is
`row=5, col=7`, and the board is 10 columns wide (columns `0..9`).

Testing `piece_can_move(dx=0, dy=0)` — is the piece legal to just *stay*
where it is? Board-absolute cells: `(5,8)`, `(5,9)`, `(6,7)`, `(6,8)`. All
four columns (8, 9, 7, 8) are within `0..9` and all four rows are within
the board — legal, assuming none of those squares are occupied.

Now test `piece_can_move(dx=+1, dy=0)` — nudge one column right. The same
four relative cells now land at `(5,9)`, `(5,10)`, `(6,8)`, `(6,9)`.
Column 10 is outside the valid range `0..9` — the move is illegal purely on
bounds, regardless of what's on the board. Notice this failure comes from
the mask cell `(0,2)`, not from the piece's leftmost or topmost cell — you
would miss it entirely if you only checked the piece's top-left corner or
its "bounding box" edges instead of walking every occupied cell.

## Worked Example: A Piece Near Stacked Blocks

Now picture the same piece at `row=17, col=1`, above a board where the
bottom row (`row=19`) already has columns `0`–`3` filled in from previous
pieces. Testing `piece_can_move(dx=0, dy=0)`: board-absolute cells `(17,2)`,
`(17,3)`, `(18,1)`, `(18,2)` — all comfortably above the stack, all empty.
Legal.

Testing `piece_can_move(dx=0, dy=+1)` — one row down: cells become `(18,2)`,
`(18,3)`, `(19,1)`, `(19,2)`. Rows and columns are all in range, so the
bounds check passes for every cell — but `(19,1)` and `(19,2)` both fall on
squares the stack already occupies. `board_get(19,1)` and `board_get(19,2)`
both report occupied, so this move is illegal even though nothing about it
violates the board's boundary. This is the second, independent failure
mode: a move can be perfectly in-bounds and still illegal because of what's
already on the board. A correct `piece_can_move` has to catch both kinds,
for every occupied cell, every time.

## Why the Bounds Compare Must Be Signed

`dx` and `dy` are allowed to be negative — moving left or moving up (as
happens transiently during some rotation systems) subtracts from a
coordinate. If a piece's column is `0` and `dx = -1`, `board_col` comes out
to `-1`. On a 16-bit register, `-1` is the bit pattern `0xFFFF`. Compared
*unsigned*, `0xFFFF` is the largest possible value — nowhere near "less
than zero." Compared *signed*, `0xFFFF` correctly reads as `-1`, which is
less than `0`. The MSP430's `JL`/`JGE` conditional jumps test the signed
sense of a `CMP` result; `JC`/`JNC` test the unsigned/carry sense. Getting
this wrong doesn't crash anything — it just silently lets a piece slide one
column past the left wall, because the "is this less than zero" check
quietly says no.

## What `piece_can_move` Does *Not* Do

It only answers "legal or not" — it doesn't move anything, and it doesn't
write to the board. That separation matters: the same check gets called
speculatively, over and over, by hard drop (Tutorial 02) without any risk
of leaving the board in a half-moved state if one of those speculative
checks comes back illegal.
