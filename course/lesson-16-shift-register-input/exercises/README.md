# Lesson 16 Exercises

## Exercise 1 (Explore) — 8-Button Display

Wire up the SN74HC165N per [`wiring/phase-3-buttons-shift-register.md`](https://github.com/aradanmn/Handheld-MSP430/blob/main/wiring/phase-3-buttons-shift-register.md)
and write a standalone program (`ex1/buttons_display.s`) that reads all 8
buttons in one transaction and reports them using the two onboard LEDs:

- **LED1** must be lit whenever *any* D-pad direction (Up, Down, Left, or
  Right) is held, and off when none are
- **LED2** must be lit whenever *any* face/menu button (A, B, Start, or
  Select) is held, and off when none are
- Both LEDs may be lit at once if buttons from each group are held
  simultaneously

Look up in SLAU144 Ch 16: USCI_B0 SPI master mode configuration bits
(clock phase/polarity, MSB-first, master enable, synchronous mode).

**Success criteria:**
- [ ] Holding any single D-pad button lights LED1 and leaves LED2 off
- [ ] Holding any single face button lights LED2 and leaves LED1 off
- [ ] Holding one of each lights both
- [ ] Releasing all buttons turns both LEDs off within one polling pass

## Exercise 2 (Challenge) — Ghost-Press Bug Hunt

`ex2/ghost_press.s` is wired and flashed identically to the lesson
example, mapped to the Up button (bit 7) instead of A. Build and flash it,
then test it against a stopwatch or just by pressing/releasing at a
deliberate, slow pace.

**Observable failure:** LED1's state consistently reflects what the Up
button was doing *one polling pass ago*, not its current state. Press Up
and the LED doesn't light until the next pass; release it and the LED
stays lit for one extra pass afterward. The lag is consistent and
reproducible on every single poll — this isn't intermittent noise.

Find and fix the cause. Do not just add a longer delay — the bug is
structural, not a timing-margin issue.

**Success criteria:**
- [ ] LED1 reflects the Up button's *current* state on the same polling
      pass the button changes, with no observable one-cycle lag

## Exercise 3 (Milestone) — Extend `handheld/hal/input.s`

See `ex3/README.md` for the full spec. You are extending the module you
built in Lesson 07, not starting a new one.
