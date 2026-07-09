# Tutorial 02 — Bit Mapping, Inversion, and a Shared SPI Bus

## Active-low in, active-high out

Every button in this design pulls its shift-register input pin to GND when
pressed, through a pull-up resistor that holds it at 3.3V when released
(the same active-low convention you already used for S2 in Lesson 06). So
the raw byte you clock in has `0` for "pressed" and `1` for "released" —
exactly backwards from how you want to *think* about button state in
software.

The fix is one instruction, applied once, right after the read:

```asm
mov.b   &UCB0RXBUF, R12
xor.b   #0xFF, R12          ; flips every bit: 0<->1
```

`XOR`-ing against `0xFF` toggles every bit in the byte. Any bit that was 0
(pressed) becomes 1; any bit that was 1 (released) becomes 0. After this
one line, `R12` reads `1 = pressed` for all eight buttons — the same
convention your Lesson 07 debounce logic already expects. Do the inversion
once, at the boundary where raw hardware data enters your code, and
everything downstream never has to think about polarity again.

## The bit-to-button table

This wiring's mapping (see `docs/hardware/phase-3-buttons-shift-register.md`
for the full pin table) is:

```
bit7 = Up      bit6 = Down   bit5 = Left    bit4 = Right
bit3 = Select  bit2 = Start  bit1 = B       bit0 = A
```

Testing one button is a `bit.b #mask, R12` against the matching single-bit
constant, exactly like testing `P1IN` for S2 in Lesson 06 — the only
difference is the bit now comes from a register holding a whole byte's
worth of buttons instead of a live GPIO pin.

## Debounce didn't go anywhere

Nothing about switching to a shift register removes contact bounce — these
are still mechanical tactile buttons. Your Lesson 07 debounce/edge-detection
logic still needs to run on every one of these eight bits, independently
(a bounce on the "A" button shouldn't be confused with a bounce on "Up").
What changes is only the **source** of the raw sample: instead of one bit
read from `P1IN`, you now have eight bits read from one SPI transaction.
Everything built on top — press detection, release detection, "was this
just pressed this frame" edge logic — keeps working unmodified as long as
it treats its input as an 8-bit bitmap instead of a single bit.

## Sharing CLK and MOSI with the OLED

The OLED (Lesson 12–13) and the SN74HC165N both sit on the same physical
wires: P1.5 (clock) and P1.7 (MOSI/SIMO — unused by the shift register,
but still shared electrically). Two devices on one clock line is normal
for SPI; what keeps them from interfering is that **only one device
listens to the clock at a time**:

- The OLED only pays attention to CLK while its chip-select pin (P2.0) is
  driven active.
- The shift register has no chip-select at all — it always shifts on
  every CLK edge once PL has gone HIGH. But since SER is tied to GND (no
  daisy-chained second chip) and nothing reads its QH output except when
  *you* choose to pulse PL and issue the read, unrelated SPI traffic aimed
  at the OLED still clocks the 165's internal register.

That last point matters: if you send a byte to the OLED without first
deasserting the 165's attention (i.e., without controlling *when* you
choose to trust QH's data), you can shift stale bits through the 165
between reads. In practice this is harmless as long as you always issue a
fresh PL pulse immediately before every button read — you never rely on
what's shifted out except right after a load, so incidental clocking from
OLED traffic in between reads doesn't corrupt anything you actually use.
This is why the read routine always starts with its own PL pulse rather
than assuming the register still holds whatever was last loaded.

## What's next

Lesson 17 leaves input behind and starts on output again — but this time
audio: PWM tone generation using the *second* independent Timer_A
peripheral on this chip, driving the speaker through the LM386 amp.
