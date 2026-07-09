# Lesson 08 — Clock System (DCO / MCLK / SMCLK / ACLK)

## Topic

Every timing decision you've made so far — delay loops in Lesson 04, the
debounce window in Lesson 07 — has secretly depended on one fact: the CPU
clock runs at 1 MHz because you called `clr.b &DCOCTL` / `mov.b
&CALBC1_1MHZ, &BCSCTL1` / `mov.b &CALDCO_1MHZ, &DCOCTL` at the top of
`_start`. This lesson opens up what that calibration sequence actually does,
why the MSP430G2553 needs it at all, and how the chip distributes clock
signals to the CPU and its peripherals via three named clocks: **MCLK**,
**SMCLK**, and **ACLK**.

You will also recalibrate to 8 MHz and see exactly what has to change in
your code (and what doesn't) when the CPU gets 8x faster.

## Learning Objectives

By the end of this lesson you will be able to:

- Explain what the DCO is, why it's imprecise out of reset, and how the
  factory-programmed calibration bytes in Info Flash (0x10F8–0x10FF) fix that
- Calibrate the DCO to 1 MHz or 8 MHz using the correct `CALBC1_x`/`CALDCO_x`
  pair
- Name the three clock signals (MCLK, SMCLK, ACLK), what drives each by
  default, and which peripherals use which clock
- Compute a divided clock frequency from `BCSCTL1`/`BCSCTL2` divider bits
  using `.equ` arithmetic
- Explain what happens to a timing-dependent program (like a delay loop) when
  you change the DCO calibration without recalculating its constants

## What You'll Build

`examples/clock-blink.s` — LED1 blinking at exactly 1 Hz, but this time you
will trace through *why* it's exactly 1 Hz by relating the delay constant to
the calibrated clock frequency rather than just copying a known-good number.

`exercises/ex1` — the same blink, recalibrated to run the CPU at 8 MHz
instead, with a delay constant you derive yourself.

`exercises/ex2` — a debugging challenge: a program with a clock/timing
mismatch that produces a wrong, but very telling, blink rate.

There is no `handheld/` milestone this lesson — Lesson 08 is foundational.
The first Part II milestone is Lesson 09's `hal/timer.s`.

## Game Connection

Every peripheral in the finished handheld — Timer_A game ticks, the SPI bus
to the OLED, UART to your terminal, the ADC — is clocked by either MCLK or
SMCLK. Getting the clock system right here means every later lesson's timing
math (baud rates, tick periods, PWM frequencies) is built on solid ground.
Pick the wrong clock source for a peripheral and your Tetris pieces will
either crawl or teleport across the board.

## Datasheet Reference

- **SLAU144, Chapter 5** — Basic Clock Module+ (DCO, BCSCTL1/2/3, calibration
  constants)
- **SLAS735** — Info Flash memory map (0x1000–0x10FF) showing where the
  calibration bytes live

## Success Criteria

- [ ] I can state, from memory, the calibration sequence (`clr.b &DCOCTL` →
      `mov.b &CALBC1_x, &BCSCTL1` → `mov.b &CALDCO_x, &DCOCTL`) and explain
      why `DCOCTL` is cleared *first*
- [ ] I can explain the difference between MCLK, SMCLK, and ACLK in one
      sentence each
- [ ] `examples/clock-blink.s` blinks LED1 at 1 Hz (on 0.5 s / off 0.5 s,
      timeable with a stopwatch across ten cycles)
- [ ] I can derive a divided clock frequency (e.g. SMCLK/8) using `.equ`
      arithmetic without a calculator
- [ ] `exercises/ex1` blinks at the assigned rate at 8 MHz using a
      self-derived delay constant
- [ ] `exercises/ex2`: I can state the actual (wrong) blink rate I observe,
      and explain in one sentence which clock assumption doesn't match reality
