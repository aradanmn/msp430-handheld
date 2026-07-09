# Lesson 03 Exercises

Two exercises this lesson. Both build directly on `tutorial-01` (the
BIS/BIC/XOR masking rules) and `tutorial-02` (representing state as data).
There is no milestone exercise in Lesson 03 — the first handheld milestone
begins in Lesson 07.

## Ex1 — Counted Flash (Explore)

**File:** `ex1/counted_flash.s`

**Task:** Make LED1 flash exactly N times (you choose N — 5 is a
reasonable choice), then stop and stay off, for a single run with no
repeat and no button involved.

**Success criteria:**
- After the program starts, LED1 flashes exactly N times — no more, no
  fewer. Count them on the physical board.
- After the Nth flash, LED1 must stay OFF indefinitely. Watch it for at
  least 10 seconds after the last flash to confirm it does not flash
  again, drift into a dim/flicker state, or turn back on.
- The program does not require a button press, reset, or any other
  external input to run through its full sequence once, starting from
  power-on / flash.

Look up whatever you need from the MSP430x2xx User's Guide (SLAU144) Ch.
8 (Digital I/O) and from the L01–L02 material already covered. The starter
file has boilerplate and LED1's direction setup only.

## Ex2 — Dual Throb (Challenge)

**File:** `ex2/dual_throb.s`

**Task:** Make LED1 and LED2 each "throb" — a breathing-like rhythm that
gets brighter, then dimmer, then repeats — using only the on/off bit
idioms you have available right now: `bis.b`/`bic.b`/`xor.b` and delay
loops. You do not have PWM or a timer peripheral yet (Timer_A is Lesson
04) — everything has to come from turning pins fully on or fully off in a
pattern, and from timing loops.

The two LEDs must throb **out of phase** with each other: when one LED is
at (or near) its brightest point in the breathing cycle, the other should
be at (or near) its dimmest.

**Constraints:**
- No PWM peripheral, no Timer_A — on/off bit idioms and delay loops only.
- The two LEDs' brightness cycles must be offset from each other, not
  synchronized.
- Switching phase (i.e., the point where one LED's cycle wraps back to its
  starting brightness) must never produce a visible flicker glitch on
  either LED — no unexpected full-brightness flash or unexpected total
  blackout at the seam.

**Success criteria:**
- Watching the board, you can see each LED cycle from dim to bright and
  back, repeating continuously.
- At any moment you can tell the two LEDs are out of phase — they are not
  both bright or both dim at the same time.
- No visible glitch, flash, or dropout at the point where a cycle repeats.

The starter file has boilerplate and direction setup for LED1 and LED2
only. How you simulate "brightness" with an on/off pin is the design
problem this exercise is asking you to solve.
