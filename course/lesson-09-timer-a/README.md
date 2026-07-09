# Lesson 09 — Timer_A Up-Mode & Polling

## Topic

Every delay so far has been a software loop: the CPU counts down a register
and does nothing else while it waits. That works, but it wastes CPU cycles,
it's brittle (Lesson 08 showed how easily a delay constant goes stale when
the clock changes), and it can't run "in the background" while other code
executes. **Timer_A** is a hardware peripheral built for exactly this job:
count clock cycles independently of the CPU, and raise a flag (or, from
Lesson 10 onward, an interrupt) when a target count is reached.

This lesson covers Timer_A's four modes, focuses on **Up mode** (the one
you'll use for the rest of the course), and builds a periodic "tick" by
polling `TAIFG` — still busy-waiting, but now waiting on a *hardware
clock* instead of counting instructions. This is also this Part's first
milestone: you'll write the polling version of `handheld/hal/timer.s`.

## Learning Objectives

By the end of this lesson you will be able to:

- Name Timer_A's four modes (Stop, Up, Continuous, Up/Down) and explain what
  each one counts to and what happens at the top of the count
- Explain the relationship between `TACCR0` and the timer's period in Up
  mode
- Compute a `TACCR0` value for a target period from a clock frequency and an
  input divider, using `.equ` arithmetic
- Build a polling loop that waits for `TAIFG` and clears it correctly
- Explain why a hardware timer tick is more precise and more flexible than a
  cycle-counted software delay loop

## What You'll Build

`examples/timer-blink.s` — LED1 blinking at exactly 1 Hz, timed by Timer_A
in Up mode instead of a software delay loop.

`exercises/ex1` — a different target frequency, different divider, derived
from scratch.

`exercises/ex2` — a timing-analysis challenge: a program whose observed
blink rate doesn't match its intended rate.

`exercises/ex3` (**Milestone**) — `handheld/hal/timer.s`, the polling-tick
module the rest of the handheld project's timing will build on. See
`exercises/ex3/README.md` for the spec.

## Game Connection

Tetris gravity — a piece dropping one row every N ticks — is *the* defining
timing behavior of the game, and it's driven by exactly this mechanism: a
periodic Timer_A tick that the game loop counts. Everything from here to
Lesson 26 assumes a reliable, precisely-clocked tick source. This lesson (and
its Lesson 11 upgrade to interrupt-driven + low-power) is where that tick is
born.

## Datasheet Reference

- **SLAU144, Chapter 12** — Timer_A (modes, `TACTL`, `TACCRx`, `TACCTLx`)

## Success Criteria

- [ ] I can name all four Timer_A modes and state what "top of the count" is
      in Up mode vs. Continuous mode
- [ ] I can compute `TACCR0` for a target period given a clock frequency and
      an input divider, entirely with `.equ` arithmetic
- [ ] `examples/timer-blink.s` blinks LED1 at a clean, stopwatch-verifiable
      1 Hz using Timer_A Up mode + `TAIFG` polling — no software delay loop
      anywhere in the file
- [ ] `exercises/ex1` blinks at its assigned rate using a divider and
      `TACCR0` value I derived myself
- [ ] `exercises/ex2`: I can state the actual observed rate and explain,
      in terms of Timer_A's configuration, why it doesn't match the intended
      rate
- [ ] `exercises/ex3`: `handheld/hal/timer.s` exists, builds cleanly as part
      of `handheld/`, and meets the behavioral spec in `exercises/ex3/README.md`
