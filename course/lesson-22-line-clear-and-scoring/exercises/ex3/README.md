# Exercise 3 — Milestone: `handheld/game/tetris.s` (rules)

This extends the same `handheld/game/tetris.s` that Lesson 19 started
(`board_get`, `board_set`), Lesson 20 continued (`piece_cell`,
`piece_rotation_cw`), and Lesson 21 continued again (`piece_can_move`,
`piece_place`, `piece_hard_drop`, `piece_soft_drop_tick`). You are **not**
creating a new file and you are **not** touching the functions already
there — you're adding three new public entry points to it.

Follow the conventions already established for the project:

- Public labels are prefixed `board_` or `score_` as appropriate; local
  labels use the `.L` prefix (see CLAUDE.md's "Assembly File Conventions")
- Argument/return convention: arg 1 in R12, arg 2 in R13, return value in
  R12 — the same convention every function already in `tetris.s` uses
- Register usage follows `handheld/registers.md`

## What Already Exists (do not redefine or contradict)

- `board_get(row, col)` → 1/0, `board_set(row, col, val)` — the packed,
  10-bits-per-row board from Lesson 19
- `piece_cell(piece_id, rotation, row, col)`, `piece_rotation_cw(piece_id,
  rotation)` — Lesson 20
- `piece_can_move(dx, dy)`, `piece_place()`, `piece_hard_drop()`,
  `piece_soft_drop_tick()` — Lesson 21

None of this milestone's new functions need to know how the board is
packed internally — that's exactly what `board_get`/`board_set` already
hide. Whatever internal layout you choose for anything new this milestone
needs (a running score, a running line count, a level number) is your call;
it isn't specified here.

## Behavioral Spec

Add these three public entry points to `handheld/game/tetris.s`:

- **`board_check_lines()`** — no arguments. Scans all 20 rows of the board
  and returns, in R12, a count (0-4) of how many rows are currently
  completely full. Does not modify the board or clear anything — it only
  counts.

- **`board_clear_line(row)`** — `row` in R12 (0-19), the index of one full
  row to remove. Removes that row and shifts every row above it down by
  one; the top row (row 0) becomes completely empty afterward. Rows below
  `row` are left unchanged. Does not check whether `row` is actually full
  — the caller is responsible for only passing a row that
  `board_check_lines` has confirmed is full.

- **`score_add_lines(count)`** — `count` in R12 (1-4), the number of lines
  cleared by a single piece placement. Updates the running score per the
  standard Tetris table (1 line = 100, 2 = 300, 3 = 500, 4 = 800) and
  updates a running total-lines-cleared count; every time that running
  total crosses a multiple of 10, increases a running level number by one.
  No return value.

If a placed piece completes more than one line at once, `board_clear_line`
is called once per full line — in an order that keeps every call's `row`
argument correct as the board changes underneath it is part of what you
need to get right.

## Integrating into `handheld/main.s`

Exercise `board_check_lines`, `board_clear_line`, and `score_add_lines`
against a hardcoded test board and confirm the result on hardware — the
same solid-LED1/blinking-LED1 pattern this lesson's examples and exercises
already use is a reasonable choice, but the exact mechanism is up to you.
The requirement is that correctness is observable by flashing the board
and watching it, not just "it compiles."

## Success Criteria

- [ ] `handheld/game/tetris.s` gains `board_check_lines`,
      `board_clear_line`, and `score_add_lines`, without modifying the
      existing functions' names or argument conventions
- [ ] `cd handheld && make flash` builds and flashes cleanly
- [ ] `board_check_lines` correctly distinguishes a completely full row
      from one that's merely nearly full (9 of 10 columns)
- [ ] `board_clear_line` leaves every row below the cleared line
      byte-for-byte unchanged, and correctly shifts every row above it
- [ ] `score_add_lines` uses `.equ` constants for the scoring table
      (100/300/500/800), not inline magic numbers
- [ ] The level-up rule fires exactly once per multiple of 10 total lines
      crossed, even when a single multi-line clear crosses that boundary
- [ ] A visible, hardware-observable check confirms at least
      `board_check_lines` and `board_clear_line` against a hardcoded case
- [ ] No leftover TODO comments in the submitted module
