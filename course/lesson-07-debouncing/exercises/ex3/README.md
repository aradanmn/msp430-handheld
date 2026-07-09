# Ex3 — Milestone: `handheld/hal/input.s`

This is the first real milestone module in the handheld skeleton. You are
writing `handheld/hal/input.s` — a permanent piece of the project, not a
throwaway exercise file. `handheld/main.s` will `#include` it, the same way
it already includes `hal/leds.s`.

## Context

`handheld/registers.md` already documents the convention this module must
respect:

> **R5** — Input state (current button bitmap) — ISR — written by
> `input_read`, read by `game_update`
> **R6** — Previous input state (for edge detection) — ISR — updated each
> frame

That convention was written in anticipation of this exact milestone. Your
module's public function names must match it — the register roles for
R5/R6 are not something you're inventing; they're the project's existing,
documented contract.

There is no hardware timer or interrupt yet (that's Lessons 9–11). Your
module will be driven by a plain, repeated call from whatever fixed-period
polling loop the caller runs — call `input_read` once per "tick," where a
tick is one iteration of that loop, exactly like `examples/tick_debounce.s`
in this lesson.

## Public interface

### `input_init`

No arguments.

Configures BTN (P1.3) as an input with the internal pull-up enabled.
Initializes whatever internal state your debounce and edge-detection logic
needs so that the **very first call** to `input_read` behaves correctly —
it must not report a spurious press-edge on startup just because some
piece of internal state happened to start at zero.

### `input_read`

No arguments. No return value in R12 — this module reports its result in
R5 and R6, per the existing repo-wide register convention above (so it
composes with the rest of the handheld skeleton once the ISR exists in
Lesson 11).

Call once per tick. Each call:

- Samples the raw BTN pin.
- Advances your internal stable-count debounce state machine (tutorial-01)
  by exactly one tick's worth of work.
- Updates R5 and R6 so that, after the call returns:
  - **R5** holds the current debounced button state, expressed
    **active-HIGH**: 1 = pressed, 0 = released. The raw hardware signal is
    active-low (BTN reads 0 when pressed) — this module must invert that,
    so that no caller anywhere else in the codebase ever has to think about
    the hardware's polarity again.
  - **R6** holds whatever R5 held immediately before this call — i.e., the
    previous tick's debounced state.

## Debounce requirement

`input_read` must reject contact bounce the same way the tick-based,
stable-count technique from tutorial-01 does: a raw sample disagreeing with
the currently-accepted state for only a few ticks must not flip the
accepted state. The exact number of consecutive disagreeing ticks required
is your own design decision — inform it with what you observed in this
lesson's exercises, but there is no single "correct" number this spec is
checking for.

## Edge-detection requirement

A caller must be able to derive press-edge, release-edge, and held purely
from R5 and R6 using ordinary bitwise logic (tutorial-02) — you are not
required to add extra helper functions beyond `input_init` and
`input_read` for this, though you may add small private, `.L`-prefixed
helpers internally if it makes your implementation cleaner.

## How you'll know it works

- [ ] Wiring `input_init` plus a tick loop that calls `input_read` into a
      small test harness that toggles LED1 on a caller-derived press-edge
      behaves identically to your `ex1` edge-count demo — one clean toggle
      per physical press, no double-toggles from bounce.
- [ ] R5 and R6 correctly reflect **active-HIGH** pressed=1 / released=0,
      even though the raw hardware signal is active-low.
- [ ] `handheld/hal/input.s` assembles cleanly when `#include`d the same
      way `hal/leds.s` is.
- [ ] No leftover TODO comments in the version you consider done.

## Out of scope for this milestone

- Wiring `input_read` into an interrupt or a hardware timer tick — that's
  Lessons 9–11.
- Reading more than the single BTN pin — the 8-button shift register
  extension is Lesson 16.
