# Lesson 15 — Sprites & Tiles

## What You'll Learn

- Storing small bitmap images ("tiles" or "sprites") in Flash as compact
  byte arrays, and reading them with indexed/indirect addressing
- Building `sprite_draw` on top of Lesson 14's drawing primitives
- The classic 2D-graphics bug: leaving trails behind a moving sprite — and
  why the fix is about *ordering*, not about drawing anything differently
- Why "erase, then draw" is the correct order for artifact-free movement,
  and what actually goes wrong with "draw, then erase"

## Hardware for This Lesson

No new wiring — same OLED setup as Lessons 12–14.

## How This Connects to the Handheld

Every tetromino is a sprite. Once a piece can render itself and move
without leaving a trail on the board, the game has everything it needs,
visually, to let a piece fall and be steered by the player — the
remaining lessons are about the rules (collision, rotation, line clears),
not the pixels.

## Read First

1. `tutorial-01-tile-bitmaps-in-flash.md` — bitmap format, storing tiles in Flash, `sprite_draw`
2. `tutorial-02-artifact-free-movement.md` — why "erase, then draw" (not the reverse) is the only order that doesn't leave trails
3. **Datasheet:** none new this lesson — pure MSP430 assembly + the `gfx/framebuf.s` and `hal/display.s` interfaces from Lessons 13–14

## Then

Attempt the exercises before flashing `examples/sprite_demo.s`.

## Exercises

See `exercises/README.md`.

## Success Criteria

- [ ] You can explain how a 1-bit-per-pixel 8×8 sprite is packed into 8 bytes, and which bit corresponds to which column
- [ ] `examples/sprite_demo.s` builds, flashes, and shows a recognizable diamond-shaped sprite at a fixed position on an otherwise blank screen
- [ ] You can explain, precisely, what goes wrong if a moving sprite is drawn at its new position *before* being erased at its old position
- [ ] You can state the general rule ("erase old position first, then draw new position") without needing to re-derive it from scratch
