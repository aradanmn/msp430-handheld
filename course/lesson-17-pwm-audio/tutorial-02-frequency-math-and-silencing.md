# Tutorial 02 — Frequency Math at Assemble Time, and How to Go Silent

## No hardware divider, so compute periods with `.equ`

The formula relating a target frequency to a Timer_A period is simple:

```
period = (SMCLK_Hz / frequency_Hz) - 1
```

[`wiring/phase-4-audio.md`](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/wiring/phase-4-audio.md) works this out for a few notes at 1 MHz
SMCLK: A4 (440 Hz) → 2271, C5 (523 Hz) → 1911, middle C (262 Hz) → 3816.
The MSP430G2553 has no hardware multiply or divide instruction — dividing
1,000,000 by an arbitrary runtime value is real work you don't want to do
in an ISR or a hot loop. The fix is to never do it at runtime at all:
compute every period you'll ever need with `.equ` arithmetic, at assemble
time, where GAS does the division for you for free:

```asm
.equ    SMCLK_HZ,       1000000
.equ    TONE_A4_HZ,     440
.equ    TONE_A4_PERIOD, (SMCLK_HZ/TONE_A4_HZ)-1     ; = 2271, computed by
                                                       ; the assembler, not
                                                       ; the MSP430
```

This is exactly the `.equ` arithmetic style you've used for timing
constants since Lesson 04 — nothing new mechanically, just applied to a
new kind of constant. It's also why `hal/audio.s`'s public interface (in
this lesson's milestone) takes a **period**, not a raw frequency in Hz —
so the division always happens on your development machine, never on the
chip.

## Trace-through: what happens if you get the period wrong

Say you meant to play A4 (440 Hz, period 2271) but wrote `2135` instead
(off by roughly 6%). The timer doesn't know or care what "440 Hz" means —
it just counts 0 up to whatever value is in `TACCR0` and rolls over. A
smaller period means the counter rolls over *sooner*, which means more
rollovers per second, which means a *higher* frequency — audibly sharp,
not flat. A larger-than-intended period does the opposite: fewer
rollovers per second, audibly flat. If the error is small you'll hear an
out-of-tune note; if it's large (say, off by a factor of 2) you'll hear a
note a full octave away from what you intended, because doubling or
halving a period exactly doubles or halves the frequency.

This is worth internalizing now, because Lesson 18's note table is
nothing but a list of these period constants — a single wrong digit in
that table produces a specific, audible, and very findable wrong note.

## Going silent without stopping the timer

A tone you can't turn off isn't useful for a game (you need silence
between sound effects, and silence when nothing is happening). The
straightforward way is to let the timer keep running continuously in the
background, and control whether the compare channel's output actually
*reaches* the pin using `P2SEL`:

```asm
bis.b   #PWM_PIN, &P2SEL     ; pin driven by TA1.2 hardware -> audible
bic.b   #PWM_PIN, &P2SEL     ; pin reverts to plain GPIO, driven by P2OUT
```

With `P2SEL`'s bit clear, the pin is ordinary GPIO again, and whatever
level you left in `P2OUT` (keep it LOW) is what the amp sees — silence,
with no DC bias into the LM386's input. This is cheaper and simpler than
stopping and restarting `TA1CTL`'s mode bits every time you want quiet,
and it means the timer's period/duty registers can stay loaded and ready
to sound again instantly.
