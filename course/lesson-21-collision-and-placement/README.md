# Lesson 21 — Collision, Movement & Placement

## Topic

Lesson 19 gave the board a home (`board_get`/`board_set` over a packed bit
array) and Lesson 20 gave every piece a shape and a rotation state machine
(`piece_cell`/`piece_rotation_cw`). Neither of those, on its own, knows
whether a move is *legal*. A piece can rotate into a wall, slide through
already-placed blocks, or drop off the bottom of the board unless something
checks every one of its four occupied cells against the board and the
boundary on every attempted move.

This lesson builds that check — `piece_can_move(dx, dy)` — and everything
downstream of it: stamping a piece permanently onto the board
(`piece_place`), and the two ways a piece reaches the board faster than
gravity alone (`piece_hard_drop`, `piece_soft_drop_tick`). The central idea
of the lesson isn't any one of these functions individually — it's that
**all of them are built on the same single legality check.** Gravity, the
soft-drop button, and the hard-drop button must never each carry their own
private idea of "is this legal." One check, three callers.

## Learning Objectives

By the end of this lesson you will be able to:

- Walk a piece's 4×4 cell mask and, for each occupied cell, compute the
  corresponding absolute board coordinate for a given `(dx, dy)` offset
- Explain the two independent ways a candidate move can be illegal (out of
  the board's bounds vs. landing on an already-occupied cell) and why both
  must be checked for every occupied cell, not just the piece's corners
- Explain why bounds comparisons on piece/board coordinates must be
  **signed**, not unsigned — a piece nudged left of column 0 produces a
  negative column, and an unsigned compare would treat that as an enormous
  positive number instead of "out of bounds"
- Describe hard drop as repeated legality checks in the same direction
  until the first illegal one, and soft drop as one legality-gated step per
  player input
- Explain why gravity, soft drop, and hard drop should all call the same
  `piece_can_move` rather than each re-implementing their own version of
  "is this legal" — and what breaks (silently, and differently in each
  path) if they don't

## What You'll Build

`examples/collision_demo.s` — a self-contained demo with a hardcoded test
board, a hardcoded 4×4 piece shape, and a table of `(row, col, dx, dy)`
moves paired with hand-worked expected legal/illegal results. It runs every
case through a `can_move`-style check and reports pass/fail on LED1.

`exercises/ex1` — the same shape of problem against a different board and
piece: write the bounds-plus-board-lookup check yourself.

`exercises/ex2` — a working legality check that reports a piece as legal to
spawn when it plainly is not, against a board with the top rows already
mostly full. Find out why.

`exercises/ex3` (**Milestone**) — extend `handheld/game/tetris.s` with
`piece_can_move`, `piece_place`, `piece_hard_drop`, and
`piece_soft_drop_tick`, on top of the `board_*` and `piece_*` functions
already there from Lessons 19 and 20. See `exercises/ex3/README.md`.

## Game Connection

This is the moment Tetris stops being "a board" and "some shapes" and
becomes a *game with physics*. Every button press that moves or rotates a
piece, every tick of gravity, and the hard-drop button all boil down to the
same question, asked over and over: "if I move the piece this way, is that
still a legal position?" Getting that one question right, in one place, is
what Lesson 22 (line clears) and everything after it will build on without
ever having to think about collision again.

## Datasheet Reference

No new peripheral this lesson — it's pure algorithm work on top of the
board and piece representations from Lessons 19–20. Worth re-reading if
signed comparisons feel shaky:

- **SLAU144, Chapter 3** — the CPU's status register flags (N, Z, C, V) and
  how `JL`/`JGE` interpret them for signed comparisons, vs. `JC`/`JNC` for
  unsigned

## Success Criteria

- [ ] I can explain, for a single piece cell, how its board-relative
      coordinate is computed from the piece's position, the cell's
      row/column within the 4×4 mask, and a candidate `(dx, dy)`
- [ ] I can state the two distinct reasons a move can be illegal and why
      both need checking for every occupied cell
- [ ] I can explain why the bounds check must use a signed comparison
- [ ] I can explain hard drop and soft drop each in terms of repeated calls
      to the same legality check, not as separate mechanisms
- [ ] `examples/collision_demo.s` builds and flashes; LED1 lands solid,
      confirming every hardcoded test case matches its expected result
- [ ] `exercises/ex1`, `ex2`, and `ex3` each meet their own success criteria
      (see `exercises/README.md` and `exercises/ex3/README.md`)
