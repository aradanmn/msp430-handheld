# Tutorial 02 — Edge Detection

## From a level to an event

The stable-count debounce machine from Tutorial 01 gives you a clean
**level**: at any given tick, the accepted state says "pressed" or
"released," and you can trust it. But a game almost never wants to react
to a level directly. "LED1 is lit while the button is held" (Lesson 06's
`examples/button_poll.s`) is a level reaction. "Start the game the instant
the player presses the button" is not — it's a reaction to a **transition**,
a single instant in time, not a duration. That transition is called an
**edge**.

This is exactly the convention `handheld/registers.md` already documents
for this project: **R5** holds the current debounced input state, and
**R6** holds the previous tick's debounced input state. Every edge you care
about is derivable from comparing those two registers. (Ex3 only asks you
to define `hal/input.s`'s own public interface — it doesn't require you to
hardcode R5/R6 internally — but it's worth reading this section with that
convention in mind, since that's exactly the shape of state your module
will need to expose.)

## Three edges, one comparison

Given **current** debounced state and **previous** debounced state (both
single bits, 1 = pressed / 0 = released, sampled one tick apart):

| Name | Condition | Meaning |
|---|---|---|
| **Pressed edge** | was released last tick, is pressed this tick | the instant a press begins |
| **Released edge** | was pressed last tick, is released this tick | the instant a press ends |
| **Held** | pressed both this tick and last tick | continuing, not a new event |

All three fall out of two bitwise operations on current vs. previous:

- **`current XOR previous`** — 1 wherever the two disagree, i.e. *something
  changed this tick*. This is 0 for both "held pressed" and "held released"
  (no news), and 1 for either direction of transition.
- **`change AND current`** — of the bits that changed, keep only the ones
  where the *current* state is pressed. That isolates **pressed edge**
  specifically (a change that landed on "pressed").
- **`change AND previous`** (equivalently, `change AND NOT current`) —
  of the bits that changed, keep only the ones where the *previous* state
  was pressed. That isolates **released edge** (a change that left
  "pressed").
- **`current AND previous`** — both bits pressed, no XOR needed — that's
  **held**, directly.

You don't need to solve the actual instruction sequence here; the point is
to recognize that all three named events are just different bitwise
combinations of two ordinary state registers — no new hardware, no new
peripheral, just logic on values you already have.

## Worked trace

Take a short run of already-debounced levels (P = pressed, R = released),
one per tick, and derive the classification for each tick by comparing it
to the tick before:

| Tick | Current (debounced) | Previous (debounced) | Classification |
|---|---|---|---|
| 1 | R | R (assume prior idle) | idle (released, no change) |
| 2 | R | R | idle (released, no change) |
| 3 | P | R | **pressed edge** |
| 4 | P | P | held |
| 5 | P | P | held |
| 6 | R | P | **released edge** |
| 7 | R | R | idle (released, no change) |

Read it against the bitwise rules above: at tick 3, `current XOR previous`
= 1 (a change happened), and `current` = P, so the change lands on
"pressed" → pressed edge. At tick 6, `current XOR previous` = 1 again, but
now `previous` = P and `current` = R, so the change is leaving "pressed" →
released edge. Ticks 4 and 5 have no XOR at all (`current == previous`,
both pressed) — that's `current AND previous` = held. Exactly one pressed
edge and exactly one released edge come out of this whole six-press-tick
sequence, no matter how many ticks the button stays held in between — which
is exactly the property a game needs: "did the player just press it" fires
once, not once per tick the button happens to still be down.

## Where this is going

By the end of this lesson's milestone (ex3), `handheld/hal/input.s` will
expose exactly the current/previous debounced state a caller needs to
derive these edges — the actual event stream every later lesson's game
logic (piece drop, menu navigation, pause) will be built from.
