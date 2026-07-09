# Tutorial 10.1 — The Vector Table and ISR Mechanics

## What the hardware does when an interrupt fires

An interrupt source (a peripheral, like Timer_A's CC0 compare) sets its own
flag (`CCIFG`) the instant the triggering event happens — this part happens
in hardware regardless of anything the CPU has configured. Whether that flag
*turns into an actual interrupt* depends on two more bits, both of which you
control:

1. The peripheral's own interrupt-enable bit — for Timer_A CC0, that's
   `CCIE` in `TACCTL0`.
2. The **global interrupt enable**, `GIE` — bit 3 of the status register
   `SR`. This is a single master switch for *every* maskable interrupt
   source on the chip.

Only when a flag is set **and** its local enable is set **and** `GIE` is set
does the CPU actually respond. When it does, here is the exact sequence,
entirely in hardware, before your ISR code runs a single instruction:

1. The currently-executing instruction finishes.
2. The CPU pushes the current `PC` (R0) onto the stack.
3. The CPU pushes the current `SR` (R2) onto the stack.
4. The CPU clears `GIE` in `SR` — **interrupts are automatically disabled
   the instant an ISR starts**, so a second interrupt can't preempt this one
   until the ISR explicitly (via `reti`) restores the saved `SR`.
5. The CPU fetches the 16-bit address stored at that interrupt's fixed
   vector location and jumps there.

This whole sequence — takes a fixed number of cycles (SLAU144 states 6
cycles for this "interrupt latency") before your first ISR instruction
executes.

## The vector table, concretely

The vector table is just 16 words (32 bytes) sitting at fixed addresses
0xFFE0–0xFFFF. Each peripheral's interrupt has a permanently fixed slot; you
don't choose which address a given peripheral uses, you only choose what
*code address* to put in that slot:

```asm
    .section ".vectors","ax",@progbits
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   0           ; 0xFFE4  Port 1
    .word   0           ; 0xFFE6  Port 2
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI_A0/B0 TX
    .word   0           ; 0xFFEE  USCI_A0/B0 RX
    .word   0           ; 0xFFF0  Timer_A overflow (TAIV)
    .word   cc0_isr     ; 0xFFF2  Timer_A CC0     ← our ISR goes here
    .word   0           ; 0xFFF4  WDT
    .word   0           ; 0xFFF6  Comparator_A+
    .word   0           ; 0xFFF8  Timer1_A1
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
```

Notice the Reset vector (0xFFFE) is really just the *same mechanism* used
for every other interrupt — a power-on reset is, from the CPU's point of
view, the highest-priority "interrupt" there is, and it always jumps to
whatever address sits in that last slot.

## One dedicated vector vs. one shared vector

Timer_A actually has two interrupt vectors, and they behave differently:

- **CC0 (0xFFF2)** — dedicated exclusively to the CC0 compare match. When
  the CPU services this vector, hardware automatically clears `CCIFG` for
  you. No explicit flag-clearing instruction needed in the ISR.
- **TAIV (0xFFF0)** — shared between the timer overflow flag *and* CC1/CC2
  (any compare/capture channel other than CC0). Because multiple sources
  feed into this one vector, you must read `TAIV` inside the ISR to find out
  *which* source fired — reading `TAIV` also auto-clears the highest-priority
  pending flag as a side effect. This course's Timer_A usage sticks to CC0
  for ticks, so you won't need `TAIV` decoding until PWM work in Lesson 17
  introduces CC1/CC2.

## Check your understanding

1. List, in order, the five things the CPU hardware does between "an
   enabled interrupt condition becomes true" and "your ISR's first
   instruction executes."
2. `CCIE` is set in `TACCTL0`, but `GIE` was never set anywhere in the
   program. Does the ISR ever run? Does `CCIFG` still get set by hardware?
3. Why doesn't a CC0 ISR need to manually clear `CCIFG`, while a TAIV-based
   ISR (for CC1/CC2/overflow) does need explicit handling?
