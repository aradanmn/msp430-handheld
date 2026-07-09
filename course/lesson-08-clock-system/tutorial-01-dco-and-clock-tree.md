# Tutorial 08.1 — The DCO and the Basic Clock System

## Why the CPU needs calibrating at all

The MSP430G2553's default clock source is the **DCO** — Digitally
Controlled Oscillator. It's an RC-based oscillator built directly on the
chip: cheap, fast to start up (a few microseconds — important for waking
from low-power modes later), but *imprecise*. Straight out of reset, the DCO
runs at some frequency determined by process variation, temperature, and
supply voltage — it could be anywhere from under 1 MHz to several MHz
depending on the specific chip in your hand.

That's useless for anything timing-sensitive. A delay loop tuned for 1 MHz
would run at the wrong speed on an uncalibrated DCO, and it would run at a
*different* wrong speed on a different chip, or even the same chip at a
different temperature.

TI's fix: at the factory, every MSP430G2553 is individually measured, and
four calibration values get burned into a protected region of Flash called
**Info Flash** (0x1000–0x10FF, segment C in the datasheet). These bytes tell
the chip exactly how to configure its own DCO trim registers to hit
1 MHz, 8 MHz, 12 MHz, or 16 MHz *on this specific piece of silicon*.

```
.equ    CALBC1_1MHZ,    0x10FF  ; → BCSCTL1 for 1 MHz
.equ    CALDCO_1MHZ,    0x10FE  ; → DCOCTL  for 1 MHz
.equ    CALBC1_8MHZ,    0x10FD  ; → BCSCTL1 for 8 MHz
.equ    CALDCO_8MHZ,    0x10FC  ; → DCOCTL  for 8 MHz
```

You never compute these values yourself — you just copy them from Info Flash
into the live control registers:

```asm
clr.b   &DCOCTL                 ; clear fine-tune first to avoid a glitch
mov.b   &CALBC1_1MHZ, &BCSCTL1  ; coarse range
mov.b   &CALDCO_1MHZ, &DCOCTL   ; fine-tune
```

### Why `clr.b &DCOCTL` comes first

`DCOCTL` holds the DCO's fine-tune step (bits 7-5) and modulation (bits
4-0). `BCSCTL1` holds the *coarse* frequency range (bits 7-4, `RSEL3:RSEL0`).
If you load the new coarse range into `BCSCTL1` while `DCOCTL` still holds
fine-tune bits calibrated for a *different* range, the DCO briefly runs at
some in-between, undefined frequency — a glitch. Clearing `DCOCTL` first
means the fine-tune bits are all zero (a known, safe state) while the coarse
range changes, and only then do you load the correct fine-tune value. This
is why the four-instruction sequence is always written in that exact order.

### Switching to 8 MHz

The only difference between calibrating to 1 MHz and 8 MHz is *which pair*
of Info Flash constants you copy:

```asm
clr.b   &DCOCTL
mov.b   &CALBC1_8MHZ, &BCSCTL1
mov.b   &CALDCO_8MHZ, &DCOCTL
```

Same sequence, same registers — only the source addresses change. But
*everything downstream that assumed 1 MHz* — every delay loop constant,
every future baud-rate divisor, every Timer_A period — is now wrong by a
factor of 8, because the CPU is executing (and any clock derived from
MCLK/SMCLK without additional division is ticking) eight times faster than
before. Tutorial 08.2 and Exercise 2 dig into exactly what breaks and why.

## The three clocks: MCLK, SMCLK, ACLK

The DCO doesn't feed the CPU and every peripheral directly — it feeds the
**Basic Clock System (BCS)**, which distributes (and optionally divides)
clock signals to three named destinations:

| Clock | Drives | Default source | Typical use |
|-------|--------|-----------------|--------------|
| **MCLK**  | The CPU itself | DCO | Instruction execution speed |
| **SMCLK** | Peripherals (Timer_A, USCI for UART/SPI/I2C, ADC10) | DCO | Anything that needs a fast, stable clock |
| **ACLK**  | Low-power/low-frequency peripherals | LFXT1 crystal, or the internal ~12 kHz VLO if no crystal is populated | Real-time-ish low-power timing |

On the MSP-EXP430G2 LaunchPad, **no 32.768 kHz crystal is populated** on
XIN/XOUT by default, so if you select ACLK as a clock source without doing
anything else, you get the internal **VLO** (Very-Low-power Oscillator) at
roughly 12 kHz instead of a crystal-accurate 32.768 kHz. That's an easy trap:
code that "looks correct" using `TASSEL_1` (ACLK) can run at a wildly
different, and much less precise, rate than you expect on this specific
board. We'll come back to this in Exercise 2.

MCLK and SMCLK both default to the DCO, and both can be independently
divided:

```
BCSCTL2 — MCLK and SMCLK dividers:
  DIVM_0 = MCLK /1     DIVM_1 = MCLK /2   (bits 5-4)
  DIVS_0 = SMCLK /1    DIVS_1 = SMCLK /2  DIVS_2 = /4   DIVS_3 = /8  (bits 2-1)

BCSCTL1 — ACLK divider:
  DIVA_0 = ACLK /1   DIVA_1 = /2   DIVA_2 = /4   DIVA_3 = /8  (bits 5-4)
```

So "the clock speed" isn't one number — it's DCO frequency ÷ whichever
divider applies to whichever named clock a given peripheral is wired to.
Timer_A, for instance, has its own *separate* input divider (`ID_0..ID_3` in
`TACTL`) on top of whatever SMCLK divider you configured in `BCSCTL2` — two
dividers can stack. Lesson 09 uses this.

## Worked example: computing an effective frequency with `.equ`

Suppose you calibrate to 1 MHz (DCO), leave `BCSCTL2` dividers at their
power-on default (`/1` for both MCLK and SMCLK), and want to know SMCLK's
frequency for a later baud-rate or timer calculation:

```asm
.equ    DCO_HZ,     1000000     ; DCO calibrated to 1 MHz
.equ    SMCLK_DIV,  1           ; BCSCTL2 DIVS_0 → /1
.equ    SMCLK_HZ,   (DCO_HZ / SMCLK_DIV)   ; = 1,000,000
```

If instead you set `DIVS_1` (SMCLK /2):

```asm
.equ    SMCLK_DIV,  2
.equ    SMCLK_HZ,   (DCO_HZ / SMCLK_DIV)   ; = 500,000
```

This is the pattern you'll use for the rest of the course: name the raw
clock rate, name the divider, and let the assembler compute the derived
value with `.equ` arithmetic rather than hand-calculating and hardcoding a
magic number. It documents *why* a constant is what it is, and it means
changing one `.equ` (say, moving from 1 MHz to 8 MHz) automatically
recalculates every dependent constant when you rebuild.

## Check your understanding

1. Why does the calibration sequence clear `DCOCTL` *before* writing
   `BCSCTL1`, instead of writing both registers in either order?
2. If you calibrate the DCO to 8 MHz but leave `BCSCTL2`'s SMCLK divider at
   its default, what is SMCLK's frequency?
3. A LaunchPad has no crystal installed. What clock actually drives ACLK,
   and roughly how far off is it from the "expected" 32.768 kHz?
