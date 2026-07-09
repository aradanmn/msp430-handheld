# Lesson 15 Exercises

Read both tutorials first. Flash `examples/sprite_demo.s` only *after*
you've attempted your own exercises.

---

## Exercise 1 — Explore: Render Bitmap

**Requires:** Lessons 01–14 + Tutorial 01 (tile bitmap format, `sprite_draw`)

**File:** `ex1/ex1.s`

Implement `sprite_draw(ptr, x, y)`: walk all 8 rows of an 8×8 sprite
bitmap, and within each row, all 8 columns (bit 7 = leftmost, per
tutorial-01), calling `display_set_pixel` for every column whose bit is
set. `display_init`/`display_clear`/`display_set_pixel` and the SPI
plumbing under them are provided — `sprite_draw` itself is yours to write.

**What to look up:** nothing new — this reuses `display_set_pixel`
(Lesson 13) and the bit-testing idioms from `msp430g2553-defs.s`'s opening
tutorial, applied to a bitmap row instead of a peripheral register.

**Success criteria:** the `tile_plus` sprite (a plus/cross shape) is
visible at `(SPRITE_X, SPRITE_Y)` on an otherwise blank screen.

---

## Exercise 2 — Challenge: Move Without Artifacts

**Requires:** Lessons 01–15 + Tutorial 02 (artifact-free movement)

**File:** `ex2/ex2.s`

This file steps a sprite rightward across the screen, redrawing it at a
new position every ~100 ms so the motion is visible. `sprite_draw` and
`sprite_erase` are both already implemented and correct in isolation.
Build it and flash it.

**Observed behavior:** as the sprite moves, it leaves a trail behind it —
lit pixels from earlier positions that never fully clear. Sometimes part
of the sprite itself looks partially eaten away as it moves, rather than
showing a clean, solid shape sliding smoothly across the screen.

Find what's wrong with how the movement loop calls `sprite_draw` and
`sprite_erase`, and fix it.

**Success criteria:** the sprite slides cleanly across the screen with no
trailing pixels left behind at any point along its path, and no
partially-erased look at any step.

---

## Exercise 3 — Milestone: `handheld/gfx/sprites.s`

**Requires:** Lessons 01–15 + Exercises 1–2

**What to create:** `handheld/gfx/sprites.s`

See `ex3/README.md` for the full spec.

**Build & test:** `cd handheld && make && make flash`

**Success criteria:** compiles cleanly as part of the handheld build;
drawing then erasing a sprite leaves the screen exactly as it was before
the sprite was drawn.
