# Tutorial 01 — P1DIR and P1OUT in Depth

## Two Registers, One Job Each

You've already used both of these to get LED1 blinking. Here's the fuller
picture.

**P1DIR — direction.** One bit per pin. `0` = input, `1` = output. This is
a *per-pin* setting inside one 8-bit register — bit *N* controls P1.*N*.
Until a pin's direction bit is `1`, writes to `P1OUT` for that pin don't
drive the physical output at all; the pin stays in whatever input state it
was in (typically floating, unless `P1REN` is involved — that's Lesson 03
Ex1/Ex2 and Lesson 03's sibling input lesson territory, not here).

**P1OUT — output level.** Also one bit per pin, but its *meaning* depends
on that pin's direction:

- If the pin is an **output** (`P1DIR` bit = 1): `P1OUT` bit = the driven
  logic level. `1` = HIGH (3.3 V), `0` = LOW (0 V).
- If the pin is an **input** with its pull resistor enabled (`P1REN` bit =
  1): `P1OUT` bit selects pull-up (`1`) vs pull-down (`0`) instead of
  driving anything.

This lesson only deals with the output case. LED1 (P1.0) and LED2 (P1.6)
are both active-HIGH, so `P1OUT` bit = 1 turns the LED on.

### Why direction has to be set first

`P1DIR` and `P1OUT` are independent registers, but they only combine to
produce a meaningful output once both are configured: direction says
"this pin is mine to drive," and output says "drive it to this level."
Setting `P1OUT` bits on a pin that's still an input (the power-on-reset
default for all P1 pins) has no visible effect on the physical pin — you're
only writing to the "pull resistor direction" interpretation of that bit,
which does nothing unless `P1REN` is also set. If your LED never lights,
before suspecting the timing or the `bis`/`bic` mask, confirm `P1DIR` is
actually set for that pin.

### The toggle trick

You've seen `xor.b #LEDx, &P1OUT` used to blink an LED without tracking
whether it's currently on or off. XOR flips exactly the bits set in the
mask and leaves every other bit alone — so it's safe on a shared register
in the same way `BIS`/`BIC` are, and it's more compact when the current
state doesn't matter (you're going to flip it either way).

## The Golden Rule: P1OUT and P1DIR Control *All Eight Pins at Once*

`P1OUT` is a single 8-bit register. Every pin's output level lives in the
same byte. LED1 is bit 0. LED2 is bit 6. The button (once you wire it up as
an input with pull-up, later in this lesson's exercises) uses bit 3 of
`P1OUT` for a completely different purpose (pull direction, not output
level). Later lessons put UART and SPI pins in this same byte too.

That means **any instruction that writes to `P1OUT` without a precise mask
risks clobbering bits you don't own.** The three safe instructions from
`msp430g2553-defs.s`:

```asm
bis.b   #mask, &P1OUT   ; set   only the masked bits — others untouched
bic.b   #mask, &P1OUT   ; clear only the masked bits — others untouched
xor.b   #mask, &P1OUT   ; toggle only the masked bits — others untouched
```

Contrast with:

```asm
mov.b   #mask, &P1OUT   ; REPLACES the entire byte — every unmasked bit
                         ; becomes 0, whether you meant it to or not
```

`mov.b` is not "wrong" in an absolute sense — sometimes you *do* want to
set the whole register at once (e.g. right after reset, when you know every
bit's desired value). But once more than one peripheral shares a port, a
`mov.b` to `P1OUT` is almost never what you want, because it forgets every
bit you didn't explicitly list.

## Worked Scenario: The Clobber

Say LED2 is already on (P1OUT bit 6 = 1), and LED1 is off (bit 0 = 0).
Current `P1OUT` (showing only bits 7–0, `-` = don't-care bits not used by
LED1/LED2 in this trace):

```
bit:     7 6 5 4 3 2 1 0
P1OUT:   - 1 - - - - - 0      (LED2 on, LED1 off)
```

Now you want to turn LED1 on too, intending for LED2 to stay on. Two ways
to write it:

**Correct — `bis.b`:**
```asm
bis.b   #LED1, &P1OUT     ; P1OUT |= 0000 0001
```
```
bit:     7 6 5 4 3 2 1 0
before:  - 1 - - - - - 0
mask:    0 0 0 0 0 0 0 1
after:   - 1 - - - - - 1      ← LED2 untouched, LED1 now on
```

**Wrong — `mov.b`:**
```asm
mov.b   #LED1, &P1OUT     ; P1OUT = 0000 0001  (replaces everything)
```
```
bit:     7 6 5 4 3 2 1 0
before:  - 1 - - - - - 0
after:   0 0 0 0 0 0 0 1      ← LED2 got FORCED OFF — bit 6 clobbered!
```

The `mov.b` version doesn't just fail to turn on LED1 correctly — it
actively turns LED2 off, even though nothing in the instruction mentions
LED2 at all. That's the clobber: every bit not named in the mask gets
reset to whatever literal value you wrote, silently discarding the state
of every other pin sharing that register. This is exactly the bug class
`bis.b`/`bic.b`/`xor.b` exist to prevent, and it only gets more dangerous as
more peripherals move onto Port 1 in later lessons.

**Rule of thumb:** if you're not initializing the entire register from
scratch (e.g. immediately after reset with every pin's state already
decided), reach for `bis.b`/`bic.b`/`xor.b` with a precise mask instead of
`mov.b`.
