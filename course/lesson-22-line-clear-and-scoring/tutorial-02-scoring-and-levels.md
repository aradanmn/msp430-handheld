# Tutorial 02 — Shifting Rows Down, Scoring, and Leveling Up

## Clearing a Line: What Has to Move

Once a row is confirmed full, it needs to disappear and everything above
it needs to drop down by one row — exactly the way stacked blocks fall
when you pull one out from under them. Concretely, for a cleared row `r`:

```
for dest_row from r down to 1:
    copy row (dest_row - 1)'s content into row dest_row
row 0 becomes completely empty
```

Walking *downward* from the cleared row (not upward from row 0) matters:
each destination row's new content comes from the row immediately above
it, and if you process rows in the wrong order you'd overwrite a row's
data before you'd copied it somewhere. Rows **below** the cleared row are
never touched at all — they weren't affected by the clear, and shifting
them would corrupt board state that's already correct.

Whether you implement the shift by moving 10-bit rows wholesale (with the
same straddling-byte read from Tutorial 01, plus a matching write) or by
moving one column at a time with cell-level get/set calls is an
implementation choice — either is a legitimate way to satisfy the
behavior. What matters is the *result*: every row above the cleared line
ends up holding what used to be directly above it, the top row ends up
empty, and nothing below the cleared line changes.

## Scoring: `.equ` Arithmetic, Not Magic Numbers

Standard Tetris scoring rewards clearing multiple lines with a single
piece disproportionately more than clearing them one at a time — this is
what makes stacking up a well and clearing four lines at once (a "Tetris")
worth chasing instead of just clearing whatever's available immediately:

```
.equ    SCORE_1,    100     ; one line cleared
.equ    SCORE_2,    300     ; two lines cleared at once
.equ    SCORE_3,    500     ; three lines cleared at once
.equ    SCORE_4,    800     ; four lines cleared at once (a "Tetris")
```

These are look-up values, not a formula — 300 isn't "2 × 100," and 800
isn't "4 × 100" (that would be 400). A line-clear count of 0-4 selects
directly into this small table; there's no arithmetic to derive one score
from another.

## Leveling Up

Tetris tracks a running total of lines cleared across the whole game (not
just per piece), and every time that running total crosses a multiple of
10, the level increases by one:

```
.equ    LINES_PER_LEVEL, 10
```

```
lines_cleared_total += lines_cleared_this_piece
if lines_cleared_total / LINES_PER_LEVEL > current_level:
    current_level += 1
    ; hand a new, shorter tick period to hal/timer.s
```

The division-and-compare form matters more than it looks: a piece that
clears more than one line at once (say, clearing lines 9 and 10 of the
game with a single double-clear) needs to trigger exactly one level-up,
not zero and not two — comparing the *before* and *after* totals against
multiples of `LINES_PER_LEVEL` handles that correctly, whereas checking
only "did this piece's clear count exactly hit a multiple of 10" would
miss a level-up that happens to land mid-multi-line-clear.

## Handing Off to the Timer

This lesson stops at *deciding* the level increased — it does not
reconfigure `hal/timer.s`'s tick period itself. That module (Lessons 09 and
11) already owns Timer_A's configuration and already knows how to produce
a tick of a given length; "level increased" just means the game loop needs
to ask it for a shorter one. Exactly how much shorter per level, and
exactly what interface `hal/timer.s` exposes for changing its period, is a
design decision for whoever wires the level system into the running game
— this lesson's job is only to get the level number right.
