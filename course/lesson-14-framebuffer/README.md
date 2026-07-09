# Lesson 14 — Framebuffer & Drawing Primitives

## What You'll Learn

- Why the MSP430G2553's 512 bytes of RAM cannot hold a full on-chip mirror
  of a 128×64 display (1024 bytes needed, twice the entire chip's RAM) — and
  what that constraint forces you to decide
- Building filled-rectangle and line primitives on top of `display_set_pixel`
- Why "obviously correct" pixel-by-pixel drawing has a real performance cost,
  and what a page-based buffering strategy buys you (Exercise 2 explores this)
- The register-budget reality of 3–4-argument subroutines on a 16-register
  machine with only R12–R15 as scratch

## Hardware for This Lesson

No new wiring — same OLED setup as Lessons 12–13.

## How This Connects to the Handheld

The Tetris board is a grid of filled squares. Every block you'll ever place,
every border you'll ever draw, is a filled rectangle or a line. This
lesson's milestone, `gfx/framebuf.s`, is the drawing layer every piece of
game visuals from here on is built out of — literally: this lesson's example
draws the Tetris board border and a single tetromino block.

## Read First

1. `tutorial-01-the-framebuffer-problem.md` — the RAM budget, the options, why this course draws direct-to-display for now
2. `tutorial-02-drawing-primitives.md` — building `fill_rect`, `hline`, `vline` on top of `display_set_pixel`
3. **Datasheet:** none new this lesson — this is pure MSP430 assembly + the `display_set_pixel` interface from Lesson 13

## Then

Attempt the exercises before flashing `examples/framebuf_demo.s`.

## Exercises

See `exercises/README.md`.

## Success Criteria

- [ ] You can state, from memory, why a full 128×64 monochrome framebuffer
      does not fit in this chip's RAM (show the byte-count math)
- [ ] You can explain what "direct-to-display" drawing costs you compared to
      a local buffer (in both directions — what you gain and what you give up)
- [ ] `examples/framebuf_demo.s` builds, flashes, and draws a rectangular
      board border with one filled block inside it
- [ ] You can explain why `fill_rect` needs 4 arguments and how that maps
      onto R12–R15
