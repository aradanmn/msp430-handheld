# Tutorial 01 — Parallel-Load Shift Registers

## The problem eight buttons create

A single button is easy: dedicate a pin, enable its pull-up, read `P1IN`.
Eight buttons the same way would need eight GPIO pins. You don't have eight
free ones — P1.1/P1.2 are UART, P1.5/P1.6/P1.7 are SPI (shared with the
OLED), P2.0–P2.2 are OLED chip-select/DC/reset. Something has to give.

The SN74HC165N solves this by trading pins for time: it has eight parallel
inputs (A–H), but only *one* serial output (QH). You sample all eight
button pins in parallel, at the same instant, into eight internal
flip-flops. Then you shift those eight captured values out through QH one
bit at a time, clocked by CLK. Reading the chip costs you three pins
(PL, CLK, QH) no matter how many buttons are wired to it.

## Why you need a latch pulse

The chip has two distinct modes, selected by one pin (SH/LD, wired here to
P2.3, which the datasheet abbreviates PL):

- **Parallel load** (PL LOW): the eight internal flip-flops continuously
  track whatever voltage is on pins A–H, live, right now.
- **Shift** (PL HIGH): the flip-flops stop tracking A–H and instead form a
  serial shift register — each CLK pulse moves QH's bit out and pulls the
  next bit up the chain.

If you forget the load pulse and just start clocking, you shift out
whatever happened to be latched from the *last* load — stale data. If you
never bring PL back HIGH, the chip never leaves parallel-load mode and QH
just mirrors pin H directly; you never see the other seven buttons at all.

The sequence is always: **pulse PL LOW then HIGH (snapshot all 8 pins),
then clock 8 bits out while PL stays HIGH.**

```asm
bic.b   #SR_PL, &P2OUT      ; PL low  — every flip-flop now tracks A-H live
nop
nop
bis.b   #SR_PL, &P2OUT      ; PL high — snapshot is frozen, ready to shift
```

The two `nop`s aren't load-bearing on real silicon at 1 MHz (the chip's
minimum pulse width is nanoseconds; a single MSP430 instruction takes
microseconds), but get in the habit of giving hardware a moment to react
whenever a datasheet quotes a minimum pulse width — it costs you two
cycles and saves you a debugging session on a chip that's more finicky.

## Why an SPI peripheral can drive a chip that has no MOSI input

USCI_B0 is a full-duplex SPI master: every time it clocks a bit out on
MOSI, it simultaneously clocks a bit in on MISO. The SN74HC165N only
*uses* the MISO half — its SER (serial-in) pin is grounded, so whatever
byte you write to `UCB0TXBUF` is thrown away by the chip. But you still
have to write **something** to `UCB0TXBUF`, because writing to TXBUF is
what tells the USCI hardware to start toggling CLK. No write, no clock
pulses, no shifted-out data.

```asm
mov.b   #0xFF, &UCB0TXBUF   ; the 0xFF is irrelevant — this line's real
                              ; job is "generate 8 clock edges on P1.5"
```

That's the whole reason the value is a placeholder — the shift register
class of device is fundamentally receive-only from the MSP430's point of
view, but the SPI peripheral has no receive-only mode, so you drive a
throwaway transmit to get the clock you need.

## Trace-through: pressing "Up" alone

Say only Up (mapped to pin A per the wiring table) is held. After the PL
pulse, the eight flip-flops hold: A=0 (pressed, active-low), B–H=1
(released). QH shifts out in the order documented for this wiring —
resulting, after all 8 clocks, in the raw byte `0111 1111` (`0x7F`) landing
in `UCB0RXBUF` — bit 7 (mapped to Up/pin A) is the only bit that reads 0.

That's still "backwards" from a programmer's point of view: 0 means
pressed. Tutorial 02 covers cleaning that up.
