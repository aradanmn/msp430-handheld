# Tutorial 01 — Input Registers and Pull-Ups

## P1IN: the only register that tells you the truth

Every Port 1 register you've used so far — `P1DIR`, `P1OUT` — is something
*you* write to configure the pin. `P1IN` is different: it's read-only, and
it always reflects the actual electrical logic level present on the pin
*right now*, regardless of what `P1DIR` says.

That "regardless of `P1DIR`" detail matters more than it sounds. Even a pin
configured as an output still has a real voltage on it, and reading `P1IN`
on an output pin will faithfully report whatever that pin is currently
driving. But for this lesson the relevant case is simpler: with a pin
configured as an *input*, `P1IN`'s bit for that pin is exactly the pin's
current voltage, sampled at the moment you read it. High voltage (near
3.3V) reads as 1. Low voltage (near 0V) reads as 0. There's no debouncing,
no filtering, no memory — every read is a fresh, instantaneous snapshot.

That instantaneousness is exactly why this lesson exists. If the electrical
signal itself is noisy or chattering, `P1IN` will happily report every
single chatter, one snapshot at a time. Keep that in mind for Tutorial 02.

## Why a floating input is a problem

The S2 button on the LaunchPad is wired as a simple mechanical switch: one
side ties to P1.3, the other side ties to ground. When you press it, P1.3 is
connected to ground (0V). But when you *release* it... P1.3 is connected to
nothing. It's electrically "floating" — not driven high, not driven low,
just sitting there picking up whatever stray noise happens to be nearby
(50/60 Hz hum, capacitive coupling from adjacent traces, your own hand near
the board). A floating digital input can read as an unpredictable mix of 0s
and 1s even when nobody is touching the switch.

The fix is a **pull resistor**: a weak internal resistor that gently pulls
the pin to a known voltage (high or low) whenever nothing else is actively
driving it. The button, when pressed, easily overpowers the weak pull
resistor and yanks the pin to ground. When released, the pull resistor wins
by default and holds the pin at a clean, defined level. No floating, no
random noise.

## P1REN: turning the pull resistor on

`P1REN` (Resistor Enable) is the register that turns this internal pull
resistor on or off, per pin. Setting a bit in `P1REN` to 1 enables the pull
resistor for that pin; leaving it 0 leaves the pin floating if it's
configured as an input.

```asm
bis.b   #BTN, &P1REN     ; enable the internal pull resistor on P1.3
```

This alone doesn't tell you *which direction* the pin gets pulled — high or
low. That's a separate decision, and it's made by a register you'd expect to
have nothing to do with inputs at all.

## The wrinkle: P1OUT changes meaning on an input pin

Here is the detail that trips almost everyone up the first time: **when a
pin is configured as an input (`P1DIR` bit = 0) and its pull resistor is
enabled (`P1REN` bit = 1), the corresponding bit in `P1OUT` no longer means
"drive high/low." It means "pull up vs. pull down."**

- `P1OUT` bit = 1 → pull the input **up** toward 3.3V when nothing else is
  driving it
- `P1OUT` bit = 0 → pull the input **down** toward 0V when nothing else is
  driving it

This is the *same physical register* you've been using to turn LED1 on and
off. Same address, same bits, same instructions (`bis.b`, `bic.b`). Only its
*interpretation* changes, and that interpretation is decided entirely by
`P1DIR` and `P1REN` for that bit. Nothing about the instruction you write
looks any different — you have to keep straight, from context, which
meaning applies to which pin. Get this wrong and you'll enable the pull
resistor in the wrong direction, and your button will appear to be
permanently "pressed" (or permanently "released," with no way to change
it).

For S2 on P1.3, you want a pull-**up**: released reads high (1), pressed
pulls it low (0) when the switch shorts the pin to ground. That means:

```asm
bic.b   #BTN, &P1DIR     ; P1.3 = input (this is the reset default, but
                         ; write it explicitly — don't rely on defaults)
bis.b   #BTN, &P1REN     ; enable the pull resistor on P1.3
bis.b   #BTN, &P1OUT     ; ...and pull it UP, not down
```

Three registers, three separate decisions, one pin. If you skip the
`P1REN` line, the pull resistor never turns on and `P1OUT`'s bit is
meaningless. If you skip the `P1OUT` line, the pull resistor turns on with
whatever direction happened to be left over from reset (which happens to be
0 → pull-down — the wrong direction for this button).

## Active-low logic: tracing a press by hand

S2's physical wiring means the logic sense is **inverted** relative to what
you might expect intuitively:

| Button state | P1.3 voltage | `P1IN` bit 3 |
|---|---|---|
| Released | pulled to 3.3V by internal pull-up | **1** |
| Pressed | shorted to 0V (ground) by the switch | **0** |

This is called **active-low**: the "active"/"pressed" condition corresponds
to the *lower* voltage and the *lower* bit value, not the higher one. It's
the opposite of LED1, where 1 = on (bright) and 0 = off — with the button,
1 = *not* pressed and 0 = pressed.

Now look at the instruction the CLAUDE.md pattern hands you:

```asm
bit.b   #BTN, &P1IN     ; sets Z=1 if the masked bit(s) are all 0
jz      pressed_target
```

`bit.b` doesn't move any data — it's a test-only instruction. It ANDs the
mask against the register (without writing the result anywhere) and sets
the Zero flag if the AND result is all-zero. So `bit.b #BTN, &P1IN` sets
`Z=1` exactly when bit 3 of `P1IN` is 0 — which, per the table above, is
exactly when the button **is pressed**. `jz pressed_target` therefore
branches to your "pressed" handling code when the button is down. This is
the inverted sense that catches people out: you are testing for "bit is
zero" to detect "button is active." Read it twice before you trust your
instinct here.

Walk the whole cycle through by hand once, slowly:

1. **At rest, button not touched:** pull-up wins, P1.3 = 3.3V, `P1IN` bit 3
   = 1. `bit.b #BTN, &P1IN` ANDs against a 1 bit → non-zero result → `Z=0`.
   `jz` does *not* branch. Correct: nobody is pressing it.
2. **Finger presses S2:** the switch shorts P1.3 to ground, overpowering
   the weak pull-up. P1.3 = 0V, `P1IN` bit 3 = 0. `bit.b #BTN, &P1IN` ANDs
   against a 0 bit → zero result → `Z=1`. `jz` branches. Correct: someone
   is pressing it right now.
3. **Finger releases S2:** the switch opens, the pull-up wins again, P1.3
   returns to 3.3V, `P1IN` bit 3 returns to 1, `Z=0`, `jz` does not branch.
   Back to step 1's state.

Every one of these three reads is instantaneous and independent — `P1IN`
has no memory of what it read last time. That property is exactly why the
polling loop in Tutorial 02 has to sample it repeatedly, and exactly why a
noisy real-world signal (Tutorial 02, again) can make that sampling see
things a clean logical model doesn't predict.

## Reference

SLAU144 (MSP430x2xx Family User's Guide), Chapter 8 — Digital I/O, covers
`PxIN`, `PxOUT`, `PxDIR`, and `PxREN` in full register detail if you want the
authoritative bit-level description beyond what's summarized here.
