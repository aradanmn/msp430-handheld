# Lesson 16 — Shift-Register Input

## Topic

Since Lesson 06 your handheld has read exactly one button: S2 on P1.3. A real
handheld needs eight — a D-pad (Up/Down/Left/Right) plus Select, Start, B,
and A. The MSP430G2553 doesn't have eight spare GPIO pins to spare for this
(most are already claimed by the OLED's SPI bus and control lines). Instead,
Phase 4 wires all eight buttons into a **SN74HC165N parallel-in,
serial-out shift register**, and you read all eight states in a single SPI
transaction.

This lesson is entirely about that one chip and the protocol it needs:
latch the parallel inputs, then clock them out serially.

## Learning Objectives

- Explain why a parallel-load shift register needs a **latch pulse** before
  you can shift its contents out
- Wire and drive the SN74HC165N's SH/LD (PL), CLK, and QH pins
- Reuse USCI_B0 SPI (already covered in Lesson 12) in a new role: generating
  clock pulses to shift data *in* from a device that has no MOSI/SIMO input
  of its own
- Translate the chip's raw (active-low) output byte into a readable,
  active-high button bitmap
- Understand why sharing one SPI clock/data bus between the OLED and the
  shift register is safe, as long as only one device is addressed at a time

## What You'll Build

An example program that latches and reads the shift register once per
polling pass and lights LED1 whenever a specific button is held — a
self-test that confirms your wiring and bit order are correct before you
build the real thing.

## Game Connection

This lesson's milestone extends `handheld/hal/input.s` (built in Lesson 07)
so its raw-sample step reads all eight shift-register bits instead of the
single onboard button. Every debounce and edge-detection routine you
already wrote keeps working — it never cared how many bits wide "the
button state" was, only that `1 = pressed`. From here on, your game reads
a full D-pad + four action buttons in one shot, once per frame.

## Hardware

See [`wiring/phase-3-buttons-shift-register.md`](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/wiring/phase-3-buttons-shift-register.md) for the full parts
list and wiring diagram. Summary:

| SN74HC165N Pin | Function | Connects to |
|---|---|---|
| SH/LD (PL) | Parallel load, active LOW | P2.3 (GPIO) |
| CLK | Shift clock | P1.5 (USCI_B0 SPI clock — shared with the OLED) |
| QH | Serial data out | P1.6 (USCI_B0 MISO — **remove the LED2 jumper**) |
| SER | Serial data in | GND (no daisy-chained second register) |
| CLK INH | Clock inhibit | GND (always enabled) |
| A–H | Parallel inputs | One button + pull-up each |

Bit mapping once you've read and inverted the byte (`1` = pressed):

```
bit7 = Up      bit6 = Down   bit5 = Left    bit4 = Right
bit3 = Select  bit2 = Start  bit1 = B       bit0 = A
```

## Datasheet References

- **SLAU144, Ch 16** — USCI SPI mode, master configuration, MSB-first framing
- SN74HC165N datasheet (any distributor copy) — SH/LD and CLK timing,
  why SER/CLK INH are tied off the way they are

## Success Criteria

- [ ] `examples/shiftreg_read.s` builds and flashes without errors
- [ ] LED1 turns on only while the mapped button is held, and off the
      instant it's released — no lag, no stuck-on state
- [ ] Holding a *different* button does **not** light LED1 (confirms bit
      mapping, not just "any press")
- [ ] You can explain, in one sentence, why the PL pulse has to happen
      *before* the SPI transfer that reads the byte, not after
- [ ] You can explain why the dummy `0xFF` written to `UCB0TXBUF` is
      necessary even though its value is never used by the shift register
