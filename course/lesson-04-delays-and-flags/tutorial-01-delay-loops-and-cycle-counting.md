# Tutorial 01 — Delay Loops & Cycle Counting

## Why count cycles at all

Every busy-wait delay you've written so far (`leds_test`'s flash timing in
`handheld/hal/leds.s`, the blink loops in Lessons 01–02) works by burning a
known number of CPU cycles doing nothing useful. At 1 MHz the CPU executes
roughly one million cycles per second, so — approximately — **1 cycle ≈ 1
microsecond**. If you know exactly how many cycles a loop body costs, you
know exactly how long it takes, and you can derive the loop count needed to
hit any target duration instead of guessing a magic number and eyeballing
the result with your own eyes and a sense of "that looks about right."

That approximation (1 cycle ≈ 1 µs at 1 MHz) is exactly that — an
approximation. Real MSP430 instructions take different numbers of cycles
depending on addressing mode (register-to-register is cheapest; indexed or
absolute addressing costs more). This tutorial — and the rest of this
course — uses the same simplified accounting `handheld/hal/leds.s` already
uses in its `.Ldelay_ms` comment: **`dec` costs 1 cycle, `jnz` costs 2
cycles when taken**. That's close enough to build calibrated delays that
land within a few percent of their target, which is exactly the bar this
lesson's success criteria set.

## The one-register loop

The simplest possible delay is a single counted loop:

```asm
    mov.w   #333, R13      ; load iteration count
.Lloop:
    dec.w   R13             ; 1 cycle
    jnz     .Lloop          ; 2 cycles (taken), 1 cycle (not taken, last pass)
```

Per the accounting above, each pass through the loop *except the last* costs
`dec` (1) + `jnz` taken (2) = **3 cycles**. The final pass costs `dec` (1) +
`jnz` not-taken (1) = 2 cycles, but for a loop counting into the hundreds
that one-cycle discrepancy is noise — we'll treat every pass as 3 cycles for
calibration purposes, same as the comment in `leds.s` does.

333 iterations × 3 cycles/iteration = 999 cycles ≈ 1 ms at 1 MHz. That's
exactly the constant `handheld/hal/leds.s` uses for `.Ldelay_ms`'s inner
loop, and exactly why it's 333 and not, say, 300 or 1000.

## Building the constant with `.equ`

Instead of writing the bare number `333` and trusting that whoever reads it
remembers why, name it:

```asm
.equ    MS_CYCLES, 333          ; iterations for ~1 ms at 1 MHz, ~3 cycles/iter
```

From here on in this course, **`.equ` arithmetic is the expected style for
any timing constant** — don't hand-calculate a derived value and paste the
result; let the assembler do the arithmetic so the relationship between
constants stays visible in the source:

```asm
.equ    MS_CYCLES,     333                  ; ~1 ms per outer-loop pass
.equ    DELAY_500MS,   (500 * MS_CYCLES)    ; total inner-loop iterations for 500 ms
```

`DELAY_500MS` here isn't a loop count you'd load into a single register in
one shot (500 × 333 = 166,500 doesn't fit usefully as a flat single-register
countdown at this granularity) — it's a way of keeping the *relationship*
between "milliseconds wanted" and "inner-loop iterations" visible and
checkable in the source itself. In practice you still write the delay as a
**nested loop**: an outer counter of milliseconds, and for each pass, an
inner counter of `MS_CYCLES` iterations — exactly the shape `leds.s`'s
`.Ldelay_ms` already has, just with the "333" given a name:

```asm
delay_ms:                    ; R12 = number of ms to wait
.Ldelay_ms_outer:
    mov.w   #MS_CYCLES, R13
.Ldelay_ms_inner:
    dec.w   R13
    jnz     .Ldelay_ms_inner
    dec.w   R12
    jnz     .Ldelay_ms_outer
    ret
```

Writing `.equ DELAY_500MS, (500 * MS_CYCLES)` and then, separately,
`mov.w #500, R12` before calling `delay_ms` is how you keep both numbers —
the outer count and the total cycle budget they imply — connected to the
same source of truth (`MS_CYCLES`) instead of two constants that happen to
agree today and silently drift apart the next time someone tunes the clock.

## Worked example: hand-calculating a delay

Take the nested loop above with an outer count of 250 (`R12 = 250`) and the
standard inner count `MS_CYCLES = 333`.

**Inner loop cost per outer pass:**
333 iterations × 3 cycles = 999 cycles, plus the `mov.w #MS_CYCLES, R13`
that reloads the inner counter at the top of each outer pass (roughly 2
cycles for an immediate-to-register move) ≈ **1001 cycles per outer pass**.

**Total cost:**
250 outer passes × 1001 cycles/pass ≈ **250,250 cycles**.

**Real-world duration at 1 MHz** (1 cycle ≈ 1 µs):
250,250 cycles ≈ **250.25 ms** — a 250 ms delay, accurate to within a
fraction of a percent of the simplified accounting.

### What one extra instruction costs you

Suppose you're debugging the inner loop and leave a stray instruction in
the body — say a `bit.w #1, R14` added temporarily to inspect something,
that never got removed:

```asm
.Ldelay_ms_inner:
    dec.w   R13
    bit.w   #1, R14      ; leftover — costs ~1 extra cycle, does nothing useful
    jnz     .Ldelay_ms_inner
```

That's one more cycle per inner iteration: 4 cycles instead of 3. Redo the
math: 333 × 4 = 1332 cycles per outer pass instead of 999 — roughly a 33%
increase. Over 250 outer passes, your "250 ms" delay is now taking closer to
**333 ms**. A single leftover instruction inside a hot loop is easy to miss
by eye and easy to catch with a stopwatch — which is exactly the discipline
this lesson's success criteria ask you to practice: don't just build the
delay, *measure* it.

## Next

Cycle counting explains *how long* a sequence takes. It says nothing about
what that sequence does to the CPU's status flags along the way — and once
you start calling subroutines from inside timing-sensitive code, that
becomes the more dangerous question. That's Tutorial 02.
