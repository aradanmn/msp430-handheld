# Lesson 26 — Complete Game + Polish

## Topic

Every lesson since Lesson 07 has added one working piece of the handheld:
input, timing, the display pipeline, audio, the game rules, SRAM. This
lesson doesn't add a new peripheral — it's the lesson where all of that
becomes an actual *game* instead of a collection of working modules. A
player needs a title screen to start from, a clear and unambiguous "you
lost" moment, a way to pause without losing progress, a high score that
survives a power cycle, and a device that doesn't drain its battery sitting
idle between ticks. This is the ship-it lesson.

Two genuinely new pieces of MSP430 knowledge get introduced along the way,
both covered in Tutorial 2: writing to the Info Flash Memory segment that
holds a persistent high score (the MSP430x2xx Flash Controller — SLAU144
Chapter 5, which this course hasn't touched before now), and entering LPM3
instead of LPM0 between ticks by sourcing `ACLK` from the internal VLO
(there's no crystal on this board to give `ACLK` a real 32 kHz source).
Everything else in this lesson is **structure** — how the pieces you
already built compose into a game with a beginning, middle, and end.

## Learning Objectives

By the end of this lesson you will be able to:

- Describe a top-level game state machine (title → playing → paused ↔
  playing → game over → title) and explain how a single "current mode"
  value gates which input/update/render logic runs each tick
- Explain the MSP430 Flash Controller's unlock → erase/write → lock
  sequence (`FCTL1`/`FCTL2`/`FCTL3`, the `FWKEY` password) at a conceptual
  level, and why Info Flash Segment A must never be erased or written by
  this project
- Explain the difference between LPM0 (CPU off, clocks running) and LPM3
  (CPU + DCO + SMCLK off, only ACLK running), and why a tick-driven game
  that doesn't need SMCLK between ticks can sleep in LPM3 instead
- Configure `ACLK` to run from the internal VLO instead of an (absent)
  32 kHz crystal, using `BCSCTL3`'s `LFXT1S` field

## What You'll Build

`examples/flash_and_lpm3_demo.s` — reads one byte from Info Flash Segment D
at boot (an ordinary read — no unlock sequence needed) and reflects it as an
LED1 blink count, then configures `ACLK` from VLO, enters LPM3, and wakes on
a button press (toggling LED1 once per wake). This example never erases or
writes flash — that risk is deliberately left to the milestone.

`exercises/ex1` — LPM3 entry/exit on your own, sourced from VLO, waking on
the onboard button.

`exercises/ex2` — a working LPM3 wake-on-button demo whose wake behavior
goes wrong the *second* time you try it, not the first.

`exercises/ex3` (**Milestone, capstone**) — the final polish pass across
`handheld/`: title screen, game over state + indication, pause toggle,
Info-Flash-backed high score, and LPM3 between ticks. See
`exercises/ex3/README.md`. This is the last exercise of the whole course —
after it, the handheld is a complete, playable Tetris.

## Game Connection

This is it — the lesson where the project stops being "a handheld that can
run Tetris logic" and becomes "a handheld Tetris game" a player could
actually pick up, play, lose, and try again, on battery power, for however
long the LiPo lasts.

## Datasheet Reference

- **SLAU144, Chapter 5** — Flash Memory Controller (`FCTL1`/`FCTL2`/`FCTL3`,
  the unlock/erase/write sequence, Info Flash segmentation)
- **SLAU144's Basic Clock System chapter** — `BCSCTL3`'s `LFXT1S` field,
  the internal VLO as an `ACLK` source with no crystal populated

## Safety Note — Read Before Touching Flash

Info Flash is only 256 bytes (`0x1000`–`0x10FF`), split into four 64-byte
segments. The **top** segment, conventionally called Segment A
(`0x10C0`–`0x10FF`), holds the DCO calibration constants
(`CALBC1_1MHZ`/`CALDCO_1MHZ`/etc.) that **every single lesson in this
course** depends on in its `_start` sequence, including this one. Erasing
Segment A destroys those constants permanently — there's no software way to
recover a factory calibration that's been erased.

**This lesson's persistent high score lives in Segment D
(`0x1000`–`0x103F`) — the lowest segment, and the one furthest from the
calibration data.** Never erase or write any address at or above `0x10C0`.
The example in this lesson only *reads* flash (which needs no unlock
sequence and carries none of this risk); the milestone is where you'll
implement the actual erase/write sequence, and the spec for it repeats this
constraint.

## Read First

1. `tutorial-01-game-state-machine.md` — the title/playing/paused/game-over
   state machine and how "current mode" gates per-tick logic
2. `tutorial-02-flash-persistence-and-lpm3.md` — the Flash Controller
   unlock/erase/write sequence (Segment D only), and configuring `ACLK`
   from VLO for LPM3

## Then

Attempt the exercises before studying
`examples/flash_and_lpm3_demo.s` — it's the reference, not the starting
point.

## Exercises

See `exercises/README.md`.

## Success Criteria

- [ ] I can describe the top-level game state machine and which existing
      module/function each transition hooks into
- [ ] I can describe the Flash Controller's unlock → erase/write → lock
      sequence conceptually, including why `FWKEY` is required on every
      write to `FCTL1`/`FCTL2`/`FCTL3`
- [ ] I can state, without hesitation, which Info Flash segment this
      project's high score lives in and which segment must never be
      touched
- [ ] I can explain the difference between LPM0 and LPM3 in terms of which
      clocks stay running, and why this project's tick timer needs to move
      to `ACLK`/VLO before LPM3 will actually let it wake on schedule
- [ ] `examples/flash_and_lpm3_demo.s` builds, flashes, reflects an Info
      Flash byte via an LED1 blink count at boot, and reliably wakes from
      LPM3 on a button press
- [ ] `exercises/ex3`: the final `handheld/` build has a title screen, a
      game-over state with a visible indication, a pause toggle, a
      Flash-persisted high score, and enters LPM3 between ticks
