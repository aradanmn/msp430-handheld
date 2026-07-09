# Exercise 3 — Milestone: `handheld/hal/spi.s`

**Requires:** Lessons 01–12 + Exercises 1–2

This milestone gives the handheld project its SPI transport layer — the
plumbing every later display (Lesson 13+) and external-memory module
(Lesson 25) sends bytes through.

## What to Create

```
handheld/hal/spi.s   ← new file (module doesn't exist yet)
```

## Behavioral Spec

- `spi_init` — configure USCI_B0 as an SPI master: Mode 0 (CPOL=0, CPHA=0),
  MSB-first, clocked from SMCLK. When this returns, P1.5/P1.6/P1.7 must be
  configured for the USCI_B0 peripheral function, not left as GPIO.
- `spi_tx_byte` — transmit one byte and return the byte simultaneously
  shifted in on MISO. A caller that only cares about sending (e.g. writing
  OLED commands) is free to ignore the returned byte.
- This module owns **no chip-select or DC pin**. CS/DC are per-device
  concerns — the OLED driver you write in Lesson 13 manages its own CS and
  DC pins and calls into this module only for the byte-level transfer.

## Public Interface

| Function | Arguments | Returns |
|----------|-----------|---------|
| `spi_init` | — | — |
| `spi_tx_byte` | R12 = byte to transmit | R12 = byte received |

## Build & Test

```sh
cd handheld
make && make flash
```

You'll need to wire `spi_init` into your init sequence and make
`spi_tx_byte` reachable from wherever you test it — see the Composition
Model in `CLAUDE.md` for how modules are pulled into `main.s`.

**Success criteria:**
- `handheld/hal/spi.s` compiles cleanly as part of the handheld build
- With a P1.7 -> P1.6 jumper in place, a byte sent through `spi_tx_byte`
  comes back unchanged
- Register usage follows `handheld/registers.md` — R12–R15 as scratch,
  no R4–R11 touched
