# Exercise 3 — Milestone: `handheld/hal/timer.s` → CC0 ISR + LPM0

This converts the polling tick you built in Lesson 09 into the
interrupt-driven, low-power design the rest of the handheld project runs
on, and adds the game-loop shell to `handheld/main.s` that every later
lesson's module will call into.

Follow the composition model and conventions already established for the
project:

- `handheld/main.s` pulls this module in with `#include "hal/timer.s"`
  (see CLAUDE.md's "Handheld Skeleton — Composition Model")
- The ISR's public label is `timer_isr` (CLAUDE.md names this exact
  convention); other public labels stay prefixed `timer_`, local labels use
  the `.L` prefix
- Register usage follows `handheld/registers.md` — note that it already
  assigns R4 the role "frame/tick counter, ISR-persistent"

## Behavioral Spec

Replace your Lesson 09 polling implementation with:

- **`timer_init`** — no arguments, no return value. Called once from
  `main.s`'s init sequence, after the existing LED init calls. Configures
  Timer_A CC0 for a periodic tick of **5 ms** and enables the CC0 compare
  interrupt (`CCIE`). Does **not** itself enter LPM0 — that happens in
  `main.s`.

- **`timer_isr`** — the CC0 interrupt service routine. Runs once per 5 ms
  tick. Must exit via `reti` (not `ret`). Whether it uses the plain-`reti`
  pattern or the explicit-`CPUOFF`-clear pattern (Tutorial 11.1) is your
  design decision, based on where you decide the tick's per-frame work
  belongs.

- **`handheld/main.s`** — after calling `timer_init`, the init sequence must
  enter LPM0 (`bis.w #(GIE|CPUOFF), SR`) instead of the old `halt: jmp halt`
  spin loop. There must be no polling loop anywhere in `main.s` — all
  per-tick behavior is driven by `timer_isr` firing.

- **Observable behavior:** something must visibly happen on hardware at a
  timeable rate driven by the 5 ms tick — for example, toggling LED1 every
  100 ticks (0.5 s). The exact mechanism (what toggles, how often, whether
  the counting happens inside `timer_isr` or in main-line code woken by it)
  is your design choice.

## Success Criteria

- [ ] `handheld/hal/timer.s` no longer contains a polling loop — Timer_A's
      CC0 interrupt drives all per-tick behavior
- [ ] `handheld/main.s` enters LPM0 via `bis.w #(GIE|CPUOFF), SR`; no
      `halt: jmp halt`-style spin loop remains
- [ ] `cd handheld && make flash` builds and flashes cleanly
- [ ] A visible LED behavior driven by the tick is timeable against a
      stopwatch and matches the expected rate for a 5 ms tick, ±a few
      percent
- [ ] The ISR ends with `reti`
- [ ] No leftover TODO comments in the submitted module or `main.s` changes
