# Tutorial 11.2 — Building a 60 Hz Heartbeat, and Measuring What Sleep Buys You

## Why 60 Hz, and why it won't be exact

A game loop tick target of 60 Hz is a natural choice — it matches common
display refresh rates and gives smooth-feeling movement without wasting
CPU time on updates more often than anything can visibly change. But watch
what happens when you try to hit it exactly from a 1 MHz SMCLK:

```
period_cycles = SMCLK_HZ / 60 = 1,000,000 / 60 = 16,666.67
```

Not an integer. There is no way to configure `TACCR0` (which only holds
whole numbers) to produce an *exactly* 60.000 Hz tick from a 1 MHz clock, no
matter what divider you choose — 60 simply doesn't divide 1,000,000 evenly.
This isn't a mistake to fix; it's a real constraint every game programmer
runs into (the exact same issue is why NTSC video is 59.94 Hz, not a clean
60). The practical answer is to round to the nearest whole cycle count and
accept the tiny resulting error:

```asm
.equ    SMCLK_HZ,           1000000
.equ    HEARTBEAT_HZ_APPROX, 60
.equ    TICK_PERIOD_CYCLES, ((SMCLK_HZ + (HEARTBEAT_HZ_APPROX / 2)) / HEARTBEAT_HZ_APPROX)
                                        ; rounds to nearest cycle count = 16,667
.equ    TACCR0_HEARTBEAT,   (TICK_PERIOD_CYCLES - 1)   ; = 16,666
```

This gives an actual tick rate of `1,000,000 / 16,667 ≈ 59.988 Hz` — off
from 60 Hz by about 0.02%, utterly imperceptible in a game loop. The
takeaway: naming the *approximation* explicitly (`HEARTBEAT_HZ_APPROX`,
with a comment showing the actual resulting rate) is more honest and more
maintainable than pretending the number is exact.

## From a fast tick to a slower visible action

A 60 Hz tick fires far too fast to blink an LED usefully — you wouldn't be
able to see or verify it. The pattern this course uses throughout (and
which you saw named in `handheld/registers.md` as R4's role, "frame/tick
counter") is a **countdown register**, decremented once per tick, that
triggers the slower, visible action only when it reaches zero:

```asm
cc0_isr:
    dec.w   R4                      ; one tick has elapsed
    jnz     .Lnot_yet
    mov.w   #TICKS_PER_HALF_SEC, R4 ; reload the countdown
    xor.b   #LED1, &P1OUT           ; the slow, visible action
.Lnot_yet:
    reti
```

With a ~60 Hz tick, `TICKS_PER_HALF_SEC = 30` gives a visible toggle every
~0.5 seconds — a 1 Hz blink, timeable with a stopwatch, built on top of a
tick fast enough to drive real per-frame game logic later.

## What "sleep between ticks" actually buys you

Every tick, this design spends CPU time on exactly: however many
instructions the ISR executes (a handful — a decrement, a compare, maybe an
LED toggle), then goes back to sleep for the rest of the ~16.7 ms period.
At even a generous estimate of 10-15 CPU cycles of real ISR work out of
16,667 total cycles per tick, the CPU is *active* well under 0.1% of the
time — everything else is LPM0.

If you have a multimeter capable of reading milliamps, you can observe this
directly: measure the current draw of a LaunchPad running this lesson's
example (LPM0 heartbeat) versus Lesson 10's `.Lspin: jmp .Lspin` busy-wait
version. The difference is the entire point of this lesson — the LPM0
version's average current draw over time is dramatically lower, because
the CPU core is powered down for nearly the whole tick period instead of
spinning at full activity. (Consult your LaunchPad board's documentation for
the current-measurement jumper/header if you want to try this — it varies
slightly by board revision.) Exercise 1 asks you to make and record this
comparison if you have the equipment; if you don't, the code-level success
criteria (correct LPM0 entry, ISR structure) stand on their own.

## Check your understanding

1. Why can't `TACCR0` produce an exactly 60.000 Hz tick from a 1 MHz SMCLK,
   and what's the practical way to handle that?
2. Which register does `handheld/registers.md` assign the role of
   "frame/tick counter," and why does keeping it there (rather than in RAM)
   matter for a 512-byte-RAM chip?
3. Roughly what fraction of each tick period is the CPU actually *awake*
   in this lesson's heartbeat design, and what does the rest of that time
   look like from a current-draw perspective?
