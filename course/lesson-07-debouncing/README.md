# Lesson 07 — Debouncing & Edge Detection

## Topic

Lesson 06 got you close enough to a real button to see the problem: a
mechanical switch doesn't transition cleanly. Its contacts physically
chatter — bounce — for a few milliseconds around every press and release,
and a fast enough polling loop will see that chatter as several transitions
instead of one. If Lesson 06's ex2 asked you to fix that with a blocking
delay (sample, then freeze the CPU for a calibrated number of milliseconds
before trusting the pin again), you already know the shape of the problem
even if your fix worked. That fix doesn't scale: the CPU sits frozen for
the entire settle window doing nothing else, and the "how long do I wait"
number is whatever delay-loop count you hand-tuned, not a value with any
clean meaning.

This lesson replaces that with a **non-blocking, tick-based** debounce: a
tiny state machine you drive once per periodic "tick" — for now, one
iteration of a calibrated delay loop; starting in Lesson 09 a real hardware
timer will generate that tick instead, without the debounce logic itself
changing at all. On top of the clean debounced signal that produces, you'll
learn to derive **press-edge**, **release-edge**, and **held** events —
the actual events a game reacts to, as opposed to a raw level.

## Learning Objectives

By the end of this lesson you will be able to:

- Explain why a blocking, delay-based debounce monopolizes the CPU and
  ties its timing to an arbitrary calibration constant, and why a
  tick-based debounce avoids both problems.
- Implement a stable-count debounce state machine: sample once per tick,
  count consecutive ticks where the raw sample disagrees with the
  currently-accepted debounced state, and only flip the accepted state once
  that count reaches a threshold.
- Hand-trace the state machine through a bouncy sample sequence and predict
  exactly when (and how many times) the accepted state changes.
- Derive press-edge, release-edge, and held events from the current and
  previous tick's debounced state using simple bitwise comparison.
- Build a real handheld module — `hal/input.s` — from a behavioural spec
  and a public interface, matching the register convention already
  documented in `handheld/registers.md`.

## What You'll Build

`examples/tick_debounce.s` is a complete, standalone demo: it samples S2
(BTN, P1.3) once per fixed-period tick, runs it through a stable-count
debounce state machine, detects the press edge, and toggles LED1 exactly
once per physical press — no matter how much the contact bounces.

The exercises push further. `ex1` asks you to build your own tick-debounce
and press-edge counter that displays a running count (mod 4) across LED1 +
LED2. `ex2` hands you a *working* debounce+edge-detector with a timing
constant tuned wrong for one particular case — your job is to find which
case, by testing against a stress scenario, not to be told where the bug
is.

`ex3` is this course's first **Milestone**: you will write
`handheld/hal/input.s` from a behavioural spec, producing the actual input
driver the handheld skeleton uses from here forward. This is not a
throwaway exercise file — it's real, permanent project code.

## Game Connection

Every button press in the final game — start, rotate, drop, pause — passes
through the module you build today. `handheld/registers.md` already
reserves R5 for "current debounced input state" and R6 for "previous input
state," written and read by exactly the kind of debounce + edge-detection
logic this lesson teaches — that convention was written in anticipation of
this milestone. Lesson 16 will extend `hal/input.s` to read eight buttons
through a shift register instead of one pin directly on P1.3, but the
debounce and edge-detection core you write here does not change — only the
sampling step does. Get this right now and you get it for free later.

## Success Criteria

- [ ] The tick-debounce example produces exactly one LED toggle per
      physical press, with zero double-toggles across at least 10 test
      presses, without ever blocking longer than one tick's worth of CPU
      time.
- [ ] Press-edge and release-edge are each detected exactly once per
      physical press/release cycle.
- [ ] You can hand-trace the stable-count state machine through a bouncy
      sample sequence and correctly predict when the accepted state flips.
- [ ] You can derive press-edge / release-edge / held from two ticks of
      debounced state using bitwise logic, without hint of pseudocode.
- [ ] `handheld/hal/input.s` compiles cleanly as part of a test harness and
      matches the ex3 spec's public interface exactly — `input_init`,
      `input_read` — with R5/R6 holding active-high current/previous state
      as specified.

See `course/common/glossary.md` for any unfamiliar acronym.
