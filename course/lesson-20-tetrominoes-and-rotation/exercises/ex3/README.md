# Exercise 3 — Milestone: `handheld/game/tetris.s` (pieces)

This milestone **extends** `handheld/game/tetris.s`, the file Lesson 19
created with `board_init`/`board_get`/`board_set`. You are adding
piece-related functions alongside those, not replacing anything. Lessons 21
and 22 will each extend this same file again (physics, then rules) — so
whatever you add here should still make sense sitting next to the board code
already there, and next to whatever gets added after it.

## Behavioral Spec

There are 7 standard tetrominoes (see this lesson's README/tutorial-01 for
the reference shapes — that table is public-domain game-design knowledge,
not something this exercise is testing). Each piece has 4 rotation states.
Each rotation state is a shape within a 4x4 grid (16 cells).

Add two public subroutines to `handheld/game/tetris.s`:

- **`piece_rotation_cw(piece_id, rotation)` → `new_rotation`**
  Arguments: `piece_id` in R12 (which of the 7 pieces), `rotation` in R13
  (its current rotation state).
  Returns: R12 = the rotation state that results from rotating this piece
  90 degrees clockwise from `rotation`. Rotating one step past the last
  valid rotation state must land back on the first one — rotation always
  wraps, it never produces an invalid state and never gets "stuck."

- **`piece_cell(piece_id, rotation, row, col)` → `bit`**
  Arguments: `piece_id` in R12, `rotation` in R13, `row` in R14, `col` in
  R15 — this is exactly 4 arguments, using all four of R12-R15, which is
  every argument register this course's convention provides. `row` and
  `col` are coordinates within the 4x4 grid (0-3 each), not board
  coordinates.
  Returns: R12 = 1 if that cell is part of the piece's shape in that
  rotation, 0 if it's empty.

`piece_id` numbering (0-6, one per shape) and `rotation` numbering (0-3, and
which rotation is "state 0" for each piece) are your design decisions —
document whatever scheme you pick in a comment. The 4x4 grid's internal bit
layout (row-major or not, MSB-first or not, one Flash `.word` per rotation
or some other encoding) is also your design decision, exactly as the board's
internal bit layout was Lesson 19's.

## A Note on the Register Budget

This course's calling convention gives you exactly four argument registers,
R12-R15. `piece_cell` above uses all four. If you ever find yourself
designing a function that needs a fifth input value, R12-R15 alone won't
carry it — you'd need some other mechanism (a fixed memory location, a value
pushed on the stack before the call, restructuring the function to take
fewer inputs, etc.). That's not a problem this milestone's two functions
actually have — both fit inside R12-R15 as specified — but it's worth
knowing the ceiling exists before Lesson 21 potentially runs into it.

## Integration

`handheld/game/tetris.s` should still `#include` cleanly into
`handheld/main.s` and build with `cd handheld && make`. You do not need to
wire `piece_rotation_cw`/`piece_cell` into the game loop yet — there's no
rendering or input-driven movement until later lessons. The goal is that
the functions exist, are correctly extending the same file (not a second
file, not a rewrite of Lesson 19's board code), and are ready for Lesson 21
to build on.

## Success Criteria

- [ ] `handheld/game/tetris.s` still contains Lesson 19's
      `board_init`/`board_get`/`board_set`, unchanged in behavior
- [ ] `piece_rotation_cw` and `piece_cell` exist with exactly the
      argument/return registers specified above
- [ ] All 7 tetrominoes are encoded, each with 4 rotation states
- [ ] A comment documents your `piece_id` numbering, your rotation-state
      numbering, and your internal grid bit layout
- [ ] You can demonstrate (even via temporary test code you remove
      afterward) that calling `piece_rotation_cw` four times in a row on any
      piece returns to that piece's original rotation state
- [ ] `cd handheld && make` builds cleanly
- [ ] No leftover TODO comments in the committed version
