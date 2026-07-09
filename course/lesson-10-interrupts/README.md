# Lesson 10 — Interrupts & ISRs

## Topic

Lesson 09's polling loop worked, but it cost the CPU 100% of its attention —
spinning in `.Lloop`, testing `TAIFG` over and over, unable to do anything
else. An **interrupt** lets a peripheral event (like a Timer_A compare
match) redirect the CPU to a small routine — the **Interrupt Service
Routine (ISR)** — automatically, the instant it happens, without the CPU
having to ask. This lesson covers the mechanics: the vector table, how the
CPU enters and exits an ISR, the global interrupt-enable bit (`GIE`), and
the difference between `reti` and `ret`.

There is no `handheld/` milestone this lesson — you'll apply interrupts to
the tick module itself in Lesson 11, once low-power modes give the CPU
somewhere useful to be while it waits.

## Learning Objectives

By the end of this lesson you will be able to:

- Explain, in order, what the CPU hardware does automatically when an
  enabled, pending interrupt fires (push PC, push SR, clear GIE, fetch
  vector, jump)
- Write a correctly-structured interrupt vector table entry for a specific
  peripheral interrupt
- Explain why `GIE` must be set globally *and* the peripheral's own
  interrupt-enable bit (e.g. `CCIE`) must be set, for an interrupt to fire
- Explain the difference between `reti` and `ret`, and why an ISR must end
  with `reti`
- Reason about interrupt latency and priority, and diagnose what happens
  when an ISR takes longer to execute than the period of the event
  triggering it

## What You'll Build

`examples/timer-cc0-isr.s` — the same 1 Hz LED1 blink from Lesson 09,
rebuilt as interrupt-driven: Timer_A's CC0 interrupt fires every 0.5 s and
an ISR toggles the LED, while the main loop is free to do nothing at all
(spin) — Lesson 11 replaces that spin with true sleep.

`exercises/ex1` — convert a polling blink to an interrupt-driven one
yourself, vector table and all.

`exercises/ex2` — an ISR timing-budget challenge: an ISR that occasionally
takes too long, and the visible consequence of that.

## Game Connection

The finished handheld uses interrupts for both of its most time-critical
jobs at once: the game tick (Timer_A CC0) and button input (Port 1). Both
need to fire promptly and return quickly, or the other starves. Getting
comfortable with ISR mechanics and their cost here is what makes that
combination tractable later.

## Datasheet Reference

- **SLAU144, Chapter 1** — Interrupt handling, vector priority, `GIE`
- **SLAU144, Chapter 12** — Timer_A interrupt behavior (`CCIE`, `CCIFG`,
  `TAIV`)

## Success Criteria

- [ ] I can list, in order, the steps the CPU hardware takes when a pending,
      enabled interrupt fires
- [ ] I can explain why an interrupt with `CCIE` set but `GIE` clear never
      fires, even though its flag (`CCIFG`) still sets
- [ ] `examples/timer-cc0-isr.s` blinks LED1 at 1 Hz using only an ISR — no
      polling loop anywhere in `main`
- [ ] I can explain, precisely, what `reti` restores that `ret` does not
- [ ] `exercises/ex1` converts a polling design to interrupt-driven and
      blinks correctly
- [ ] `exercises/ex2`: I can state the observable symptom of the ISR
      overrunning its budget and explain why it happens in terms of GIE and
      interrupt latency
