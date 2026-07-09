# Lesson 14 Exercises

Read both tutorials first. Flash `examples/framebuf_demo.s` only *after*
you've attempted your own exercises.

---

## Exercise 1 — Explore: Pixel/Line to Byte Array

**Requires:** Lessons 01–13 + Tutorial 02 (Lesson 13's page/bit addressing math)

**File:** `ex1/ex1.s`

Compute pixel and line placement into a local 128-byte RAM array
(`page_buf`, representing one OLED page) without touching SPI or the
display at all. No hardware needed to grade this one — a provided self-check
compares your buffer against known-correct values and reports pass/fail via
LED1.

**What to look up:** nothing new — this reuses Lesson 13 tutorial-02's
page/bit addressing math, applied to a plain array instead of GDDRAM.

**Success criteria:** LED1 lights if `page_buf` matches `expected_buf`
exactly after your code runs.

---

## Exercise 2 — Challenge: Dirty-Page Optimisation

**Requires:** Lessons 01–14 + Tutorial 01 (the framebuffer problem) + Tutorial 02

**File:** `ex2/ex2.s`

This file fills the entire 128×64 screen using `framebuf_fill_rect` —
exactly the technique from this lesson's tutorial and example. Build it,
flash it, and watch the OLED while it runs.

**Observed behavior:** the fill is clearly not instantaneous. Watching the
screen, you can see it being painted — not a single flash from blank to
fully lit, but a visible progression across the panel that takes a
noticeable fraction of a second (or more) to finish.

A real game redraws parts of the board many times per second, every
frame. At this fill speed, that isn't going to keep up.

**Your task:** redesign the fill so that a full-screen (or large-region)
update is dramatically faster than what's here — fast enough that repeated
full-board redraws during real gameplay wouldn't be visibly slow. You are
free to change anything about how pixels get from your program to the
display; `display_set_pixel`'s existing per-pixel addressing protocol
(Lesson 13) is not a required stop along the way. Document your approach
in a comment block at the top of the file: what you changed, and why it's
faster.

**Success criteria:** the same visual result (the requested region fully
lit) appears dramatically faster than the provided version — the "visible
paint" progression should no longer be obvious to the eye.

---

## Exercise 3 — Milestone: `handheld/gfx/framebuf.s`

**Requires:** Lessons 01–14 + Exercises 1–2

**What to create:** `handheld/gfx/framebuf.s`

See `ex3/README.md` for the full spec.

**Build & test:** `cd handheld && make && make flash`

**Success criteria:** compiles cleanly as part of the handheld build;
drawing a board border and a filled block produces the same result as this
lesson's example.
