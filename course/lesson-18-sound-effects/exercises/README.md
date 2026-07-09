# Lesson 18 Exercises

## Exercise 1 (Explore) — Melody Sequencer

Write a standalone program (`ex1/melody_isr.s`) that plays a short melody
(at least 4 notes) from a table in Flash, but — unlike the lesson
example — drive it from a **Timer_A CC0 interrupt and LPM0**, not a
blocking busy-wait (you covered interrupts and low-power modes in Lessons
10–11). The main thread should be able to sleep between ticks while the
melody advances in the background.

Look up in SLAU144 Ch 12: nothing new here — this is the interrupt
pattern from Lesson 10–11 applied to note timing instead of game timing.

**Success criteria:**
- [ ] A recognizable short melody (4+ notes) plays via the speaker
- [ ] The CPU is in LPM0 between ticks, not busy-waiting
- [ ] The melody's tempo is steady from first note to last

## Exercise 2 (Challenge) — Tempo-Drift Bug

`ex2/tempo_drift.s` plays an 8-note repeating pattern through the speaker,
wired identically to the lesson example. Build and flash it.

**Observable failure:** each individual note sounds fine — right pitch,
nothing obviously broken — but the overall tempo is not steady. Time
several repeats of the 8-note pattern with a stopwatch: the measured
time is consistently, measurably shorter than the note durations in the
table would predict. The pattern doesn't get faster as it plays — it's
uniformly faster than intended from the very first repeat.

Find and fix the cause.

**Success criteria:**
- [ ] Timing several repeats of the pattern with a stopwatch matches the
      duration values in the table (within normal stopwatch measurement
      error)

## Exercise 3 (Milestone) — Extend `handheld/hal/audio.s` with a Sequencer

See `ex3/README.md` for the full spec. You are extending the module you
built in Lesson 17, not starting a new one.
