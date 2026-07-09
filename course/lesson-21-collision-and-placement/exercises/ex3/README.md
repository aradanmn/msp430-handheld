# Exercise 3 — Milestone: `handheld/game/tetris.s` (physics)

This extends the same `handheld/game/tetris.s` that Lesson 19 started
(`board_get`, `board_set`) and Lesson 20 continued (`piece_cell`,
`piece_rotation_cw`). You are **not** creating a new file and you are
**not** touching the functions already there — you're adding four new
public entry points to it.

Follow the conventions already established for the project:

- Public labels are prefixed `piece_`; local labels use the `.L` prefix
  (see CLAUDE.md's "Assembly File Conventions")
- Argument/return convention: arg 1 in R12, arg 2 in R13, arg 3 in R14,
  arg 4 in R15, return value in R12 — the same convention `board_get`,
  `board_set`, `piece_cell`, and `piece_rotation_cw` already use
- Register usage follows `handheld/registers.md` — R12–R15 are scratch,
  R4–R11 must be saved/restored by any subroutine that borrows them

## What Already Exists (do not redefine or contradict)

- `board_get(row, col)` → 1/0, `board_set(row, col, val)` — the packed
  board from Lesson 19
- `piece_cell(piece_id, rotation, row, col)` → 1/0 — is this cell of this
  piece's 4×4 mask, at this rotation, occupied?
- `piece_rotation_cw(piece_id, rotation)` → new rotation index

Somewhere in `tetris.s`, the "current active piece" already has an
identity, a rotation, and (from this milestone onward) a position — the
top-left row/column of its 4×4 bounding box on the board. Exactly how that
state is stored is your call; it isn't specified here.

## Behavioral Spec

Add these four public entry points to `handheld/game/tetris.s`:

- **`piece_can_move(dx, dy)`** — `dx` in R12, `dy` in R13. Returns 1 in R12
  if every occupied cell of the current active piece would land inside the
  board (rows `0..19`, columns `0..9`) and on an unoccupied board cell, if
  the piece's position were shifted by `dx` columns and `dy` rows. Returns
  0 if any occupied cell would land out of bounds or on an already-occupied
  cell. Does not move anything or modify the board — it only answers the
  question.

- **`piece_place()`** — no arguments, no return value. Writes every
  occupied cell of the current active piece into the board at its current
  position, via `board_set`. Does not check legality first — the caller is
  responsible for only calling this when the current position is legal.

- **`piece_hard_drop()`** — no arguments, no return value. Moves the
  current active piece straight down as many rows as `piece_can_move(0, 1)`
  allows, stopping at the last row for which that check succeeds. Does not
  call `piece_place` itself — that remains a separate, explicit step.

- **`piece_soft_drop_tick()`** — no arguments. Returns 1 in R12 if the
  piece actually moved down one row, 0 if it did not (meaning the piece is
  already resting against the board or the floor). Attempts to move the
  current active piece down exactly one row, gated by the same legality
  check `piece_hard_drop` and gravity use — never an unconditional move.

## Integrating into `handheld/main.s`

Exercise a working `piece_can_move` (and, if you'd like, `piece_place` /
`piece_hard_drop` / `piece_soft_drop_tick`) against some hardcoded test
position and board state you set up yourself, and make the result visible
on hardware — LED1 solid for "matches expectation," blinking otherwise, is
the pattern this lesson's examples and exercises already use, but the exact
mechanism is up to you. The requirement is that correctness is observable
by flashing the board and watching it, not just "it compiles."

## Success Criteria

- [ ] `handheld/game/tetris.s` gains `piece_can_move`, `piece_place`,
      `piece_hard_drop`, and `piece_soft_drop_tick`, without modifying the
      existing `board_*`/`piece_cell`/`piece_rotation_cw` functions' names
      or argument conventions
- [ ] `cd handheld && make flash` builds and flashes cleanly
- [ ] `piece_can_move` checks every occupied cell of the 4×4 mask — not
      just the piece's corners — against both the board boundary and
      existing board occupancy
- [ ] `piece_can_move`'s bounds comparison is signed (a piece nudged past
      column 0 or row 0 must be correctly rejected)
- [ ] `piece_hard_drop` and `piece_soft_drop_tick` are both implemented in
      terms of `piece_can_move` — neither one re-implements its own
      legality logic
- [ ] A visible, hardware-observable check confirms `piece_can_move`
      against at least one legal and one illegal hardcoded case
- [ ] No leftover TODO comments in the submitted module
