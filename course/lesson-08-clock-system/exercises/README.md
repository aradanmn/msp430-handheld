# Lesson 08 Exercises

Three tiers: Explore (ex1), Challenge (ex2). Lesson 08 has no milestone —
the first Part II milestone is Lesson 09's `hal/timer.s`.

## Ex1 — Explore: 8 MHz Recalibration

**Directory:** `ex1/`

Calibrate the DCO to **8 MHz** instead of 1 MHz, and blink **LED1** at
**2 Hz** (on 250 ms / off 250 ms).

Everything you need is in Tutorial 08.1 (the calibration constant pairs) and
SLAU144 Ch. 5 (what `BCSCTL1`/`DCOCTL` actually do). The starter file gives
you the mandatory boilerplate (stack init, watchdog disable) and a vector
table skeleton — the calibration sequence, port setup, and delay loop are
yours to write.

Your delay constant(s) must be derived with `.equ` arithmetic from the
**8 MHz** frequency you calibrated to — don't copy the 1 MHz constant from
the lesson example and adjust it by trial and error.

**Success criteria:**
- [ ] DCO is calibrated using the 8 MHz Info Flash constants (not the 1 MHz
      ones)
- [ ] LED1 blinks at a rate you can count as "twice per second" over a
      10-second span (roughly 20 toggles)
- [ ] Every timing constant is a `.equ` expression that shows its derivation
      from `DCO_HZ = 8000000`, not a bare literal

## Ex2 — Challenge: Clock-Source Mixup

**Directory:** `ex2/`

`ex2/clock-mixup.s` is a complete, compiling program. Its header comment
states the *intended* behavior. Build it, flash it, and watch LED1.

**Observable failure:** the LED does not blink once per second. It blinks
noticeably faster — fast enough that you can tell at a glance it isn't 1 Hz,
without needing a stopwatch.

Your job: figure out *why*, in terms of the clock system concepts from this
lesson (not just "change this number until it looks right"). What
assumption does the delay-loop math make, and what does the code actually
configure? Fix it so LED1 genuinely blinks at 1 Hz.

This exercise will not tell you which register or line is involved — that's
the challenge. Use Tutorial 08.2's "what breaks when you don't" reasoning to
work backward from the observed rate to the mismatch.

**Success criteria:**
- [ ] I can state the actual observed blink rate (roughly) before making any
      changes
- [ ] I can explain in one sentence which clock assumption in the code
      doesn't match what's actually configured
- [ ] After my fix, LED1 blinks at a clean, stopwatch-verifiable 1 Hz
