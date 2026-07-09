# Tutorial 24.2 — From a Raw 10-Bit Code to a Usable Value

## The result is just a number 0–1023

Whatever channel you read, `ADC10MEM` holds the same kind of thing: a
10-bit unsigned number from 0 to 1023, where 0 represents the low end of
whatever reference range you configured and 1023 represents the high end.
By itself, "raw = 614" doesn't mean anything to a game or a thermometer
display — it has to be mapped into units the rest of your program actually
uses.

## Temperature sensor: raw code to °C

This course's reference material gives the conversion formula directly:

```
T°C ≈ (raw − 673) / 4 + 25
```

Implementing this with instructions you already know: `sub.w` for the
subtraction, then two `rra.w` (arithmetic right shift) instructions in a
row for the divide-by-4 (each `rra.w` halves the value while preserving
its sign, so two of them divide by 4), then `add.w` for the final offset:

```asm
; R5 = raw ADC result (0-1023)
sub.w   #673, R5      ; R5 = raw - 673 (can go negative in a cold room)
rra.w   R5             ; R5 = R5 / 2 (sign-preserving shift)
rra.w   R5             ; R5 = R5 / 2 again → net /4
add.w   #25, R5       ; R5 = approx T in °C
```

Because the intermediate value can legitimately go negative before the
final `+25` (a raw reading below 673 subtracts down past zero), `rra.w` —
not a plain logical shift — matters here: it shifts the sign bit down into
the result instead of always shifting in a 0, so the arithmetic still
comes out approximately correct for readings on the cold side of the
673 raw-code crossover point.

## Potentiometer: raw code to a small number of discrete steps

A game parameter like "drop speed" doesn't need 1024 distinct levels — a
handful of discrete steps (say, 4 or 8) is both easier to reason about and
easier to display. The standard technique for collapsing a wide range down
to a small number of buckets is exactly the same right-shift idea, just
without the sign-preservation concern (the raw ADC result is always
non-negative, so a plain `rra.w` or a few of them work fine here — there's
no risk of shifting in a stray sign bit from a negative value that was
never possible in the first place):

```asm
; R5 = raw ADC result (0-1023)
rra.w   R5             ; /2  → 0-511
rra.w   R5             ; /4  → 0-255
rra.w   R5             ; /8  → 0-127
rra.w   R5             ; /16 → 0-63
rra.w   R5             ; /32 → 0-31
rra.w   R5             ; /64 → 0-15
rra.w   R5             ; /128 → 0-7   (8 discrete steps: 0-7)
```

Each shift halves the range of possible output values. Choosing how many
shifts to apply is a direct trade: more shifts means fewer, coarser steps
(easier to land exactly on the one you want by turning the pot, but less
granular control); fewer shifts means more steps (finer control, but a
tiny pot movement might not visibly change anything if what you're driving
— like a blink rate — can't distinguish adjacent raw values anyway).
Exercise 1 asks you to pick a shift count that makes the resulting blink
rate change *visibly* as you turn the pot from one end to the other, which
means picking a bucket count small enough that each step is an obviously
different blink speed.

## Check your understanding

1. Why does the temperature conversion need `rra.w` specifically (as
   opposed to a plain logical shift), while the potentiometer's
   bucket-reduction doesn't strictly need to care about sign?
2. If you only right-shifted the potentiometer reading twice instead of
   seven times, how many distinct output values would be possible, and
   would that likely be too many or too few for a visibly-steppy blink
   rate?
3. A raw temperature-sensor reading of exactly 673 gives what computed
   `T°C` value, using the formula above? Show the `.equ`-style arithmetic,
   not just the final number.
