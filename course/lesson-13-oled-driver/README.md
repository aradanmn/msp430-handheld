# Lesson 13 — OLED Driver

## What You'll Learn

- How a SPI OLED controller separates **command** bytes from **data** bytes
  using a sideband GPIO pin (DC), not anything in the SPI protocol itself
- The controller-init pattern: reset pulse, then a sequence of setup commands
  before the panel will display anything
- Page/column addressing — how the controller's own onboard display memory
  (GDDRAM) maps x/y pixel coordinates onto bytes
- Why the exact command bytes are part-specific, and how to read a
  controller datasheet instead of trusting a hex dump from memory

## Hardware for This Lesson

Same wiring as Lesson 12: OLED SCLK -> P1.5, MOSI -> P1.7, CS -> P2.0,
DC -> P2.1, RST -> P2.2, 3.3V power (see [`wiring/phase-2-oled-display.md`](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/wiring/phase-2-oled-display.md)).
**Remove the P1.7 -> P1.6 loopback jumper from Lesson 12** — MISO isn't wired
to the OLED at all, and leaving that jumper in place will make P1.6 fight the
signal coming from whatever the OLED does (or doesn't) drive there.

## A Note on Exact Commands

This course teaches the SSD1306 command set as the reference example — it's
one of the most widely documented OLED controllers, and reasoning through its
init sequence teaches the pattern every SPI OLED controller follows. Your
actual board may be a different but related part (the BOM references the
SSD1325, a grayscale cousin with more capability and some different command
values). **Command bytes are controller-specific.** Before you trust any hex
byte in this lesson's materials against your own hardware, check it against
your part's actual datasheet. The categories of what needs configuring
(oscillator, charge pump, addressing mode, contrast, remap, display on/off)
are consistent across the whole family — the exact byte values are not
guaranteed to be.

## How This Connects to the Handheld

`hal/display.s` is the first module that turns SPI bytes into something you
can see. Every subsequent visual lesson — the framebuffer (L14), sprites
(L15), and eventually the whole Tetris board — reduces to calls into
`display_set_pixel`.

## Read First

1. `tutorial-01-controller-init.md` — command/data protocol, reset, the init sequence pattern
2. `tutorial-02-addressing-and-pixels.md` — page/column addressing, drawing one pixel, why a byte-write clobbers its neighbors without a framebuffer
3. **Datasheet:** your OLED controller's own datasheet (SSD1306, SSD1325, or SSD1309 depending on what's in your BOM) — command tables and addressing diagrams

## Then

Attempt the exercises before flashing `examples/display_demo.s`.

## Exercises

See `exercises/README.md`.

## Success Criteria

- [ ] You can explain what the DC pin does and why it isn't part of the SPI protocol itself
- [ ] You can explain why a fresh SSD1306-family panel shows nothing until a specific init sequence runs
- [ ] `examples/display_demo.s` builds, flashes, and lights exactly one pixel at (10, 10) on an otherwise-blank screen
- [ ] You can explain why `display_set_pixel`, as built in this lesson, can clobber other pixels sharing the same GDDRAM byte
