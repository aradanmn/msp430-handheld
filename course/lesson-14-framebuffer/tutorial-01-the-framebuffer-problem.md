# Tutorial 01 — The Framebuffer Problem

## The Numbers

The OLED in this project is 128 pixels wide, 64 pixels tall, monochrome —
one bit per pixel. A full mirror of that screen, the kind of "framebuffer"
you'd take for granted on almost any other platform, needs:

```
128 * 64 bits = 8192 bits = 1024 bytes
```

The MSP430G2553 has **512 bytes of RAM, total** — for the stack, every
global variable, every register spill, everything. A full framebuffer alone
is **twice** the entire chip's memory. This isn't a "the framebuffer would
be a bit tight" situation — it is categorically impossible to hold a
full-screen bitmap copy on-chip, no matter how carefully you budget
everything else.

This is worth sitting with, because most drawing-primitives tutorials you'll
find online silently assume you *can* keep a full framebuffer in RAM and
`memcpy` it out to the display each frame. That assumption is simply false
on this hardware. Every drawing decision from here to the end of the course
has to be made with that constraint in view.

## The Options

**Option A — Mirror the whole screen off-chip.** The 23LC1024 SPI SRAM in
this project's BOM has 128 KB — more than enough to hold a full framebuffer
(or several). This is exactly what Lesson 25 does: `gfx/framebuf.s` gets
upgraded to be SRAM-backed once the external memory is wired up. It's the
"correct," scalable answer — but it isn't available yet. Lesson 25 is a
long way off, and the game needs to draw things well before then.

**Option B — Draw directly to the display, with no local buffer at all.**
Every primitive (a filled rectangle, a line) is computed and written
straight to GDDRAM via `display_set_pixel`, one pixel at a time, with no
RAM cost beyond a handful of loop-counter registers. This works *today*,
requires no new hardware, and is exactly what Lesson 13's
`display_set_pixel` already gives you. The cost: every single pixel write
is a full SPI transaction with its own column/page addressing overhead
(recall from Lesson 13 — setting one pixel means sending six command bytes
plus one data byte). Filling a large rectangle this way sends a lot of SPI
traffic for what is, informationally, a very repetitive pattern. You'll see
exactly how much this costs in Exercise 2.

**Option C — Buffer a small piece of the screen at a time** (a single page,
or a single tile), draw into that local buffer with ordinary byte
read-modify-write, then flush just that piece to the display. This is a
genuine middle ground — 128 bytes (one page) or even 8 bytes (one tile)
fits comfortably in RAM, and it fixes the "clobbers its neighbors" problem
from Lesson 13's `display_set_pixel` for anything drawn within one flush.
It costs you bookkeeping: you have to track what's "dirty" (changed since
the last flush) to get any benefit over just always flushing everything.

## What This Course Does, and When

**This lesson (14) adopts Option B.** `gfx/framebuf.s`'s primitives —
`framebuf_fill_rect`, `framebuf_hline`, `framebuf_vline` — are built directly
on top of `display_set_pixel`, computing which pixels a shape covers and
writing each one straight to the display. No local buffer, no RAM cost
beyond loop counters. This is not a placeholder to be embarrassed about — it
is a legitimate, working way to draw graphics, and it is exactly correct for
this lesson's success criteria (a static board border and a single block,
drawn once at startup).

**Exercise 2 asks you to notice where Option B starts to hurt** and to
explore Option C's page-buffering as the fix — this is the "dirty-page
optimisation" the exercise is named for.

**Lesson 25 delivers Option A** once external SRAM is wired up, at which
point `gfx/framebuf.s` is rewritten to keep a full off-chip mirror and the
whole "which pixels changed" question gets answered by comparing against
that persistent buffer instead of recomputing shapes from scratch every
frame.

## What's Next

Tutorial 02 builds the actual primitives — `fill_rect`, `hline`, `vline` —
on top of `display_set_pixel`, and works through the register-budget
question that four-argument subroutines force on you with only R12–R15
available as scratch.
