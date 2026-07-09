# Lesson 11 — Low-Power Modes & the Game Loop

## Topic

Lesson 10's `.Lspin: jmp .Lspin` main loop is honest about what it's doing —
nothing — but it's still burning full power the entire time, fetching and
executing a jump instruction over and over, waiting for the next interrupt.
The MSP430 can do better: **CPUOFF**, a bit in the status register, actually
halts instruction execution while leaving peripherals (and interrupts)
running. Combined with an interrupt, this gives you a CPU that spends nearly
all of its time asleep and only wakes for the instant it takes to service a
tick — the exact shape of a real game loop's power profile.

This lesson is also this Part's second and final milestone: you'll convert
`handheld/hal/timer.s` from Lesson 09's polling design to an interrupt +
low-power design, and add the game-loop shell to `handheld/main.s` that
every future lesson's module will hook into.

## Learning Objectives

By the end of this lesson you will be able to:

- Explain what `CPUOFF` does, and how it differs from "the CPU is still
  running, just executing a jump forever"
- Name LPM0 through LPM4 by which bits they set and (at a level of "what
  category of thing turns off") what stops in each
- Enter LPM0 correctly, atomically enabling interrupts and halting in one
  instruction: `bis.w #(GIE|CPUOFF), SR`
- Explain the difference between an ISR that exits via plain `reti` (CPU
  automatically returns to the same low-power state it was in) and one that
  clears `CPUOFF` in the saved `SR` first (CPU stays awake after the ISR
  returns) — and choose correctly between them for a given situation
- Build a periodic "heartbeat" — a tick that mostly sleeps and only spends
  CPU time doing real work

## What You'll Build

`examples/lpm0-heartbeat.s` — the reference low-power pattern this course
uses everywhere from here on: a Timer_A CC0 ISR decrements a countdown
register and toggles LED1 when it hits zero, while the CPU sleeps in LPM0
between ticks via `reti`'s automatic restore of the sleeping `SR`.

`exercises/ex1` — build your own LPM0 heartbeat at a different rate, and (if
you have a multimeter) observe the actual current draw difference between
sleeping and spinning.

`exercises/ex2` — an auto-wake design problem: a given program that never
actually rests in LPM0, and why that's observable even without a meter.

`exercises/ex3` (**Milestone**) — convert `handheld/hal/timer.s` to
interrupt-driven + LPM0, and add the game-loop shell to `handheld/main.s`
that every later lesson's module builds on. See `exercises/ex3/README.md`.

## Game Connection

This is the shell the entire rest of the platform runs inside: init once,
sleep, wake on tick, do one frame's worth of work, sleep again. Every future
`hal/`, `gfx/`, and `game/` module assumes this shape already exists in
`main.s` — this lesson is where it's built.

## Datasheet Reference

- **SLAU144, Chapter 1** — Low-power modes (LPM0–LPM4), the `SR` bits that
  control them

## Success Criteria

- [ ] I can state which `SR` bits combine to form LPM0, and in one sentence
      what stays running vs. what stops
- [ ] I can explain, precisely, the difference between exiting an ISR with
      plain `reti` vs. `bic.w #CPUOFF, 0(SP)` before `reti`, and when each is
      correct
- [ ] `examples/lpm0-heartbeat.s` blinks LED1 at 1 Hz while the CPU spends
      the overwhelming majority of its time in LPM0 (no spin loop doing
      real work between ticks)
- [ ] `exercises/ex1` builds its own heartbeat at an assigned rate using the
      same idiom
- [ ] `exercises/ex2`: I can state the observable symptom that reveals the
      CPU isn't actually resting, and explain the design fix in terms of
      when `CPUOFF` should (and shouldn't) be cleared
- [ ] `exercises/ex3`: `handheld/hal/timer.s` is interrupt-driven with LPM0
      entry, `handheld/main.s` has a working game-loop shell, and
      `cd handheld && make flash` builds and runs correctly
