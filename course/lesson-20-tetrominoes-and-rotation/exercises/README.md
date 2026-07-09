# Lesson 20 Exercises

Three exercises this lesson. Ex3 extends the `game/tetris.s` milestone
Lesson 19 created — nothing here replaces the board code, it adds to it.

## Ex1 — Explore: Encode and Rotate

**File:** `ex1/tetromino_ops.s`

**Task:** Encode all 7 standard tetrominoes' spawn orientation (rotation 0)
as a table in Flash — one 4x4 shape per piece, however you choose to pack
16 cells into a compile-time constant. Then build a rotation function for
**one** piece of your choosing that derives, or looks up, its next rotation
state. Self-test both the encoding and the rotation function, reporting
PASS/FAIL on LED1 (solid = all checks passed, visibly blinking = at least
one failed).

**What to look up:** bit shifting (`RLA`/`RRA`, same as Lesson 19), the
difference between `.byte` and `.word` directives and what "word vs. byte
access" means for a 16-cell shape, and indexed addressing into a Flash
table (`table(Rn)`) — you used this exact addressing mode for the board in
Lesson 19, just against RAM instead of Flash.

The starter file has boilerplate and LED1's direction setup only. Reference
shapes for all 7 tetrominoes are in this lesson's `README.md` and
`tutorial-01` — encoding them correctly, and addressing them correctly, is
the exercise; the shapes themselves are given.

**Success criteria:**
- [ ] All 7 tetrominoes' spawn orientation are encoded in your Flash table
- [ ] A self-test confirms your table decodes correctly against the
      reference shapes (test every cell of at least the piece you chose to
      rotate, ideally all 7)
- [ ] Your rotation function, applied 4 times in a row to your chosen
      piece, returns to that piece's original shape
- [ ] LED1 lights solid if every check passes, blinks if any fails

## Ex2 — Challenge: Rotation Drift

**File:** `ex2/piece_rotate_probe.s`

`ex2/piece_rotate_probe.s` is a complete, compiling program. Its header
comment states the *intended* behavior. Build it, flash it, and watch LED1.

**Observable failure:** LED1 does not stay solid through all six rotation
steps the program runs. Partway through the sequence, it starts blinking —
meaning the program has found a rotation state that matches **none** of the
four words it encoded for this piece, even though the sequence started out
fine (the first several steps do match one of the four valid encodings).

Your job: figure out how many steps run correctly before the mismatch
appears, and reason from there about what's different between a rotation
index that stays valid and one that doesn't. This exercise will not tell
you which line, which register, or which arithmetic step is responsible.

**Success criteria:**
- [ ] I can state how many rotation steps complete correctly before LED1
      starts blinking
- [ ] I can explain, using this lesson's addressing math, why an
      out-of-range rotation index doesn't just fail loudly — it reads
      *something*, and that something happens to not be one of the four
      valid words
- [ ] After my fix, LED1 stays solid through all six steps — and I can
      argue why it would stay solid through any number of steps, not just
      six

## Ex3 — Milestone: `game/tetris.s` (pieces)

See `ex3/README.md` for the full spec. This **extends**
`handheld/game/tetris.s` (created in Lesson 19) with `piece_rotation_cw`
and `piece_cell`, alongside the existing `board_*` functions.
