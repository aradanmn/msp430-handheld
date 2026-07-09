# Tutorial 24.1 — Two Sensors, Two References

## The temperature sensor: a known channel, a precise reference

`msp430g2553-defs.s` already gives you everything needed to read the
internal temperature sensor — it's the pattern this course's earlier
material has been pointing at since Lesson 01's `CLAUDE.md` reference:

```asm
mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0
; wait ~30 µs for the reference to settle, then:
bis.w   #(ENC|ADC10SC), &ADC10CTL0
poll:   bit.w   #ADC10BUSY, &ADC10CTL1
        jnz     poll
        mov.w   &ADC10MEM, R5      ; 10-bit result
```

Two fields here matter more than they might first appear:

- **`INCH_10`** selects channel 10 — the temperature sensor is wired
  internally to the ADC as if it were "pin" 10, even though it isn't an
  actual P1 pin.
- **`SREF_1|REFON`** together mean "generate a stable internal reference
  voltage and measure against that, not against the raw supply rail."
  Turning on that internal reference (`REFON`) isn't instantaneous — it
  takes time to stabilize, which is exactly why the comment says to wait
  roughly 30 µs before triggering the first conversion. Skip that wait, or
  don't wait long enough, and the very first sample after power-up gets
  measured against a reference voltage that hasn't finished settling —
  Exercise 2 asks you to track down exactly this failure mode.

Why does the temperature sensor specifically need a *precise* internal
reference rather than just VCC? Because its output voltage change per
degree Celsius is small — a few millivolts per degree — and the LaunchPad's
3.3 V supply rail isn't a fixed, precisely known voltage in the way an
internally-regulated reference is. Measuring a small, precise signal
against an imprecise or fluctuating supply rail would swamp the actual
temperature information in reference-voltage noise. The temperature
sensor needs the *precision* of the internal reference, not the *range* of
the full supply rail — its output never gets close to either supply rail
anyway.

## The potentiometer: a new channel, the supply rail as reference

A potentiometer wired between VCC and GND, with its wiper tapped into an
ADC-capable pin, has the opposite property: its output *is* the full 0 V to
VCC range, by design — that's what a pot connected this way does. There's
no small signal to protect from reference noise; you want the ADC to read
"turned all the way to one end" as 0 and "turned all the way to the other
end" as the maximum code, and the natural reference for that is the supply
rail itself:

```asm
.equ    SREF_0,     0x0000      ; already in msp430g2553-defs.s
                                ; bits 15-13 = 000 → Vr+ = VCC, Vr- = GND
```

No `REFON`, no internal reference, and — because there's no reference
voltage generator to wait on — no settle delay is needed before the first
conversion. That asymmetry (precise-but-slow-to-stabilize internal
reference for a small signal vs. instant-but-imprecise supply rail for a
full-range signal) is the entire reason this lesson treats the two sensors
side by side instead of just repeating the temperature sensor pattern
twice.

## The gap: there's no `INCH_4`

This course's pin budget puts the potentiometer on **P1.4**, which the ADC
calls channel 4 (`msp430g2553-defs.s`'s own comment above `INCH_10`
documents the field: "Bits 15-12: INCH — input channel"). Only `INCH_10`
is defined in that file, because until this lesson nothing in the course
needed any other channel. You have to build `INCH_4` yourself, from the
same bit-field layout `INCH_10` already follows:

```
INCH occupies bits 15-12 of ADC10CTL1. INCH_10 = 0xA000 because channel 10
in binary is 1010, placed in bits 15-12:

   1010 0000 0000 0000  = 0xA000   (channel 10, bits 15-12 = 1010)

Channel 4 in binary is 0100 — the same field, a different channel number:

   0100 0000 0000 0000  = 0x4000   (channel 4, bits 15-12 = 0100)
```

```asm
; INCH_4 is not defined in msp430g2553-defs.s — only the temperature
; sensor's channel (INCH_10) was needed before this lesson. Bits 15-12 of
; ADC10CTL1 select the channel (see msp430g2553-defs.s's ADC10 comment
; block); channel 4 = 0100 in that field = 0x4000.
.equ    INCH_4,     0x4000
```

Define this `.equ` locally in whatever file reads the potentiometer — it's
a project-specific extension of the shared definitions file, not something
to go add to `msp430g2553-defs.s` itself.

## Why `ADC10AE0`, not `P1SEL`

Every peripheral you've configured so far — UART, SPI — hands a pin over
using `P1SEL`/`P1SEL2`. The ADC is different: it uses its own dedicated
gate, `ADC10AE0` ("analog enable"), to disconnect a pin's ordinary digital
input buffer and connect it to the analog-to-digital converter instead.
`P1SEL` stays at its default (GPIO) value for ADC pins — setting it has no
effect on which pins the ADC samples from, and isn't part of the ADC
configuration at all:

```asm
bis.b   #BIT4, &ADC10AE0      ; disable P1.4's digital buffer, connect it to ADC10
```

`P1DIR` doesn't need to change either — leaving P1.4 at its default input
setting is fine, since `ADC10AE0` already routes the pin away from the
ordinary digital-input path regardless of `P1DIR`'s setting.

## Putting the potentiometer's setup together

```asm
bis.b   #BIT4, &ADC10AE0                             ; P1.4 → analog input
mov.w   #(INCH_4|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
mov.w   #(SREF_0|ADC10SHT_3|ADC10ON), &ADC10CTL0     ; no REFON — AVCC is the reference
bis.w   #(ENC|ADC10SC), &ADC10CTL0                   ; no settle delay needed
poll:   bit.w   #ADC10BUSY, &ADC10CTL1
        jnz     poll
        mov.w   &ADC10MEM, R5
```

Side by side, the only differences from the temperature-sensor sequence
are the channel (`INCH_4` vs. `INCH_10`), the reference (`SREF_0` vs.
`SREF_1|REFON`), the one-time `ADC10AE0` pin gate the temperature sensor
never needs (it isn't a real pin), and the settle delay the temperature
sensor's internal reference requires but the pot's supply-rail reference
doesn't.

## Check your understanding

1. Why does the temperature sensor need `REFON` but the potentiometer
   doesn't?
2. If you wired the potentiometer to P1.3 instead of P1.4, which two
   things in this tutorial's code would need to change, and which would
   stay the same?
3. What would you expect to observe if you left `ADC10AE0`'s `BIT4` bit
   clear while otherwise configuring the pot exactly as shown above?
