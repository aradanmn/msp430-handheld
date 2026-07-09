# Exercise 3 — Milestone: `handheld/game/tetris.s` (board)

This is the **first** milestone that creates `handheld/game/tetris.s`. Lessons
20, 21, and 22 all extend this same file (pieces, physics, rules) — nothing
you write here gets replaced later, only added to. Pick names and a bit
layout now that you'd be comfortable building on for the rest of the course.

## Behavioral Spec

The board is **20 rows x 10 columns**. Rows are numbered 0-19; row 0 is the
top of the visible playing field and row 19 is the bottom (the row where a
piece that can't fall any further comes to rest). Columns are numbered 0-9;
column 0 is the left edge and column 9 is the right edge.

Each cell holds exactly one bit of state: **filled** or **empty**. There is
no color, no piece-identity, no anything else stored per cell at this
milestone — just occupancy. (Later lessons may decide they need more; that's
not this milestone's problem.)

Build `handheld/game/tetris.s` with these three public subroutines:

- **`board_init`** — clears every cell to empty. No arguments, no return
  value. Must be called once before any `board_get`/`board_set` call, since
  RAM does not power up zeroed.

- **`board_get(row, col)` → `filled`**
  Arguments: `row` in R12, `col` in R13.
  Returns: R12 = 1 if the cell is filled, 0 if it is empty.

- **`board_set(row, col, val)`**
  Arguments: `row` in R12, `col` in R13, `val` in R14.
  Behavior: if `val` is 0, the cell becomes empty; if `val` is nonzero, the
  cell becomes filled. No return value.

Both `row` and `col` are assumed to be in range (0-19 and 0-9 respectively)
whenever these are called. What happens if they aren't is undefined at this
milestone — Lesson 19's own Exercise 2 exists precisely because calling
these with an out-of-range value is not automatically safe. A later lesson
will decide how (and where) bounds-checking belongs; don't build it into
`board_set`/`board_get` themselves unless you have a specific reason to.

## What's Not Specified

The internal bit layout — row-major or column-major, MSB-first or
LSB-first, how many bytes you reserve, what you name your internal helper
labels — is **your design decision**, as long as it is internally
consistent (every `board_get` call must correctly read back whatever the
matching `board_set` call wrote) and documented with a comment at the top of
the file stating the convention you picked. You do not have to match the
convention used in this lesson's `examples/board_demo.s` or in
`exercises/ex1`/`exercises/ex2` — those are separate standalone programs,
not the module you're building here.

## Integration

Add `#include "game/tetris.s"` to `handheld/main.s` (following the
composition model already used for `hal/*.s`), and call `board_init` from
the init sequence. You do not need to call `board_get`/`board_set` from
`main.s` yet — there's no piece or renderer to drive them until later
lessons. The goal of this milestone is that the module exists, compiles
cleanly as part of the handheld build, and is ready for Lesson 20 to add to.

## Success Criteria

- [ ] `handheld/game/tetris.s` exists and defines `board_init`, `board_get`,
      and `board_set` with the exact argument/return registers specified
      above
- [ ] A comment at the top of the file states the bit layout convention you
      chose
- [ ] `cd handheld && make` builds cleanly with `game/tetris.s` included
- [ ] You can describe a test you personally ran (even temporarily, even if
      you removed the test code afterward) that proves a `board_set` at a
      given `(row, col)` is read back correctly by `board_get` at that same
      `(row, col)`, and that it does **not** change the reading of any
      neighboring cell
- [ ] No leftover TODO comments in the committed version
