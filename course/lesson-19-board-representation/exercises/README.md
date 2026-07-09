# Lesson 19 Exercises

Three exercises this lesson: Explore, Challenge, and — for the first time
since Lesson 07 — a handheld milestone. `game/tetris.s` is created here and
grows through Lessons 20-22.

## Ex1 — Explore: Board Read/Write

**File:** `ex1/board_ops.s`

**Task:** Build `board_get(row, col)` and `board_set(row, col, val)` from
scratch as a standalone program (this is not the handheld milestone — that's
Ex3). The board is 20 rows x 10 columns, packed one bit per cell. Choose a
bit layout (row-major or column-major, MSB-first or LSB-first) and use it
consistently in both subroutines. `board_init` (clears the board), the
addressing math, and a self-test that reports PASS/FAIL on LED1 (solid = all
checks passed, visibly blinking = at least one failed) are all yours to
design.

Your self-test must include at least:
- A round trip on an interior cell
- A round trip on `row 0, col 0`
- A round trip on the last cell of the board (`row 19, col 9`)
- Confirmation that setting one cell does not change a neighboring cell's
  value

**What to look up:** the shift/rotate instructions (`RLA`, `RRA`) covered in
Lessons 02-03 — this board has no multiply instruction available, so
`row * 10` has to be built out of shifts and adds. You'll also want the
`BIT`/`BIS`/`BIC` bit-idioms from Lesson 03, applied to a RAM byte you
address yourself rather than to `P1OUT`. SLAU144's GPIO chapter (Ch. 8) is
not relevant here — this exercise is pure arithmetic and data structure, not
a peripheral.

The starter file has boilerplate, the RAM reservation for the board array,
and LED1's direction setup only.

**Success criteria:**
- [ ] `board_init`, `board_get`, and `board_set` exist and are internally
      consistent (whatever you write to a cell reads back correctly)
- [ ] The four round-trip cases above are all exercised by your self-test
- [ ] LED1 lights solid if every check in your self-test passes
- [ ] LED1 visibly blinks if you deliberately break one check (temporarily,
      to confirm your failure path actually works) and reflash

## Ex2 — Challenge: Board Probe

**File:** `ex2/board_probe.s`

`ex2/board_probe.s` is a complete, compiling program. Its header comment
states the *intended* behavior. Build it, flash it, and watch LED1.

**Observable failure:** LED1 does not stay solid. It blinks — meaning one of
the checks the program runs after its sequence of `board_set`/`board_get`
calls no longer matches what it expects, even though the two board cells the
program explicitly sets and rereads (`row 5, col 3` and `row 5, col 4`) still
report the correct values.

Something *else*, stored in memory right after the board array, has changed
value — and none of the board's own read/write checks caught it happening.

Your job: figure out which call in the sequence is responsible, and explain
in your own words why calling `board_set`/`board_get` with a coordinate
outside the board's valid range (rows 0-19, columns 0-9) can silently change
memory that has nothing to do with the board, without crashing and without
either function reporting an error. This exercise will not tell you which
line or which register is involved, and it will not tell you how to prevent
it — reasoning about *why* it happens is the point.

**Success criteria:**
- [ ] I can identify which specific `board_set`/`board_get` call in the
      sequence is the one responsible
- [ ] I can state, in one or two sentences, why the corruption doesn't
      crash the program or show up in the checks on the cells that were
      deliberately being tested
- [ ] I can explain what "out of range" means here in terms of the
      addressing math from tutorial-02, not just "the numbers were wrong"

## Ex3 — Milestone: `game/tetris.s` (board)

See `ex3/README.md` for the full spec. This creates
`handheld/game/tetris.s` for the first time, with `board_init`, `board_get`,
and `board_set`.
