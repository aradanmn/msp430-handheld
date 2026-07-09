# Tutorial 02 — Hard Drop, Soft Drop, and One Source of Truth for Legality

## Three Ways a Piece Moves Down

By the time the game is fully assembled, a piece can move downward in three
different circumstances:

- **Gravity** — the tick source from `hal/timer.s` (Lessons 09/11) fires,
  and if enough ticks have elapsed, the piece drops one row automatically.
- **Soft drop** — the player holds (or presses) a "move down" input, and
  the piece drops one *extra* row beyond what gravity alone would have
  done that tick.
- **Hard drop** — the player presses a dedicated button, and the piece
  drops immediately, all the way down, to the lowest row it can legally
  occupy — no waiting for ticks at all.

All three end up asking the exact same question — "can this piece occupy
one more row down than it currently does?" — just at different moments and
different numbers of times. That question is `piece_can_move(0, +1)`.

## Hard Drop: Repeat Until It Fails

Hard drop's entire job is to find the lowest legal row for the current
piece and put it there in one visible step. The way to find that row
without inventing any new logic is to lean on the same check repeatedly:

```
row = 0
loop:
    if piece_can_move(0, +1) is true:
        actually move the piece down one row
        row += 1
        go to loop
    else:
        stop — the piece is now at the lowest legal row
```

Each iteration asks "one more row down — still legal?" The moment the
answer is no, the piece is sitting at the last position that *was* legal,
which is exactly where hard drop is supposed to land it. There's no special
"find the floor" math, no scanning the board for the highest stack column
under the piece — the same yes/no check, asked enough times, finds the
floor for free.

## Soft Drop: One Extra Legality-Gated Step

Soft drop looks almost trivial by comparison: on a player input, try to
move down by exactly one row — but "try" is the operative word. Soft drop
must **not** unconditionally move the piece down; it has to gate that move
behind the identical `piece_can_move(0, +1)` check hard drop uses. If the
piece is already resting on the stack (or the floor), a soft-drop input
should not move it further — it should instead be a signal that the piece
has landed, and gravity's next tick should be the one that stamps it down
(Lesson 22's line-clear logic runs right after a piece is placed). That's
why `piece_soft_drop_tick` reports back *whether it
actually moved* — the caller needs to know the difference between "moved
down one row" and "tried to move down and couldn't," because those two
outcomes lead to different next steps in the game loop.

## Why Not Three Separate Checks?

It would be entirely possible to write three different pieces of logic —
one for gravity's drop, one for soft drop, one for hard drop's repeated
stepping — each with its own idea of "is the row below me clear." It would
even work, at first. The problem shows up later, and it shows up as three
different, hard-to-reproduce bugs instead of one:

- If gravity's drop check has an off-by-one that hard drop's doesn't, a
  piece that gravity would have stopped one row higher can be hard-dropped
  one row *further* than it should — the piece visibly buries itself half
  a cell into the stack, only when hard-dropped, never otherwise.
- If soft drop's check forgets the board-occupancy test and only checks
  bounds (an easy mistake — see `exercises/ex2` this lesson), soft drop
  alone lets a piece push through already-placed blocks, while gravity and
  hard drop, using a different and correct check, never do.
- Every one of these bugs is *silent* — nothing crashes, nothing throws an
  error. The board just quietly ends up in a position that shouldn't be
  reachable, and by the time you notice, the piece that caused it is long
  gone and the reproduction steps are "sometimes, doing X, the board looks
  wrong."

Routing gravity, soft drop, and hard drop through the **same**
`piece_can_move` doesn't just save code — it means there is exactly one
place legality can be wrong, and fixing it there fixes it for all three
callers at once. This is the single most important design decision in this
lesson, more so than any individual line of collision-checking logic.

## What Comes Next

`piece_can_move` only answers questions. Once hard drop or gravity finds
that a piece can go no further, something has to make that position
permanent — writing every occupied cell into the board via `board_set`.
That's `piece_place`, and it's the last piece this lesson adds before
Lesson 22 picks up immediately afterward: the instant a piece is placed is
the instant the board needs to be checked for completed lines.
