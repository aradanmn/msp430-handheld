# Lesson 12 Exercises

Read both tutorials first. Wire the OLED per `docs/hardware/phase-2-oled-display.md`,
remove the LED2 jumper, and add a temporary P1.7 -> P1.6 loopback jumper before
starting Exercise 1. Flash `examples/spi_loopback.s` only *after* you've
attempted your own exercises — it's the reference, not the starting point.

---

## Exercise 1 — Explore: Bit-Bang SPI

**Requires:** Lessons 01–11 + Tutorial 01 (SPI protocol, Mode 0, MSB-first)

**File:** `ex1/ex1.s`

Before you let USCI_B0 do the work, build one SPI transaction entirely out of
plain GPIO. Using P1.5 as a manually-toggled clock line and P1.7 as a
manually-toggled data line (both configured as ordinary outputs — no `P1SEL`
involved), transmit the byte `0xA5` one bit at a time, MSB first, obeying
Mode 0 timing (clock idles LOW, data line is set up *before* the clock's
rising edge). To confirm the bits actually went out correctly, read them
back on P1.6 (configured as an ordinary input) using the same P1.7 -> P1.6
jumper from the lesson setup, sampling P1.6 at the same point in each clock
cycle you'd expect the far end to sample it.

Compare the byte you reconstructed from your own bit-banging against `0xA5`.

**What to look up:** SLAU144 Ch. 16's timing diagrams for CPOL=0/CPHA=0 —
they show exactly when data must be valid relative to each clock edge. This
is the same timing USCI_B0 will generate for you starting in the example —
here you're generating it yourself, one instruction at a time.

**Success criteria:** LED1 lights if the byte you bit-banged out and read
back bit-for-bit equals `0xA5`; stays off otherwise. No `UCB0`-anything
register may appear in this file — GPIO only.

---

## Exercise 2 — Challenge: USCI_B0 Loopback Bug

**Requires:** Lessons 01–11 + Tutorial 02 (USCI_B0 configuration, `spi_tx_byte`)

**File:** `ex2/ex2.s`

This file configures USCI_B0 and runs the same loopback test as the lesson
example — same jumper (P1.7 -> P1.6), same test byte, same LED1 pass/fail
signal. Build it, flash it, and jumper it up exactly as described in this
lesson's `README.md`.

**Observed behavior:** LED1 never lights. Not intermittently — every single
time, on every reset, LED1 stays off.

The wiring is correct (it's the identical physical setup the working example
uses). Find what's different in the code.

**Success criteria:** LED1 lights on reset, matching the example's behavior.
State in a comment which register(s) you had to change and why — but do not
leave the broken configuration commented out for reference; leave the file
in the state that actually works.

---

## Exercise 3 — Milestone: `handheld/hal/spi.s`

**Requires:** Lessons 01–12 + Exercises 1–2

**What to create:** `handheld/hal/spi.s`

See `ex3/README.md` for the full spec.

**Build & test:** `cd handheld && make && make flash`

**Success criteria:** compiles cleanly as part of the handheld build;
`spi_tx_byte` round-trips a byte correctly with the P1.7 -> P1.6 jumper in place.
