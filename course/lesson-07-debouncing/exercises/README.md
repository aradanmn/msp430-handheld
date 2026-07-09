# Lesson 07 Exercises — Debouncing & Edge Detection

## Ex1 — Explore: Edge-count demo

`ex1/edge_count_demo.s` gives you boilerplate plus port setup for BTN
(input, pull-up) and LED1 + LED2 (outputs) — the debounce and edge-detection
logic is entirely yours to design and build, using tutorial-01 and
tutorial-02 as your reference.

**Task:** count press-edges and display the count, mod 4, as a 2-bit binary
pattern across LED1 (bit 0) and LED2 (bit 1).

**Success criteria:**

- [ ] Each physical press advances the displayed pattern by exactly one
      step, in order (00 → 01 → 10 → 11 → 00 → ...).
- [ ] Across at least 10 test presses, contact bounce never advances the
      pattern by more than one step per physical press.
- [ ] Holding the button down does not continue to advance the pattern —
      only a fresh press does.

Look up: SLAU144 (MSP430x2xx Family User's Guide) Ch 8 — Digital I/O.

## Ex2 — Challenge: Debounce timing design

`ex2/debounce_timing_design.s` is a complete, working tick-based debounce +
press-edge detector, structurally the same as `examples/tick_debounce.s` —
it compiles, flashes, and toggles LED1 on press-edges.

**Stress test it against both of these cases:**

1. A single, ordinary physical press of S2 (press, hold briefly, release).
2. A deliberate **fast double-tap** — two separate, distinct presses of S2,
   both presses (and the release between them) completing within roughly
   150 ms of each other.

A single ordinary press must register as exactly **1** press-edge (one
LED1 toggle). A fast double-tap must register as exactly **2** press-edges
(two LED1 toggles). Test the provided starter against both cases and find
out which one it fails.

**Success criteria:**

- [ ] You can describe, from direct observation, which of the two stress
      cases above the starter fails.
- [ ] You can explain *why* that timing constant produces that specific
      failure, in terms of the state machine from tutorial-01.
- [ ] Your corrected version passes both stress cases.

## Ex3 — Milestone: `handheld/hal/input.s`

This lesson's milestone is a real module in the `handheld/` skeleton, not a
standalone exercise file. Full spec, public interface, and success criteria
are in `ex3/README.md` — read that before starting. `ex3/ex3.s` is an
intentionally empty stub; you build `handheld/hal/input.s` directly.
