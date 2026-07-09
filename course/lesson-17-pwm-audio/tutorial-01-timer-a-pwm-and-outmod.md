# Tutorial 01 — Timer_A PWM and the OUTMOD Field

## Two independent Timer_A peripherals

Since Lesson 09, every timer register you've written has been `TACTL`,
`TACCR0`, `TACCTL1`, and so on — all part of one hardware block, sitting
at addresses `0x0160`–`0x0176`. That block is officially called
**Timer0_A3**: three capture/compare channels (CCR0, CCR1, CCR2), one
timer counter, one clock-source mux.

The MSP430G2553 has a *second*, completely independent copy of this same
hardware: **Timer1_A3**, at addresses `0x0180`–`0x0196` — the identical
register layout, offset by `0x20`. It isn't in `msp430g2553-defs.s` yet
(only Timer0_A3 is, since that's what Lessons 09–11 needed), so this
lesson's example defines the handful of Timer1_A3 registers it needs
locally, right in the `.s` file:

```asm
.equ    TA1CTL,    0x0180
.equ    TA1CCTL2,  0x0186
.equ    TA1CCR0,   0x0192
.equ    TA1CCR2,   0x0196
```

Why does this matter for audio? Because P2.4 — the pin wired to the LM386
— is physically connected to Timer1_A3's third channel (`TA1.2`), not
Timer0_A3's. You cannot rewire which timer drives which pin in software;
the connection is fixed in the chip's silicon. So generating a tone means
configuring *this specific* timer, and it runs entirely independently of
whatever tick/game-loop timer you already have running on Timer0_A3 —
neither one affects the other's timing.

## From "blink" to "tone": what actually changes

You already know Timer_A up mode: `TACCR0` holds the period, the counter
counts from 0 up to that value and resets, over and over, at a rate of
`SMCLK / (TACCR0 + 1)`. In Lesson 09 you used the CCR0-match *interrupt*
to fire code once per period. This lesson uses the same up-mode counting,
but instead of interrupting the CPU, a **second compare register** drives
a pin directly in hardware — no ISR involved at all.

A square wave audible as a musical tone needs exactly one HIGH-to-LOW-to-
HIGH cycle per period. One compare register alone (just CCR0) can only
give you a toggle *once per period* — half a cycle, which is a tone at
half the frequency you intended, and worse, it's not obviously a clean
50/50 duty cycle. You need a **second** register that fires partway
through the period, so the output can go one way at the start of the
period and the other way partway through.

## The OUTMOD field

Each capture/compare channel's control register (`TACCTL1`, `TACCTL2`)
has a 3-bit `OUTMOD` field controlling exactly how that channel drives its
output pin on a compare match. `msp430g2553-defs.s` already lists all
eight modes; the ones worth tracing through by hand:

- **`OUTMOD_3` (Set/Reset):** output is SET when the timer matches *this*
  channel's CCR, and RESET when it matches CCR0. This is the mode you'd
  reach for if this channel's CCR value marked the *start* of the pulse
  and CCR0 marked the period boundary that also ends it.
- **`OUTMOD_7` (Reset/Set):** the mirror image — output is RESET
  (driven low) when the timer matches *this* channel's CCR, and SET
  (driven high) when the timer matches CCR0 (which happens exactly once
  per period, right as the counter rolls over back to 0).

For a symmetric tone, `OUTMOD_7` on the compare channel wired to the
speaker pin is the standard choice: the pin goes HIGH at the top of every
period (CCR0 match/rollover) and LOW partway through (this channel's own
CCR match). Set that channel's compare value to **half** of CCR0, and you
get a clean 50% duty cycle — high for the first half of the period, low
for the second — repeating at exactly `SMCLK / (TACCR0 + 1)` Hz. One full
square-wave cycle per timer period, which is exactly the frequency you
computed.

```asm
mov.w   #TONE_PERIOD, &TA1CCR0         ; period -> sets frequency
mov.w   #(TONE_PERIOD/2), &TA1CCR2     ; halfway point -> 50% duty
mov.w   #OUTMOD_7, &TA1CCTL2           ; Reset/Set
mov.w   #(TASSEL_2|MC_1|TACLR), &TA1CTL ; SMCLK, up mode, start clean
```

Once `TA1CTL` is running and `P2SEL` routes the pin to the peripheral
(instead of plain GPIO), the pin toggles entirely in hardware, forever,
with the CPU free to do anything else — including sleep.
