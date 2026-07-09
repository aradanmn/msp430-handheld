# Lesson 10 Exercises

Two tiers: Explore (ex1), Challenge (ex2). Lesson 10 has no milestone — the
next Part II milestone is Lesson 11's ISR + LPM0 conversion.

## Ex1 — Explore: Convert to ISR

**Directory:** `ex1/`

`ex1/isr-convert.s` is a complete, working program: it blinks LED2 at 2 Hz
using Timer_A Up mode and `TAIFG` polling — the Lesson 09 style, exactly as
given.

Rewrite it so the same 2 Hz blink is driven **entirely by a Timer_A CC0
interrupt**, with no polling loop anywhere in `main`. You'll need to: enable
the compare interrupt, enable `GIE`, write the ISR, and place it correctly
in the vector table. Tutorial 10.1 covers exactly which register and vector
slot are involved; SLAU144 Ch. 1 and 12 fill in anything it doesn't.

**Success criteria:**
- [ ] LED2 still blinks at the same 2 Hz rate as the original polling
      version
- [ ] `main` contains no loop that reads `TAIFG` — the only thing left in
      `main` after setup is something that yields the CPU (a spin loop is
      fine; Lesson 11 replaces it with sleep)
- [ ] The ISR ends with `reti`, not `ret`
- [ ] The vector table places the ISR at the correct address for the
      interrupt source you used

## Ex2 — Challenge: ISR Timing Budget

**Directory:** `ex2/`

`ex2/isr-timing-budget.s` is a complete, compiling, interrupt-driven
program. Its header comment states the intended behavior. Build it, flash
it, and watch LED1 for at least 15–20 seconds.

**Observable failure:** the blink is not a clean, steady rhythm. Every so
often, there's a visible stutter — a beat that lands early, late, or
doubles up — breaking an otherwise steady beat.

Your job: figure out why, in terms of this lesson's material — what an ISR
is allowed to assume about how long it has before the next event, and what
happens when that assumption is violated. Compute (roughly) how much time
the ISR's most expensive path takes, compare it against the tick period, and
explain the mismatch.

This exercise will not tell you which branch or loop inside the ISR is
responsible — that's the analysis.

**Success criteria:**
- [ ] I can describe the observable stutter pattern I actually see (how
      often, what it looks like)
- [ ] I can estimate the cycle cost of the ISR's most expensive execution
      path and compare it to the tick period
- [ ] I can explain, using GIE and interrupt latency, why an occasional
      slow ISR produces a stutter rather than a uniformly slower blink
- [ ] After my fix, the blink is steady with no audible/visible stutter over
      at least 30 seconds of observation
