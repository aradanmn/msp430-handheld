# Lesson 17 — PWM & Tone Generation

## Topic

Your handheld has been silent since Lesson 01. This lesson adds the last
new peripheral before the game itself: **PWM (Pulse Width Modulation)**
tone generation, driving the LM386 amp and speaker added in Phase 4. A
square wave at a musical frequency, amplified and played through a
speaker, is a tone. Timer_A already gave you periodic ticks (Lesson 09);
this lesson uses that same hardware block in a different mode to generate
sound instead of interrupts.

The twist: the MSP430G2553 has **two independent Timer_A peripherals** —
Timer0_A3 (which you've been using since Lesson 09 for the game tick) and
Timer1_A3. The PWM output pin for this hardware, P2.4, is wired to
Timer1_A3's third compare channel (TA1.2) — a completely separate timer
from the one driving your game loop. Tone generation costs you no CPU
cycles and steals nothing from your tick timer once it's running: it's
pure hardware, ticking away in the background.

## Learning Objectives

- Configure Timer_A up-mode with a **second** compare register to produce
  a hardware square wave, with zero CPU involvement once started
- Understand the difference between the **period** register (CCR0 — sets
  frequency) and a **duty-cycle** register (CCR2 here — sets where within
  the period the output switches)
- Trace through `OUTMOD_7` (Reset/Set) and explain why it — not `OUTMOD_3`
  or `OUTMOD_4` — produces a clean, symmetric square wave locked to the
  period you set
- Compute a timer period from a target frequency using `.equ` arithmetic,
  entirely at assemble time (the MSP430G2553 has no hardware divider —
  you will never compute this at runtime)

## What You'll Build

An example that plays a fixed 440 Hz tone (concert-pitch A4) in a
repeating on/off pattern, audible through the speaker and visually
confirmed by LED1 blinking in sync with the tone.

## Game Connection

Lesson 18 builds a full sound-effect sequencer on top of what you build
here. This lesson's milestone — `handheld/hal/audio.s` — is the low-level
layer everything else calls into: "play this frequency for this long."

## Hardware

See [`wiring/phase-4-audio.md`](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/wiring/phase-4-audio.md) for the full circuit (LM386 wiring,
coupling capacitors, gain configuration). Summary:

| Signal | MSP430 Pin | Notes |
|---|---|---|
| PWM out | P2.4 | Timer1_A3, CCR2 (TA1.2) — square wave tone output |

The MSP430 drives a raw square wave; the 10µF input cap blocks DC before
the LM386, which amplifies ~20× and drives the speaker through a 250µF
output coupling cap.

## Datasheet References

- **SLAU144, Ch 12** — Timer_A: up mode, compare registers, output modes
  (`OUTMOD` field) — this is the whole lesson

## Success Criteria

- [ ] `examples/tone_play.s` builds and flashes without errors
- [ ] You hear a steady, on-pitch tone through the speaker in a clear
      on/off pattern, in sync with LED1
- [ ] You can explain why the period register alone (with no second
      compare register) is not enough to produce PWM — only a fixed
      once-per-period toggle
- [ ] You can compute, on paper, the `TACCR0` value needed for a given
      frequency at 1 MHz SMCLK, using only `.equ`-style integer arithmetic
