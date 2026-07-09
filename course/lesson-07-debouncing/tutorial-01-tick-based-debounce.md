# Tutorial 01 — Tick-Based Debounce

## Why the blocking fix from Lesson 06 doesn't scale

Lesson 06's ex2 asked you to design your own fix for contact bounce using
only tools you already had: polling and delay loops. The natural first
answer looks something like this — sample the pin, and if it looks like a
fresh press, freeze the CPU for a calibrated stretch of milliseconds before
trusting the pin again:

```asm
bit.b   #BTN, &P1IN
jnz     .Lnot_pressed
; looks pressed — wait out the bounce before trusting it
mov.w   #SETTLE_MS, R12
call    #.Ldelay_ms
; ... now check again, and act
```

This works, in the sense that it can produce one clean transition per
press. But it buys that correctness at a real cost, and the cost has two
parts:

1. **The CPU is frozen for the entire settle window.** While `.Ldelay_ms`
   is spinning, nothing else can happen — no other input can be read, no
   display can be updated, no audio can be generated. For a single button on
   a demo program, that's invisible. For a game reading multiple inputs
   while also driving a display and a timer, it's fatal: the "wait out the
   bounce" delay steals CPU time from everything else the platform needs to
   do, every single time the button is touched.
2. **The settle duration is a hand-tuned delay-loop count, not a clean
   number of anything.** `SETTLE_MS` came from picking a number that seemed
   to work on your bench, not from a value with any principled meaning you
   could explain or reason about later.

## The tick-based alternative

The fix is to stop blocking. Instead of freezing the CPU to wait out
bounce, sample the button **once per tick** and let the debounce logic
spread its decision-making across many quick, non-blocking calls instead of
one long blocking wait.

A **tick** is simply one iteration of a fixed-period loop. For this lesson,
that period comes from the same kind of calibrated delay loop you've used
since Lesson 04 — nothing new there. Starting in Lesson 09, a real hardware
timer will generate that fixed period instead, interrupting your code once
per tick rather than you calling a delay subroutine in a loop. When that
happens, **the debounce state machine you write today does not change at
all** — only the thing that drives it does. That's the whole reason to
design it this way now instead of waiting for Lesson 09's timer to "do it
properly": the logic is timer-agnostic by construction.

Concretely, instead of:

```asm
; blocking: freeze for SETTLE_MS every time a change looks real
```

you get:

```asm
main_loop:
    call    #.Ltick_delay        ; wait one tick (non-blocking w.r.t. the rest
                                  ; of the program's logical structure — the
                                  ; CPU is free again the instant this returns)
    ; sample + debounce-update happens here, every tick, unconditionally
    jmp     main_loop
```

The CPU is never frozen waiting specifically for a bounce to settle — it
simply does a fixed amount of debounce bookkeeping each tick, the same
small amount of work every time, whether the button is bouncing or dead
still.

## The stable-count state machine

The state machine needs exactly two pieces of persistent state:

- **Accepted state** — the debounced value external code is allowed to
  trust. This only ever changes when the state machine decides to flip it.
- **Mismatch counter** — how many *consecutive* ticks in a row the raw
  sample has disagreed with the accepted state.

Each tick:

1. Sample the raw pin.
2. Compare the raw sample to the **currently accepted** state (not to the
   previous raw sample — this distinction matters, see below).
3. If they **match**, reset the mismatch counter to zero. Nothing else
   happens this tick.
4. If they **differ**, increment the mismatch counter. If the counter has
   now reached a chosen **threshold** (some fixed number of consecutive
   disagreeing ticks), flip the accepted state to match the raw sample, and
   reset the counter to zero.

The threshold is a real design decision — too small and you'll still let
bounce through; too large and you'll be slow to recognize a real,
deliberate press, or even merge two fast real presses into one (you'll see
exactly this failure mode in ex2). Choosing it is left to you.

### Why "compare against the accepted state," not "the previous raw sample"

It would be tempting to instead compare each raw sample to the *previous*
raw sample, and count how many times in a row two consecutive samples
agree with each other. That's a different — and weaker — algorithm: a
single momentary bounce that happens to repeat the same value for a couple
of samples in a row can fool it into accepting a transition instantly.
Comparing against the **currently accepted** state instead means every
single disagreeing sample must be part of one unbroken run before anything
changes, and any agreement with the accepted state — even a single sample —
resets that run back to zero. This is what makes the state machine
genuinely bounce-immune rather than just bounce-resistant.

## Worked trace

Take a threshold of 3 consecutive disagreeing ticks. The button starts
released. A physical press happens, and — because it's a real mechanical
switch — the raw signal doesn't transition cleanly; it bounces once before
settling. Trace it tick by tick (P = raw sample reads "pressed," R = raw
sample reads "released"; the accepted state and counter are *after* that
tick's sample is processed):

| Tick | Raw sample | Compare to accepted | Mismatch counter | Accepted state |
|---|---|---|---|---|
| — | — | — | 0 | Released (initial) |
| 1 | R | matches accepted (R) | 0 | Released |
| 2 | P | differs from accepted (R) | 1 | Released |
| 3 | R | **matches accepted (R)** — bounce! | 0 | Released |
| 4 | P | differs from accepted (R) | 1 | Released |
| 5 | P | differs from accepted (R) | 2 | Released |
| 6 | P | differs from accepted (R) → **counter hits threshold (3)** | 0 (reset) | **Pressed** (flipped) |
| 7 | P | matches accepted (P) | 0 | Pressed |
| 8 | P | matches accepted (P) | 0 | Pressed |

Notice tick 3: the raw signal bounced back to "released," which — because
the accepted state is *still* "released" at that point — reads as an
**agreement**, not a fresh disagreement. The mismatch counter resets to 0
right there, and the run of 3 consecutive disagreements has to start over
from tick 4. Despite that bounce, the accepted state flips exactly once,
cleanly, at tick 6 — and stays flipped afterward. That's the whole point:
however messy the raw signal looks, the accepted state only ever tells you
something once it's actually sure.

## What this buys you

The debounced **accepted state** is now a clean, trustworthy level signal:
0 or 1, changing only when the state machine is confident, never chattering.
That's the raw material Tutorial 02 uses to build press-edge and
release-edge detection — the events a game actually reacts to.
