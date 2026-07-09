# Tutorial 08.2 — Choosing Clocks for Peripherals, and What Breaks When You Don't

## Which clock should drive which peripheral?

You now know the three clocks exist. The practical question every later
lesson will ask you to answer is: *which one should this peripheral use?*
The rule of thumb this course follows:

- **MCLK** — never chosen explicitly; it's whatever drives the CPU. You only
  touch it via the DCO calibration sequence.
- **SMCLK** — the default choice for anything that needs to run fast and
  needs its frequency to be *precisely known*: Timer_A game ticks (Lesson
  09+), UART baud rate (Lesson 23), SPI bit rate (Lesson 12), ADC10
  sample-and-hold timing (Lesson 24). This course's UART pattern, for
  example, is built entirely around "SMCLK = 1 MHz exactly":

  ```asm
  mov.b   #UCSSEL_2, &UCA0CTL1       ; SMCLK
  mov.b   #104, &UCA0BR0             ; 1MHz/104 ≈ 9600
  ```

  Change SMCLK's frequency (by recalibrating the DCO, or by touching
  `BCSCTL2`'s `DIVS` bits) without recalculating `UCA0BR0`, and the baud rate
  drifts — the receiving terminal reads garbage.

- **ACLK** — reserved for cases where you specifically want a *slow,
  low-power* clock independent of MCLK/SMCLK, typically so a peripheral can
  keep ticking even while the DCO is shut off in deeper low-power modes
  (LPM3, Lesson 11). Because this LaunchPad has no crystal, ACLK here means
  "the ~12 kHz VLO" — good enough for a coarse watchdog interval (Lesson 11)
  but not for anything needing sub-millisecond precision.

## Trace-through: what happens if you recalibrate mid-program?

Imagine a program that:

1. Calibrates the DCO to 1 MHz
2. Configures Timer_A with `TASSEL_2` (SMCLK) and a `TACCR0` value computed
   assuming SMCLK = 1 MHz
3. Later — for some reason — recalibrates the DCO to 8 MHz without touching
   Timer_A's configuration at all

Nothing in Timer_A's registers changed. But SMCLK is still sourced from the
DCO, and the DCO is now running 8x faster. `TACCR0` still holds the *same
number*, but each count now represents 1/8 microsecond instead of a full
microsecond. The timer period that used to be, say, 0.5 seconds is now
0.0625 seconds — the same bug pattern you'll be asked to diagnose in
Exercise 2, just relocated from a software delay loop into a hardware timer.

The general lesson: **a clock frequency and a cycle-count constant are only
correct together.** Whenever one changes, the other must be recalculated.
This is exactly why `.equ` arithmetic (Tutorial 08.1) matters — it ties the
constant to the assumption it depends on, in the source itself, instead of
a bare number that silently goes stale.

## Reasoning check: DCO frequency vs. divider vs. instruction cycles

A common point of confusion: does raising the DCO frequency make *every*
instruction faster, or just peripherals?

- MCLK drives instruction fetch/execute directly — a higher MCLK means the
  CPU genuinely executes more instructions per second. A software delay loop
  (Lesson 04's technique) that counts CPU cycles will complete in less wall
  time at a higher MCLK, for exactly the reason above.
- SMCLK drives peripherals independently of MCLK's *divider* (though both
  ultimately trace back to the same DCO unless you've deliberately switched
  ACLK to a different source). Since MCLK and SMCLK share the DCO as their
  common source in this course's default configuration, recalibrating the
  DCO changes both at once — CPU execution speed *and* every SMCLK-driven
  peripheral's effective rate, together.

This matters for Exercise 2: a "wrong blink rate" bug could come from either
side — a delay loop miscounting CPU cycles, or a Timer_A period miscounting
SMCLK cycles — and the fix in each case is the same idea (recompute the
constant for the actual clock frequency in effect) even though the affected
register is different.

## Check your understanding

1. Which of MCLK, SMCLK, ACLK would you choose to drive USCI_A0's UART baud
   rate generator, and why?
2. If SMCLK and MCLK both derive from the same DCO in this course's default
   configuration, can you change one without affecting the other? Under what
   condition (hint: `BCSCTL2` dividers) could they actually differ?
3. Suppose a Timer_A period was tuned assuming SMCLK = 1 MHz with no
   divider. If you now set `BCSCTL2`'s `DIVS_2` (SMCLK /4) without touching
   `TACCR0`, does the timer period get faster or slower, and by what factor?
