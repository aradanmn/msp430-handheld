# Lesson 22 Exercises

Three tiers: Explore (ex1), Challenge (ex2), Milestone (ex3).

## Ex1 — Explore: Row-Full Check

**File:** `ex1/row_full_check.s`

The starter file has the standard boilerplate, LED1 configured as an
output, and a hardcoded 25-byte packed board (`.Lex1_board_template`,
20 rows x 10 columns, no padding — the same layout `examples/
lineclear_demo.s` uses) already copied into a RAM buffer for you. Below
that is a table of `(row, expected)` test cases.

Your job: write the "is this row full" check yourself — extract a given
row's 10 packed bits (reading across a byte boundary where needed — see
tutorial-01) and compare against an all-ones mask — and a runner that
walks the test table, compares your check's result for each row against
its expected value, and drives LED1: solid if every case matches, blinking
if any doesn't.

Look up:
- The byte-index / bit-offset arithmetic from tutorial-01
  (`byte_idx = base_bit / 8`, `bit_off = base_bit mod 8`)
- Bit masking across a byte boundary: combining two bytes into a 16-bit
  window before shifting, rather than trying to read "half a byte"
  directly
- Comparing your extracted 10-bit value against an all-ones mask for full
  vs. not full — pay attention to at least one test row that's 9-of-10
  bits set, and make sure your check correctly calls that "not full"

**Success criteria:**
- [ ] `make flash` builds and flashes without error
- [ ] LED1 lands solid, confirming every hardcoded test case in
      `.Ltest_vectors` matches its expected full/not-full result
- [ ] The check correctly rejects a row that's 9 of 10 columns full
- [ ] No leftover `TODO` comments in the file you submit

## Ex2 — Challenge: Shift-Down Alignment

**File:** `ex2/line_shift_bug.s`

`ex2/line_shift_bug.s` is a complete, compiling program. Its header
comment states the intended behavior. Build it, flash it, and watch LED1.

**Observable failure:** the full row is correctly detected, and the rows
above it shift down exactly as expected — but after the clear, the bottom
couple of rows show a bit pattern that matches neither their original
content nor an empty row.

Your job: figure out why, in terms of this lesson's material (which rows
the shift-down step is supposed to touch, and which it must leave alone),
and fix it — not by special-casing which row was cleared, but by
correcting the general shift so it's right regardless of which row is
full.

**Success criteria:**
- [ ] I can state which rows end up with incorrect data, and what data
      they end up holding instead of their original content
- [ ] I can explain why the rows *above* the cleared line already come out
      correct despite the bug
- [ ] After my fix, LED1 lands solid — the cleared-and-shifted board
      matches the hand-computed expected result byte for byte

## Ex3 — Milestone: `handheld/game/tetris.s` (rules)

**Directory:** `ex3/`

See `ex3/README.md` for the full behavioral spec. This extends
`handheld/game/tetris.s` again — the same file Lessons 19-21 built up with
`board_get`/`board_set`, `piece_cell`/`piece_rotation_cw`, and
`piece_can_move`/`piece_place`/`piece_hard_drop`/`piece_soft_drop_tick` —
with the rules layer: `board_check_lines`, `board_clear_line`, and
`score_add_lines`.

`ex3/ex3.s` is an intentionally empty placeholder — the real work happens
in `handheld/game/tetris.s`, which you extend, not recreate.
