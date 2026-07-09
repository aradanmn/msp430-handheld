# Tutorial 02 — Artifact-Free Movement

## The Problem: Nothing "Un-Draws" Itself

`display_set_pixel` (Lesson 13) only ever turns a pixel on. `sprite_draw`
only ever lights the pixels a bitmap says to light — it never touches
anything else. Nothing about this pipeline has any notion of "the previous
frame." If a tetromino sits at column 5 for one tick and column 6 the next,
and all you do is call `sprite_draw` again at the new position, the pixels
from column 5 are **still lit** — nothing ever told the display they should
turn off. The result: a trail of lit pixels following every moving object
around the screen, forever, until the whole screen fills in.

The fix requires an explicit **erase** step: a call that turns off every
pixel in a sprite's bounding box, regardless of the bitmap's content —
because you're clearing an area, not un-drawing a specific shape. (This is
exactly why `sprite_erase`, in this lesson's milestone, doesn't take a
bitmap pointer at all — it just needs to know where.)

## The Bug That Looks Like It Should Work

Here's the tempting, wrong approach: each tick, draw the sprite at its new
position, *then* erase it at its old position — reasoning that "the new
picture is drawn, so it's now safe to clean up the old one." Trace through
what actually happens when a sprite moves right by 3 pixels within an 8-pixel
tile (so the old and new 8×8 footprints overlap by 5 columns):

```
Old footprint:  columns 0-7
New footprint:  columns 3-10
Overlap:        columns 3-7   (both footprints cover these columns)
```

**Draw-then-erase, step by step:**
1. Draw sprite at new position (columns 3-10) → columns 3-7 (the overlap)
   get lit as part of the new sprite.
2. Erase old position (columns 0-7) → **columns 3-7 get cleared again** —
   because "erase" doesn't know or care that those columns are also part
   of the sprite you just drew. It just clears its whole bounding box.

Net result: the overlap region — which should show the moving sprite — ends
up dark. Depending on exact timing and how much the sprite overlaps itself
frame to frame, this shows up as a flickering, partially-erased sprite:
exactly the "ghost-eaten-away" look that makes this bug so recognizable
once you've seen it.

## The Fix: Erase First, Draw Last

Reverse the order:

```
1. Erase sprite at its OLD position (columns 0-7 dark)
2. Update the position variables
3. Draw sprite at its NEW position (columns 3-10 lit, including the overlap)
```

Now the overlap region (columns 3-7) gets cleared in step 1 and then
correctly re-lit in step 3 — the *last* thing that happens to any pixel in
the overlap is "draw," so the overlap ends up exactly as it should: lit,
matching the new sprite position. Whichever operation touches a given pixel
**last** wins, so making "draw" the last word for every pixel that should
end up lit is the entire fix. No new drawing logic, no bookkeeping about
which columns overlap — just doing erase before draw, every time, for every
moving sprite.

## The Rule

**Always erase a sprite at its old position before drawing it at its new
position — never the reverse.** This holds regardless of how far the
sprite moved, whether the two footprints overlap at all, or which
direction it's moving. It costs nothing extra (the same two calls happen
either way) — it's purely a question of sequencing.

## What's Next

This lesson's exercises put you in a position to observe the "draw before
erase" failure firsthand (Exercise 2) and to build both `sprite_draw` and
`sprite_erase` as clean, general primitives that any calling code —
including the piece-movement logic in Lesson 20 — can sequence correctly.
