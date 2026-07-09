# Tutorial 09.1 — Timer_A Modes and Up Mode

## The counter at the center of it

Timer_A is built around one 16-bit hardware counter, `TAR`, that increments
once per input clock edge (after any divider) entirely on its own — no CPU
instructions required. What differs between Timer_A's four **modes** (set
by the `MC` bits in `TACTL`) is *what happens when `TAR` reaches its top
value*:

| Mode | `MC` bits | Counts | At the top... |
|------|-----------|--------|----------------|
| **Stop**       | `MC_0` (00) | Doesn't count | — (frozen) |
| **Up**         | `MC_1` (01) | 0 → `TACCR0` | Resets to 0, sets `TAIFG` |
| **Continuous** | `MC_2` (10) | 0 → 0xFFFF   | Resets to 0, sets `TAIFG` |
| **Up/Down**    | `MC_3` (11) | 0 → `TACCR0` → 0 | Reverses direction at each end |

Two things to notice immediately:

1. **Up mode's period is programmable** — it's whatever you put in
   `TACCR0`. Continuous mode's period is fixed at 65,536 counts (0 through
   0xFFFF) — you can't ask it for an arbitrary period. This is why Up mode
   is the default choice whenever you want a *specific* tick length (a game
   frame, a UART bit period, a debounce window) rather than "however long
   65,536 clock cycles happens to take."
2. **`TAIFG` sets in both Up and Continuous mode**, whenever the counter
   rolls over back to 0. It is *not* exclusive to Continuous mode — this is
   a common misreading. `TAIFG` just means "the counter completed one full
   cycle," and what "one full cycle" means depends on the mode.

Up/Down mode (count up to `TACCR0`, then count back down to 0) is used for
*symmetric* PWM waveforms later in the course (Lesson 17) — it isn't needed
for a periodic tick, since Up mode already gives you exactly that.

## Configuring Up mode

`TACTL` packs the clock source, input divider, mode, and a few control bits
into one 16-bit register:

```
TACTL bit layout (from msp430g2553-defs.s):
  bits 9-8  TASSEL  — clock source (TACLK/ACLK/SMCLK/INCLK)
  bits 7-6  ID      — input divider (/1, /2, /4, /8)
  bits 5-4  MC      — mode (Stop/Up/Continuous/Up-Down)
  bit 2     TACLR   — write 1 to reset TAR to 0 (self-clearing)
  bit 1     TAIE    — overflow interrupt enable (Lesson 10)
  bit 0     TAIFG   — overflow interrupt flag
```

A typical Up-mode configuration, SMCLK source, no CPU-side software divider
yet:

```asm
mov.w   #TACCR0_VALUE, &TACCR0
mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL   ; SMCLK, Up mode, clear TAR
```

`TACLR` is included so the timer starts counting from a known state (0)
rather than whatever `TAR` happened to hold before — it's a one-shot
"reset" bit that the hardware clears automatically after acting on it.

## Computing `TACCR0` for a target period

In Up mode, the timer counts `TACCR0 + 1` input clock edges per period
(0, 1, 2, ... `TACCR0`, then back to 0 — that's `TACCR0 + 1` distinct
values). So:

```
period_cycles = TACCR0 + 1
TACCR0        = period_cycles - 1
```

Suppose SMCLK is calibrated to 1 MHz (Lesson 08) and you want a 0.5-second
tick. First, decide whether you need Timer_A's own input divider (`ID`,
separate from — and stackable with — any `BCSCTL2` SMCLK divider from
Lesson 08). At 1 MHz, 0.5 seconds is 500,000 cycles — too many for a 16-bit
`TACCR0` (max 65,535). Adding Timer_A's `/8` input divider (`ID_3`) brings
the *effective* timer clock down to 125 kHz, so 0.5 seconds becomes 62,500
cycles — well within range:

```asm
.equ    SMCLK_HZ,           1000000
.equ    TA_DIVIDER,         8                   ; ID_3 → Timer_A input /8
.equ    TA_HZ,              (SMCLK_HZ / TA_DIVIDER)     ; = 125,000
.equ    HALF_SEC_TICKS,     (TA_HZ / 2)                 ; = 62,500
.equ    TACCR0_HALF_SEC,    (HALF_SEC_TICKS - 1)        ; = 62,499

mov.w   #TACCR0_HALF_SEC, &TACCR0
mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL
```

Notice the `.equ` chain names every assumption: the source clock frequency,
the divider, the derived effective frequency, the target period in ticks,
and finally the register value (which is one less than the tick count,
per the formula above). If any of those assumptions change — a different
SMCLK frequency, a different divider, a different target period — only the
relevant `.equ` needs to change, and every dependent constant recalculates
automatically when you rebuild.

## Check your understanding

1. In Continuous mode, can you configure an arbitrary period, or is it
   fixed? If fixed, at how many counts?
2. Does `TAIFG` ever set in Up mode, or only in Continuous mode?
3. At SMCLK = 1 MHz with no Timer_A input divider (`ID_0`), what `TACCR0`
   value gives a 10 ms period? (Show the `.equ` chain, not just the final
   number.)
