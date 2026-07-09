# Lesson 04 Exercises

## Ex1 — Explore: Calibrated Delay

**File:** `ex1/calibrated_delay.s`

Blink LED1 (P1.0) at as close to exactly **250 ms on / 250 ms off** as you
can, using cycle-counted `.equ` constants for your timing — not a
hand-guessed magic number.

Work out your delay constants the way tutorial-01 does: figure out roughly
how many cycles your loop body costs per iteration at 1 MHz, then derive
the iteration counts needed for a 250 ms half-period, and express that
derivation with `.equ` arithmetic rather than a bare literal.

Measure your result. Time a run of 20 full on/off blinks with a stopwatch
(20 × 500 ms = 10 seconds, if you're exactly on target) and compare against
the ideal. General CPU timing background is in SLAU144's instruction set
material if you need to double-check a cycle count.

**Success criteria:**

- [ ] `calibrated_delay.s` builds and flashes via `make flash`
- [ ] LED1 blinks continuously, on/off, at a rate you derived from `.equ`
      constants rather than trial-and-error literals
- [ ] Timing 20 full blink cycles with a stopwatch lands within a few
      percent of the 10-second ideal (250 ms on + 250 ms off, ×20)
- [ ] You can point at the specific `.equ` line(s) that encode your target
      duration and explain the arithmetic behind them

## Ex2 — Challenge: Flag-Clobber Bug Hunt

**File:** `ex2/flag_clobber_bug.s`

This program is supposed to light LED1 once a simulated press counter
reaches its target value, and keep LED1 dark before that. Build it, flash
it, and watch what actually happens.

**Observable symptom:** LED1 turns on almost immediately after power-up —
well before the counter could plausibly have reached its target — and then
stays lit continuously from that point on. It never behaves as "off, then
on only once a specific count is reached."

Figure out why. You have the full tutorial material on status flags from
this lesson to work with.

**Success criteria:**

- [ ] You can identify the specific instruction sequence responsible for
      the mismatch between "what the code appears to compare" and "what the
      branch actually reacts to"
- [ ] You can explain the bug in one or two sentences, referencing which
      flag is involved and why
- [ ] You have a fix that makes LED1 behave as originally intended (dark
      until the counter reaches its target, then lit) and you've verified
      it on hardware
