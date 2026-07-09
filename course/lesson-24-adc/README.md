# Lesson 24 — ADC10

## Topic

Every input this course has used so far has been digital: a button is
either pressed or not, a pin is either HIGH or LOW. The real world is
mostly analog — temperatures, potentiometer positions, light levels — and
the MSP430G2553's **ADC10** (a 10-bit analog-to-digital converter) is the
bridge between that continuous world and the discrete numbers your code
already knows how to work with.

This lesson covers two ADC10 sources side by side: the chip's **internal
temperature sensor** (channel 10, needing a precise internal reference
voltage) and an **external potentiometer** wired to P1.4 (channel 4,
needing only the supply rail as reference). They look almost identical in
code, but the differences between them — which reference voltage each one
needs, and why — are the actual content of this lesson. There's also a real
gap to fill: `msp430g2553-defs.s` only defines the channel constant for the
temperature sensor (`INCH_10`). Reading the potentiometer means deriving
its channel constant (`INCH_4`) yourself from the `INCH` bit-field
documented in that same file.

## Learning Objectives

By the end of this lesson you will be able to:

- Configure ADC10 to read the internal temperature sensor, reusing the
  exact register sequence from earlier lessons' reference material
- Explain what `ADC10CTL1`'s `INCH` field is (bits 15-12) and derive the
  channel constant for a pin that doesn't already have one defined
- Explain the difference between `SREF_1|REFON` (internal reference,
  needed for the temperature sensor) and `SREF_0` (VCC/GND as reference,
  needed for a potentiometer that spans the full supply rail) — and why
  each sensor needs the reference it needs
- Explain why `ADC10AE0` — not `P1SEL`/`P1SEL2` — is the register that
  hands a P1 pin over to the ADC
- Convert a raw 10-bit ADC result into a usable value: °C for the
  temperature sensor, and a small number of discrete steps for the
  potentiometer

## What You'll Build

`examples/adc_temp_demo.s` — reads the internal temperature sensor
repeatedly, converts each reading to °C, and blinks LED1 a number of times
that reflects the reading, pausing between readings.

`exercises/ex1` — the parallel potentiometer version: read P1.4, map the
10-bit result to an LED1 blink rate, built by you from the tutorials and
SLAU144.

`exercises/ex2` — a working ADC program with a real, reproducible
first-reading problem. Find it and fix it.

`exercises/ex3` (**Milestone — integration, no new file**) — wire one of
this lesson's two ADC sources into an existing game parameter from an
earlier milestone. See `exercises/ex3/README.md` for the spec.

## Game Connection

The potentiometer is an alternate control input — a natural fit for
setting the game's starting drop speed before a round begins, without
needing a button-mashing menu. The temperature sensor doesn't affect
gameplay directly, but it's a convenient diagnostic value: something real
and easily verified by hand (compare it to room temperature) to sanity
check the ADC and UART paths are both working correctly together, using
last lesson's `ui_send_score`-style transmission to report it.

## Datasheet Reference

- **SLAU144, Chapter 22** — ADC10 (`ADC10CTL0`/`ADC10CTL1`, `SREF`
  reference selection, `ADC10AE0`, sample-and-hold timing)

## Success Criteria

- [ ] I can configure ADC10 to read the internal temperature sensor from
      memory (or from the tutorial), including the settle delay after
      turning on the reference
- [ ] I can state the `INCH` field's bit position (bits 15-12) and derive
      the correct value for channel 4 without it being given to me
- [ ] I can explain why the temperature sensor needs `REFON`/`SREF_1` but
      the potentiometer only needs `SREF_0`
- [ ] I can explain why `ADC10AE0`, not `P1SEL`, is what routes a pin to
      the ADC
- [ ] `examples/adc_temp_demo.s` builds, flashes, and blinks LED1 a count
      that visibly tracks the room's actual temperature
- [ ] `exercises/ex1`, `ex2`, and `ex3` each meet their own success criteria
      (see `exercises/README.md` and `exercises/ex3/README.md`)
