# Tutorial 10.2 — `reti` vs `ret`, Priority, and the ISR Timing Budget

## `reti` restores more than `ret` does

An ordinary subroutine returns with `ret`, which pops one word — the saved
`PC` — off the stack and resumes execution there. That's correct for a
`call`, because a `call` only pushed the `PC`.

An interrupt is different: hardware pushed **two** words on entry — `PC`
*and* `SR` (Tutorial 10.1, step 2-3). If an ISR ended with a plain `ret`, it
would pop the `PC` correctly but leave the pushed `SR` sitting on the stack,
corrupting the stack pointer relative to what the rest of the program
expects, and leave the *current* `SR` (with `GIE` still cleared from step 4)
in place — interrupts would stay globally disabled forever after the first
one.

`reti` pops **both**: `SR` first, then `PC`. This is what makes `reti`
correct for ISRs specifically:

```asm
cc0_isr:
    xor.b   #LED1, &P1OUT
    reti                        ; restores SR (including GIE) AND PC
```

Restoring the saved `SR` matters for more than just `GIE`. Recall from
Lesson 11 (previewed here) that entering a low-power mode sets `CPUOFF` in
`SR`. If the CPU was asleep in LPM0 when the interrupt fired, the *pushed*
`SR` has `CPUOFF` set. On `reti`, restoring that saved `SR` verbatim means
the CPU goes right back to sleep the instant the ISR finishes — a
`reti` alone reproduces the "sleep between ticks" behavior automatically,
with no extra code. If an ISR needs the CPU to *stay awake* after it returns
(to let the main loop process something), it must explicitly clear
`CPUOFF` in the copy of `SR` still sitting on the stack, before `reti` pops
it:

```asm
    bic.w   #CPUOFF, 0(SP)      ; clear CPUOFF in the saved SR (still on stack)
    reti                        ; now restores SR *without* CPUOFF → CPU stays awake
```

Both patterns are correct — which one to use depends entirely on whether
the ISR did everything that needs doing (use plain `reti`, let the saved
`SR` decide), or whether it's just signaling that the main loop has work to
do (clear `CPUOFF` first). Lesson 11 uses both, explicitly, side by side.

## Interrupt priority

If two interrupt conditions become true "simultaneously" (or one is still
pending when another arrives), the MSP430 resolves the conflict by fixed
hardware priority: **the vector closer to 0xFFFE (the highest address) wins.**
Reset (0xFFFE) is the highest priority interrupt of all — even higher than
any peripheral. Working down from there, Timer1_A1 (0xFFF8), Comparator_A+
(0xFFF6), WDT (0xFFF4), Timer_A CC0 (0xFFF2), Timer_A overflow (0xFFF0), and
so on toward Port 1 (0xFFE4) — each successively lower address is a
successively lower priority. This ordering is fixed in silicon; you cannot
reprioritize it in software. In practice, for this course, priority mostly
matters once you have two active interrupt sources at once (Timer_A ticks
*and* Port 1 button presses, from Lesson 16 onward) and need to reason about
which one preempts which if both are pending at once.

## The ISR timing budget

Because hardware clears `GIE` on entry (step 4 of Tutorial 10.1) and only
`reti` restores it, **no other maskable interrupt can be serviced while an
ISR is running** (unless the ISR explicitly re-enables `GIE` itself, which
this course does not do). This creates a hard budget: an ISR must finish —
including "boring" work like saving/restoring any registers it borrows per
`handheld/registers.md` — well within the shortest period of any interrupt
it needs to keep up with.

Trace through what happens if a Timer_A CC0 ISR, ticking every 5 ms,
occasionally takes 6 ms to execute (say, because of an expensive branch
taken only sometimes): while that ISR runs, `TAR` keeps counting in
hardware — Timer_A doesn't pause for the CPU. By the time the slow ISR
finally reaches `reti` and restores `GIE`, the *next* CC0 match may have
already occurred and be sitting pending. The result is not a smoothly
5 ms-late tick — it's a burst: the overdue interrupt fires again
**immediately** after `reti`, back-to-back with no gap, and then the tick
schedule continues from wherever it landed. Visibly, a steady 1 Hz LED
blink built on this tick would show an occasional stutter — a beat that's
slightly early or a hair off-rhythm — rather than a uniformly slow blink.
This is exactly the failure mode Exercise 2 asks you to observe and reason
about.

## Check your understanding

1. What two things does `reti` pop off the stack, and in what order?
2. An ISR was entered while the CPU was asleep in LPM0 (`CPUOFF` set in the
   saved `SR`). If the ISR ends with a plain `reti` and never touches
   `0(SP)`, does the CPU go back to sleep, stay awake, or is it undefined?
3. Two interrupts are pending at the same instant: Timer_A CC0 (0xFFF2) and
   Port 1 (0xFFE4). Which one does the CPU service first, and how do you
   know without checking documentation for these two specifically?
