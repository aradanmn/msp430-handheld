# Lesson 09 Exercises

Three tiers: Explore (ex1), Challenge (ex2), Milestone (ex3).

## Ex1 — Explore: Polling Blink

**Directory:** `ex1/`

Blink **LED2** (P1.6) at **4 Hz** (on 125 ms / off 125 ms) using Timer_A in
Up mode, polling `TAIFG` — no software delay loop anywhere in the file.

You choose the input divider and derive `TACCR0` yourself, from SMCLK
calibrated to 1 MHz (Lesson 08's standard calibration). Tutorial 09.1 works
a similar derivation for a 0.5 s period at a different divider — the
reasoning transfers, the numbers don't.

Remember P1.6 is shared with SPI MISO in later lessons — for this exercise
it's just LED2, configured the same way you configured LED1 in earlier
lessons.

**Success criteria:**
- [ ] LED2 blinks at a rate you can count as "four times per second" over a
      few seconds
- [ ] `TACCR0` and the divider are both named `.equ` constants whose values
      are derived from `SMCLK_HZ`, not hand-computed and pasted in as a bare
      number
- [ ] The file contains no software delay loop — timing comes entirely from
      Timer_A + `TAIFG` polling

## Ex2 — Challenge: Timing Analysis

**Directory:** `ex2/`

`ex2/timer-timing-bug.s` is a complete, compiling program. Its header
comment states the intended behavior. Build it, flash it, and watch LED1.

**Observable failure:** the blink rate is clearly not what the header
comment claims.

Your job: analyze the Timer_A configuration against the `.equ` constants
used to compute `TACCR0`, figure out where the mismatch is, and explain it
in terms of this lesson's material (clock source, divider, `TACCR0`
arithmetic) — not by changing numbers until the blink "looks about right."

**Success criteria:**
- [ ] I can state the actual observed blink rate (roughly) and the intended
      rate from the header comment
- [ ] I can point to the specific mismatch between what the `.equ` chain
      assumes and what `TACTL`/`TACCR0` actually configure
- [ ] After my fix, the LED blinks at the rate the header comment claims

## Ex3 — Milestone: `handheld/hal/timer.s` (polling)

**Directory:** `ex3/`

See `ex3/README.md` for the full behavioral spec. This is the first module
of the `handheld/` project you'll write — a polling-based periodic tick,
following the same `TAIFG`-polling idiom as this lesson's example, but
packaged as a reusable module per `handheld/registers.md`'s conventions.

`ex3/ex3.s` is an intentionally empty placeholder — the real work happens in
`handheld/hal/timer.s`, which you create from scratch.
