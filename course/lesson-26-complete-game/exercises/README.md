# Lesson 26 Exercises

Read both tutorials first. Exercises 1 and 2 only need the onboard
LaunchPad — no new wiring. Attempt both before studying
`examples/flash_and_lpm3_demo.s`.

---

## Exercise 1 — Explore: LPM3 Wake on Button Press

**Directory:** `ex1/`

**File:** `ex1/lpm3_wake.s`

Configure `ACLK` to run from the internal VLO, enter LPM3, and wake the CPU
on a press of the onboard S2 button (P1.3) via a Port 1 interrupt. Toggle
LED1 once per wake, so the wake event is visible.

**What to look up:**
- SLAU144's Basic Clock System chapter for `BCSCTL3`'s `LFXT1S` field and
  what selects the VLO as `ACLK`'s source
- `LPM3_bits` is already defined in `msp430g2553-defs.s` (Lesson 11) — no
  need to derive the SR bit combination yourself, just use it
- Port 1 interrupt configuration (edge select, enable, flag) is the same
  mechanism you've used for button input since earlier lessons — nothing
  about *how* a Port 1 interrupt is configured is new here, only that it's
  now the wake source for a low-power mode instead of a polled input

**Success criteria:**
- [ ] `BCSCTL3` is configured so `ACLK` runs from VLO before LPM3 is entered
- [ ] The CPU is asleep in LPM3 (not spinning in a polling loop) between
      button presses
- [ ] LED1 toggles exactly once per button press, reliably, across several
      presses in a row

---

## Exercise 2 — Challenge: Wakes Up Wrong

**Directory:** `ex2/`

**File:** `ex2/lpm3_wake_bug.s`

This file configures `ACLK` from VLO, enters LPM3, and wakes on an S2
button press — the same behavior as Exercise 1. Build it, flash it, and
try it.

**Observable failure:** the very first wake, right after power-up, works
exactly as expected — LED1 toggles once, cleanly, for that first press. It's
what happens *after* that first cycle that's wrong: going back to sleep and
pressing the button again doesn't reliably reproduce the same behavior.
Sometimes the board appears to wake up on its own, with no press at all.
Sometimes a real, deliberate press doesn't seem to register.

Your job: figure out what's different about how this file returns to LPM3
after a wake, compared to a wake/sleep cycle that behaves consistently
every time.

**Success criteria:**
- [ ] I can describe exactly what I observed on the first wake versus
      subsequent wakes
- [ ] I can point to the specific place in the code where the state left
      behind by one wake affects whether the next sleep/wake cycle behaves
      correctly
- [ ] After my fix, LED1 toggles exactly once per button press, indefinitely,
      with no spurious wakes and no missed presses

---

## Exercise 3 — Milestone (Capstone): Final Polish

**Directory:** `ex3/`

**What to change:** multiple existing files across `handheld/` —
`main.s`, your board/collision module from Lessons 19–21, `hal/timer.s`,
and a new Flash-backed high score. This is not a single new module; it's
the integration pass that turns the working game engine into the finished,
playable handheld.

See `ex3/README.md` for the full spec. This is the last exercise in the
course.

**Build & test:** `cd handheld && make && make flash`

**Success criteria:** compiles cleanly as part of the handheld build; a
title screen appears at boot, a game over is clearly and visibly signaled
when a piece can't spawn, a pause toggle freezes and resumes play without
losing board state, a high score persists in Info Flash Segment D across a
power cycle, and the game sleeps in LPM3 between ticks.
