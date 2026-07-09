# Lesson 05 Exercises

Two tiers: Explore (ex1), Challenge (ex2). Lesson 05 has no milestone — the
first `handheld/` milestone is Lesson 07's `hal/display.s`.

## Ex1 — Explore: Reusable `delay_ms`

**Directory:** `ex1/`

Write your own `delay_ms` subroutine — argument: `R12` = milliseconds — from
scratch, and use it to blink LED1 at 1 Hz (on 500 ms / off 500 ms). The
starter file gives you the mandatory boilerplate (stack init, watchdog
disable, DCO calibration, LED1 direction setup) and a vector table skeleton.
The subroutine itself, and the main loop that calls it, are yours to write.

The point of this exercise is *parameterization*, not just "a working
delay." Prove your `delay_ms` genuinely reads its argument from `R12` rather
than being hardcoded to one duration — call it with at least two different
values somewhere in your test process (temporarily, if you want the final
program to only blink at 1 Hz) and confirm the delay actually changes
proportionally.

Tutorial 01 and Tutorial 02 cover everything you need: `call`/`ret`
mechanics, and the R12 argument convention. SLAU144 Ch. 8 has the GPIO
details if you need a refresher from Lesson 02/03.

**Success criteria:**
- [ ] `delay_ms` takes its duration in `R12` — calling it with different
      values produces proportionally different real-world delays (verify by
      trying at least two different values and observing the change).
- [ ] LED1 blinks at a stopwatch-verifiable 1 Hz in the final program.
- [ ] `delay_ms` is a genuine subroutine — called with `call`, returns with
      `ret` — not inlined into the main loop.

## Ex2 — Challenge: Stack-Corruption Bug

**Directory:** `ex2/`

`ex2/stack_corruption_bug.s` is a complete, compiling program. Its header
comment states the *intended* behavior: a repeating LED flash pattern built
from a small chain of subroutine calls.

**Observable failure:** flash it and watch LED1. The pattern runs correctly
for the first few repetitions — then the board appears to hang or reset,
and the LED either stops responding or starts doing something that doesn't
match the intended pattern at all.

Your job: find out why, using the stack-mechanics reasoning from Tutorial
01 — specifically the "what breaks if a `pop` is missing" scenario. This
exercise will not tell you which subroutine, which register, or which line
is involved. Trace the call chain by hand: for every `push` in every
subroutine involved, is there exactly one matching `pop` on every path
before that subroutine's `ret`? Somewhere in this chain, the accounting
doesn't balance.

**Success criteria:**
- [ ] I can describe the observed failure precisely (how many repetitions
      run correctly before it breaks, and what happens after) before making
      any changes.
- [ ] I can point to the exact instruction where a `push`/`pop` pair is
      unbalanced, and explain in terms of `SP` and stack contents why that
      specific imbalance produces the specific symptom observed.
- [ ] After my fix, the LED pattern repeats correctly indefinitely with no
      hang, reset, or drift.
