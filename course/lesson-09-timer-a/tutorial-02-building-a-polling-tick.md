# Tutorial 09.2 — Building a Periodic Tick via `TAIFG` Polling

## From cycle-counting to flag-polling

Lesson 04's software delay loop worked by counting down a register a known
number of times, where "known" meant *you* worked out how many loop
iterations took how many CPU cycles. That count was baked into the loop
structure itself — changing the delay meant recalculating the loop bounds.

A Timer_A polling tick separates those two concerns. The timer counts
cycles in hardware, completely independent of what the CPU is doing. The
CPU's job shrinks to one question, asked repeatedly: *has one period
elapsed yet?* That question is answered by reading a single bit —
`TAIFG` — in `TACTL`:

```asm
.Lwait_tick:
    bit.w   #TAIFG, &TACTL      ; test bit, Z=1 if TAIFG is 0 (not yet)
    jz      .Lwait_tick         ; loop while flag is still clear
    bic.w   #TAIFG, &TACTL      ; acknowledge — clear the flag yourself
```

Two details matter here:

1. **`bit.w` doesn't clear the flag.** It only sets the CPU's own `Z` flag
   based on whether `TAIFG` is currently 0 or 1 — that's how you test a bit
   without disturbing it. If you don't explicitly `bic.w #TAIFG, &TACTL`
   afterward, the flag stays set and your next poll loop would fall through
   immediately without actually waiting.
2. **This is still a busy-wait**, just against a hardware-timed target
   instead of a cycle count. The CPU is 100% occupied spinning in
   `.Lwait_tick` between ticks — it can't do anything else. That's exactly
   the limitation Lesson 10 (interrupts) and Lesson 11 (low-power modes)
   remove: an interrupt lets the CPU do other work (or sleep) between ticks
   instead of spinning.

## Why this is more robust than a software delay

Compare the two approaches directly. A software delay loop's actual elapsed
time depends on: the CPU clock frequency, the exact instruction sequence
inside the loop (how many cycles each instruction takes), and — subtly —
anything that could interrupt or stall the CPU while it's counting (not a
concern yet in this course, but it will be once interrupts are introduced).
A Timer_A tick's period depends on exactly two things: the timer's input
clock frequency (SMCLK, ACLK, or TACLK, after any divider) and `TACCR0`.
Nothing about how the *polling loop itself* is written affects the tick's
actual timing — the polling loop is just asking a hardware clock "are we
there yet?", not doing the timing itself. This is what makes hardware-timed
ticks the right foundation for anything that needs to stay accurate over
thousands of repetitions, like a multi-minute Tetris game session.

## Worked trace: what a full tick loop looks like

Putting Tutorial 09.1's configuration together with the polling idiom above,
a complete periodic action (toggle an LED once per tick) looks like:

```asm
    mov.w   #TACCR0_HALF_SEC, &TACCR0
    mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL

.Lloop:
    bit.w   #TAIFG, &TACTL
    jz      .Lloop
    bic.w   #TAIFG, &TACTL
    xor.b   #LED1, &P1OUT       ; the periodic action
    jmp     .Lloop
```

Every 0.5 seconds (per this lesson's worked `TACCR0` value), the loop falls
through the `jz`, clears the flag, does its one unit of periodic work, and
goes back to waiting. If you wanted a *counted* tick (e.g., "do this every
10th tick" — closer to what a real game tick divider looks like), you'd
keep a register as a countdown and decrement it once per loop pass instead
of acting every time — but deciding exactly how to structure that countdown
is left to you in Exercise 3, which asks for precisely this kind of
polling-tick module in `handheld/hal/timer.s`.

## Check your understanding

1. Why must you explicitly clear `TAIFG` with `bic.w`, instead of it being
   cleared automatically when you read `TACTL`?
2. Suppose your polling loop forgets to clear `TAIFG`. What's the observable
   symptom the next time through the loop?
3. What specifically does Lesson 10's interrupt-driven approach let the CPU
   do that this lesson's polling loop cannot?
