# Lesson 21 Exercises

Three tiers: Explore (ex1), Challenge (ex2), Milestone (ex3).

## Ex1 — Explore: Collision Check

**File:** `ex1/collision_check.s`

The starter file has the standard boilerplate, LED1 configured as an
output, and two hardcoded data tables already in place: a 4×4 piece mask
(`TEST_PIECE_MASK`) and a small test board (`.Lex1_board`), using the same
one-word-per-row / bit-per-column layout as `examples/collision_demo.s`.
Below that is a table of `(row, col, dx, dy, expected)` test cases.

Your job: write the bounds-and-board-lookup legality check yourself, and a
runner that walks the test table, compares your check's result against
each expected value, and drives LED1 — solid if every case matches, blinking
if any doesn't.

Look up:
- SLAU144 Chapter 3 (Status Register) for `JL`/`JGE` vs. `JC`/`JNC` —
  which pair reads the signed sense of a `CMP` result and why that matters
  for a coordinate that can go negative
- Reuse the same board-lookup idea as `board_get` — a row's packed bits
  ANDed against a single-bit column mask

**Success criteria:**
- [ ] `make flash` builds and flashes without error
- [ ] LED1 lands solid, confirming every hardcoded test case in
      `.Ltest_vectors` matches its expected legal/illegal result
- [ ] The bounds check uses a signed comparison (there is at least one test
      case with a negative `dx` or `dy` that would fail an unsigned check)
- [ ] The board-occupancy check runs for every occupied mask cell, not just
      the piece's corners
- [ ] No leftover `TODO` comments in the file you submit

## Ex2 — Challenge: Spawn Collision

**File:** `ex2/spawn_collision_bug.s`

`ex2/spawn_collision_bug.s` is a complete, compiling program. Its header
comment states the intended behavior. Build it, flash it, and watch LED1.

**Observable failure:** when a freshly-spawned piece's legality is checked
against a board whose top rows are already mostly full, the check reports
the position as legal — even though several of the piece's occupied cells
plainly overlap already-filled board cells.

Your job: figure out why, in terms of this lesson's material (which of the
two legality conditions from Tutorial 01 is actually being evaluated for
each cell), and fix it — not by special-casing the spawn position, but by
correcting the general check so it's right for every case, including the
ones this file already gets right.

**Success criteria:**
- [ ] I can state which of the two legality conditions (bounds vs. board
      occupancy) the check is failing to evaluate, and for which cells
- [ ] I can explain why the wall-collision and floor-collision test cases
      in this same file already pass despite the bug
- [ ] After my fix, LED1 lands solid — every test case, including the
      top-of-board spawn case, matches its expected result

## Ex3 — Milestone: `handheld/game/tetris.s` (physics)

**Directory:** `ex3/`

See `ex3/README.md` for the full behavioral spec. This extends
`handheld/game/tetris.s` — the same file Lessons 19 and 20 already added
`board_get`/`board_set`/`piece_cell`/`piece_rotation_cw` to — with the
collision-and-placement layer: `piece_can_move`, `piece_place`,
`piece_hard_drop`, and `piece_soft_drop_tick`.

`ex3/ex3.s` is an intentionally empty placeholder — the real work happens
in `handheld/game/tetris.s`, which you extend, not recreate.
