# Exercise 3 — Milestone: `handheld/hal/timer.s` (polling)

This is the first module of the `handheld/` project. It becomes the tick
source every later lesson's timing depends on — Tetris gravity, debounce
windows, PWM tone durations, all of it eventually trace back to this tick.

Follow the composition model and conventions already established for the
project:

- `handheld/main.s` pulls this module in with `#include "hal/timer.s"`
  (see CLAUDE.md's "Handheld Skeleton — Composition Model")
- Public labels are prefixed `timer_`; local labels use the `.L` prefix
  (see CLAUDE.md's "Assembly File Conventions")
- Register usage follows `handheld/registers.md`

## Behavioral Spec

Write `handheld/hal/timer.s` with exactly two public entry points:

- **`timer_init`** — no arguments, no return value. Call once from
  `main.s`'s init sequence, after the standard watchdog-disable + DCO
  calibration sequence already in `main.s`. Configures Timer_A (Up mode,
  SMCLK source, calibrated to 1 MHz) to produce a periodic tick of exactly
  **5 ms**, and leaves the timer running continuously.

- **`timer_wait_tick`** — no arguments, no return value. Blocks the caller
  (via polling — this lesson's `TAIFG` idiom, not interrupts) until the next
  5 ms tick boundary, then returns. Two consecutive calls to
  `timer_wait_tick`, with negligible code between them, must be separated by
  very close to 5 ms of real time.

## Integrating into `main.s`

Update `handheld/main.s` to:
1. `#include "hal/timer.s"`
2. Call `timer_init` once during startup (after the existing LED init calls)
3. Call `timer_wait_tick` in a loop, and use it to drive some visible,
   timeable behavior of your choosing — for example, toggling LED1 every 100
   calls (0.5 s at a 5 ms tick). The exact mechanism is up to you; the
   requirement is that the tick's correctness is observable on hardware, not
   just "it compiles."

## Success Criteria

- [ ] `handheld/hal/timer.s` exists and is included from `main.s`
- [ ] `cd handheld && make flash` builds and flashes cleanly
- [ ] A visible LED behavior driven by `timer_wait_tick` is timeable against
      a stopwatch and matches the 5 ms tick period (e.g., a 0.5 s toggle
      period, ±a few percent)
- [ ] No software delay loop is used anywhere in `hal/timer.s` — all timing
      comes from Timer_A
- [ ] No leftover TODO comments in the submitted module
