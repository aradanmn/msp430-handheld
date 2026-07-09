# Exercise 3 — Milestone: `handheld/hal/display.s`

**Requires:** Lessons 01–13 + Exercises 1–2

This milestone gives the handheld project its OLED driver — init, clear, and
single-pixel drawing. Everything visual from Lesson 14 onward calls into
this module.

## What to Create

```
handheld/hal/display.s   ← new file (module doesn't exist yet)
```

This module depends on `handheld/hal/spi.s` (Lesson 12's milestone) for
`spi_tx_byte` — it does not talk to USCI_B0 registers directly.

## Behavioral Spec

- `display_init` — performs the hardware reset pulse (RST pin) and sends
  the controller's init command sequence (display off, clock/oscillator,
  multiplex, charge pump, addressing mode, contrast, remap, display on —
  see tutorial-01's category table). Configures CS, DC, and RST as outputs.
  Leaves the display on and cleared to whatever GDDRAM happened to power up
  with — call `display_clear` to guarantee a blank screen.
- `display_clear` — writes 0x00 to every byte of GDDRAM (every column, every
  page), leaving the entire panel dark.
- `display_set_pixel` — lights the pixel at the given (x, y) coordinate by
  computing its page/bit, addressing that single column/page, and writing
  one data byte with only that bit set. This is a blind write — it will
  clobber the other 7 pixels sharing that GDDRAM byte if they aren't
  already 0 (see tutorial-02). That's expected at this milestone; Lesson 14
  addresses it.
- `display_clear_pixel` — the mirror image of `display_set_pixel`: same
  addressing, but the data byte written has every bit clear instead of one
  bit set. Turns the given pixel off. Same blind-write caveat applies.
- This module owns its own CS (P2.0) and DC (P2.1) pins — set them around
  each SPI transaction as described in tutorial-01. It does not touch
  `hal/spi.s`'s internals beyond calling `spi_tx_byte`.

## Public Interface

| Function | Arguments | Returns |
|----------|-----------|---------|
| `display_init` | — | — |
| `display_clear` | — | — |
| `display_set_pixel` | R12 = x (0–127), R13 = y (0–63) | — |
| `display_clear_pixel` | R12 = x (0–127), R13 = y (0–63) | — |

## Build & Test

```sh
cd handheld
make && make flash
```

**Success criteria:**
- `handheld/hal/display.s` compiles cleanly as part of the handheld build
- After `display_init` + `display_clear` + one `display_set_pixel` call, the
  panel shows exactly one lit pixel at the requested coordinate and nothing
  else
- Register usage follows `handheld/registers.md`
