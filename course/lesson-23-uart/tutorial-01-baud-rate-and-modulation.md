# Tutorial 23.1 — Baud Rate and Modulation

## What a baud rate actually is

UART has no clock wire — unlike SPI, both ends must independently agree on
how long each bit lasts and then just trust the clock. 9600 baud means the
transmitter (and the receiver) treat each bit as lasting:

```
bit period = 1 / 9600 s ≈ 104.17 µs
```

Both ends only work if they're both running that same bit period closely
enough that, over the 8–10 bits of a single byte, their clocks haven't
drifted apart by more than about half a bit. USCI_A0 doesn't measure time in
microseconds — it counts SMCLK edges. So the real question isn't "how many
microseconds is a bit," it's "how many SMCLK cycles is a bit."

## From bit period to a cycle count

At a calibrated SMCLK of 1 MHz (1,000,000 cycles per second), the number of
SMCLK cycles in one 9600-baud bit period is:

```
cycles per bit = SMCLK_HZ / baud rate = 1,000,000 / 9600 ≈ 104.1666...
```

USCI_A0's baud-rate generator counts down `UCA0BR0`/`UCA0BR1` (a 16-bit
divisor, low byte in `UCA0BR0`) SMCLK cycles per bit. A divisor register only
holds whole numbers — there is no way to load "104.1666...". You have to
pick an integer, and the closest one is 104:

```asm
mov.b   #104, &UCA0BR0             ; 1,000,000 / 104 ≈ 9615 baud
mov.b   #0,   &UCA0BR1             ; high byte of the 16-bit divisor = 0
```

Loading 104 doesn't give you *exactly* 9600 baud — it gives you a UART
clock of 1,000,000 / 104 ≈ 9615 baud, about 0.16% fast. Over a single byte
that error is invisible. Over many bytes in a row with no re-synchronization
it would eventually accumulate into a misread bit — except UART
re-synchronizes on every byte's start bit, so this particular residual
error is small enough to never matter in practice at this baud rate. That
said, USCI_A0 has a second mechanism specifically for shaving down exactly
this kind of leftover fractional error.

## What the modulation bits are for

`UCA0MCTL` doesn't change the *whole-cycle* part of the baud rate divisor —
that's still fixed at 104 SMCLK cycles per bit, set by `UCA0BR0`/`UCA0BR1`.
What it does is correct the *fractional remainder* (the ".1666..." left over
above) by occasionally lengthening or shortening individual bit samples
according to a fixed pattern, spread out over a run of bits rather than
dumped onto any single one. Think of it as the same idea as a leap year:
you can't have a fractional day, so instead of drifting the calendar by a
quarter-day every year, you add one whole extra day every fourth year and
call it even. `UCA0MCTL`'s modulation bits do the equivalent trick per-bit
instead of per-year, nudging the *sampling point* within selected bit
periods so that, averaged over many bits, the effective baud rate sits
closer to the true 9600 than the plain 104-cycle divisor alone would give
you.

You don't need to hand-derive which specific pattern `0x02` encodes to use
it correctly — TI's own baud-rate tables (SLAU144 Ch. 15) list the
`UCA0BR0`/`UCA0MCTL` pairs for common baud rates at common SMCLK
frequencies, and `0x02` is the documented pairing for 9600 baud at 1 MHz.
What matters here is the *category* of problem it solves: an integer
divisor alone gets you close to a target baud rate, and the modulation bits
get you closer still, without requiring a non-integer divisor the hardware
can't represent. This is also why `picocom -b 9600` — which is expecting a
receiver clocked at true 9600 baud — works reliably against a transmitter
running at the corrected ≈9615: the residual error after modulation is
small enough that both ends still agree on every bit, every byte, every
time.

## The full sequence

Putting the divisor and the modulation correction together, alongside the
clock-source and pin-mux setup:

```asm
bis.b   #(UART_RX|UART_TX), &P1SEL     ; P1.1/P1.2 → USCI_A0 peripheral function
bis.b   #(UART_RX|UART_TX), &P1SEL2
bis.b   #UCSWRST, &UCA0CTL1            ; hold USCI_A0 in reset while configuring
mov.b   #UCSSEL_2, &UCA0CTL1           ; clock source = SMCLK
mov.b   #104, &UCA0BR0                 ; 1 MHz / 104 ≈ 9615 baud
mov.b   #0, &UCA0BR1
mov.b   #0x02, &UCA0MCTL               ; modulation correction for 9600 @ 1 MHz
bic.b   #UCSWRST, &UCA0CTL1            ; release reset — USCI_A0 now running
```

Notice the shape: like every other USCI peripheral you've configured
(SPI in Lesson 12), you hold `UCSWRST` set while you write the clock source,
divisor, and modulation fields, and only clear it once every field is in
place. Clearing it early — before the divisor is loaded — would start the
baud-rate generator counting against whatever divisor happened to be there
first, which is exactly the kind of bug Lesson 12's SPI exercise had you
hunt for in a different register.

## Check your understanding

1. Why is 104 the closest integer divisor for 9600 baud at 1 MHz SMCLK, and
   what is the actual baud rate you get if you stop at the integer divisor
   and never touch `UCA0MCTL`?
2. In your own words, what category of timing error does `UCA0MCTL`
   correct — and why can't you get that same correction just by picking a
   different integer divisor?
3. If SMCLK were 8 MHz instead of 1 MHz, would `UCA0BR0 = 104` still target
   9600 baud? What would you need to look up or recompute?
