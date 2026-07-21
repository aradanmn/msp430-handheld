# Lesson 17 Exercises

## Exercise 1 (Explore) — Single Tone

Wire up the LM386 amp and speaker per [`wiring/phase-4-audio.md`](https://github.com/aradanmn/Handheld-MSP430/blob/main/wiring/phase-4-audio.md)
and write a standalone program (`ex1/single_tone.s`) that plays one fixed,
continuous tone through the speaker (your choice of pitch) while LED1
stays lit the whole time.

Look up in SLAU144 Ch 12: Timer_A up mode, the `OUTMOD` field for compare
output channels, and how a second compare register produces a duty cycle
within a period set by the first.

**Success criteria:**
- [ ] A steady, single, on-pitch tone plays continuously through the
      speaker (verify against a tuner or frequency-counter app, or by ear
      against a known reference tone)
- [ ] LED1 is lit for as long as the tone plays

## Exercise 2 (Challenge) — Duty-Cycle Puzzle

`ex2/duty_puzzle.s` is wired identically to the lesson example. Build and
flash it.

**Observable failure:** LED1 blinks on schedule exactly like the working
example — the on/off cadence and timing look completely normal — but no
sound comes out of the speaker at all, on either half of the cycle.

Find and fix the cause. The timer is running; the pin is attached at the
right times; something about how the *duty cycle* is set up is wrong.

**Success criteria:**
- [ ] An audible tone plays during the "on" phase of the cadence, with
      LED1's blink pattern unchanged

## Exercise 3 (Milestone) — Create `handheld/hal/audio.s`

See `ex3/README.md` for the full spec.
