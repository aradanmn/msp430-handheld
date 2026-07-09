# Lesson 06 Exercises

Both exercises build on `examples/button_poll.s`, which live-tracks S2's
level onto LED1. Neither exercise is about level-tracking anymore — both
switch to *toggle-on-press* (flip LED1 once per new press), which is the
behavior that actually exposes contact bounce.

## Exercise 1 — Bounce Demo (Explore)

`ex1/bounce_demo.s` gives you boilerplate plus P1 setup for BTN and LED1
already in place. Your job: make LED1 toggle once each time you detect a
**new** press of S2 (a transition from released to pressed) — not a level
mirror, an actual toggle.

Then use it. Press S2 slowly and normally, several separate times, and
watch LED1 closely.

**The point of this exercise is to observe the bounce artifact, not to fix
it.** Do not add any debounce logic here — that's what Exercise 2 and all
of Lesson 07 are for. If your toggle-on-press logic is correct and you
press enough times, you should eventually catch at least one press that
doesn't produce exactly one toggle.

**Success criteria:**
- LED1 toggles once per detected new-press transition (no level-mirroring
  logic left over from the example).
- You can articulate — to your instructor, or in writing — at least one
  specific instance where a single, clean physical press of S2 did **not**
  produce exactly one LED1 toggle (it toggled twice, or not at all).

Reference: SLAU144 Chapter 8 (Digital I/O).

## Exercise 2 — Design a Debounce (Challenge)

`ex2/design_a_debounce.s` starts from the same boilerplate and P1 setup as
Exercise 1. This time, the constraint is explicit: using only what you
already know — polling and delay loops, no timer peripheral, no interrupts
— make a single physical press of S2 toggle LED1 **exactly once**, and a
single physical release produce **no** extra toggle, even accounting for
the bounce behavior you observed in Exercise 1.

You are allowed to block — tie up the CPU while your program deals with
the button — and that tradeoff is intentional. Lesson 07 will come back and
replace whatever blocking technique you land on here with a non-blocking,
tick-based approach, so don't treat whatever you build today as the final
word. It just has to actually work, reliably, on real hardware.

**Success criteria:**
- 10 consecutive slow presses each produce exactly one toggle.
- 10 consecutive fast presses each still produce exactly one toggle per
  intended press — not zero, not two.
- A press-and-hold does not produce repeated toggles for as long as it's
  held (only the initial press counts).

Reference: SLAU144 Chapter 8 (Digital I/O).
