# Lesson 12 — SPI with USCI_B0

## What You'll Learn

- What SPI actually is: a synchronous, full-duplex, shift-register-to-shift-register link
- Clock polarity/phase (CPOL/CPHA) and why the OLED and SRAM on this board both want "Mode 0"
- The MSP430's USCI_B0 hardware SPI peripheral: `UCB0CTL0`/`UCB0CTL1`, the configure-in-reset pattern, `UCB0TXBUF`/`UCB0RXBUF`
- Writing a reusable `spi_tx_byte` subroutine
- Chip-select basics — why a shared SPI bus needs one CS line per device

## Hardware for This Lesson

Starting this lesson, wire the OLED to the LaunchPad (see [`wiring/phase-2-oled-display.md`](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/wiring/phase-2-oled-display.md)
for exact pin numbers): SCLK → P1.5, MOSI → P1.7, CS → P2.0, DC → P2.1, RST → P2.2, power from 3.3V.

**Before you flash anything in this lesson:** SPI on this chip shares pins with
LED2. **Remove the LED2 jumper** on the LaunchPad — P1.6 is USCI_B0's MISO line,
and LED2 sitting on that pin will fight the display/SRAM whenever they drive it.

For the example and Exercise 2 in this lesson specifically, you'll also add a
temporary jumper wire from **P1.7 to P1.6** (MOSI → MISO) on the LaunchPad
header — this loops your own transmitted byte back to your own receiver, so
you can prove the SPI peripheral works correctly before trusting it to talk to
a real display. Remove that loopback jumper before Lesson 13.

## How This Connects to the Handheld

Every pixel that ever reaches the OLED, and every byte that ever reaches the
external SRAM (Lesson 25), travels over the same physical bus this lesson
sets up. `hal/spi.s` is the transport layer — it doesn't know or care whether
the bytes it's shipping out are display commands, pixel data, or memory
addresses. That separation of concerns is why `spi_tx_byte` takes a plain
byte and returns a plain byte, nothing more.

## Read First

1. `tutorial-01-spi-protocol.md` — what SPI is, CPOL/CPHA, why "Mode 0"
2. `tutorial-02-usci-b0-master.md` — USCI_B0 registers, `spi_tx_byte`, chip-select basics
3. **Datasheet:** SLAU144 Chapter 16 (USCI — SPI Mode)

## Then

Attempt the exercises before flashing `examples/spi_loopback.s`. The example
is the working reference — study it *after* you've built your own.

## Exercises

See `exercises/README.md`.

## Success Criteria

- [ ] You can explain, without looking it up, what CPOL and CPHA each control
- [ ] You can say why the OLED, the SRAM, and the Flash chip can share one
      SPI bus with only one CS line active at a time
- [ ] `examples/spi_loopback.s` builds, flashes, and lights LED1 (byte
      round-tripped correctly through USCI_B0 and the P1.7→P1.6 jumper)
- [ ] You can explain why `spi_tx_byte` must wait on `UCB0RXIFG`, not just `UCB0TXIFG`, before returning
