# Exercise 3 — Milestone: `handheld/gfx/framebuf.s`

**Requires:** Lessons 01–14 + Exercises 1–2

This milestone gives the handheld project its drawing primitives — the
layer every piece of game visuals from here on is built out of. It lives in
`gfx/`, not `hal/`, because it's built on top of the display hardware
abstraction (`hal/display.s`), not talking to hardware directly.

## What to Create

```
handheld/gfx/framebuf.s   ← new file (module doesn't exist yet)
```

This module depends on `handheld/hal/display.s` (Lesson 13's milestone) for
`display_set_pixel` — it does not address GDDRAM or talk to SPI directly.

## Behavioral Spec

- `framebuf_fill_rect` — draws a filled rectangle given two inclusive
  corners (x0, y0) and (x1, y1), where x0 ≤ x1 and y0 ≤ y1.
- `framebuf_hline` — draws a horizontal line from x0 to x1 (inclusive) at
  row y.
- `framebuf_vline` — draws a vertical line from y0 to y1 (inclusive) at
  column x.

All three may assume their coordinate arguments are already in range for
the display (0–127 for x, 0–63 for y) — no bounds-checking is required at
this milestone.

## Public Interface

| Function | Arguments |
|----------|-----------|
| `framebuf_fill_rect` | R12=x0, R13=y0, R14=x1, R15=y1 |
| `framebuf_hline` | R12=x0, R13=x1, R14=y |
| `framebuf_vline` | R12=x, R13=y0, R14=y1 |

## Build & Test

```sh
cd handheld
make && make flash
```

**Success criteria:**
- `handheld/gfx/framebuf.s` compiles cleanly as part of the handheld build
- A filled rectangle call produces a solid block with no gaps and no pixels
  outside the requested bounds
- `framebuf_hline`/`framebuf_vline` produce single-pixel-wide lines exactly
  at the requested row/column
- Register usage follows `handheld/registers.md` — any of R4–R11 borrowed
  as scratch inside these subroutines is pushed on entry and popped before
  return
