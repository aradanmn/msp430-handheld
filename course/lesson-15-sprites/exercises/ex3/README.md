# Exercise 3 — Milestone: `handheld/gfx/sprites.s`

**Requires:** Lessons 01–15 + Exercises 1–2

This milestone gives the handheld project its sprite-drawing primitives —
`sprite_draw` and `sprite_erase`. Every tetromino from Lesson 20 onward is
rendered through this module.

## What to Create

```
handheld/gfx/sprites.s   ← new file (module doesn't exist yet)
```

This module depends on `handheld/hal/display.s` for `display_set_pixel`
and `display_clear_pixel` — it does not address GDDRAM or talk to SPI
directly.

## Behavioral Spec

- All sprites in this course are **8×8, 1-bit-per-pixel** bitmaps: 8 bytes,
  one per row, bit 7 = leftmost column, bit 0 = rightmost column (see
  tutorial-01).
- `sprite_draw` — draws a sprite bitmap at the given (x, y) position
  (x, y = the sprite's top-left corner). Lights a pixel for every set bit
  in the bitmap; leaves clear bits untouched (does not clear anything).
- `sprite_erase` — clears the entire 8×8 footprint at the given (x, y)
  position, regardless of what bitmap (if any) was drawn there. It does
  not take a bitmap pointer — erasing only needs to know where, not what
  was there.
- **This module does not decide draw/erase ordering for a moving sprite.**
  That's the caller's responsibility (see tutorial-02) — `sprite_draw` and
  `sprite_erase` are independent primitives, not a combined "move" function.

## Public Interface

| Function | Arguments |
|----------|-----------|
| `sprite_draw` | R12 = pointer to 8-byte bitmap, R13 = x, R14 = y |
| `sprite_erase` | R12 = x, R13 = y |

## Build & Test

```sh
cd handheld
make && make flash
```

**Success criteria:**
- `handheld/gfx/sprites.s` compiles cleanly as part of the handheld build
- `sprite_draw` followed immediately by `sprite_erase` at the same (x, y)
  leaves the screen exactly as it was before either call
- Register usage follows `handheld/registers.md` — any of R4–R11 borrowed
  as scratch inside these subroutines is pushed on entry and popped before
  return
