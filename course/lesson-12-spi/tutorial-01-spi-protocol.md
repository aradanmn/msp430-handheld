# Tutorial 01 — The SPI Protocol

## Why Not Just Use More GPIO Pins?

Up through Lesson 11 you've talked to the outside world one bit at a time —
a button pin here, an LED pin there. A 128×64 OLED needs over a thousand
bytes of picture data delivered to it, over and over, dozens of times a
second once the game is running. Wiring one MCU pin per display pixel isn't
an option — the chip only has 16 usable GPIO pins total. You need a way to
send a whole byte down **one** data line, one bit at a time, fast, with both
sides agreeing exactly when each bit is valid.

That's what SPI (Serial Peripheral Interface) is for.

## The Shift-Register Model

Picture two 8-bit shift registers — one inside the MSP430, one inside the
OLED controller — wired together in a ring:

```
   MSP430                          OLED controller
  ┌──────────┐      MOSI          ┌──────────┐
  │  shift    │ ───────────────►  │  shift    │
  │  register │                   │  register │
  │  (TX)     │ ◄─────────────── │  (RX/TX)  │
  └──────────┘      MISO          └──────────┘
        │                                │
        └──────────  SCLK  ──────────────┘
              (MSP430 drives this — it's the master)
```

Every clock pulse, **both** shift registers shift out their top bit on their
output line and shift in a new bit on their input line — simultaneously. After
8 clock pulses, the two registers have completely swapped contents. This is
why SPI is called **full-duplex**: data moves in both directions on every
transaction, whether or not you care about what comes back. When you only
care about sending (like writing OLED commands), you still receive a byte —
you just ignore it. When you only care about receiving (like reading an SRAM
address's contents), you still have to clock out a byte — often a dummy 0x00
— to drive the clock that shifts the response out.

There is no separate "start" or "stop" bit like UART has (Lesson 23). SPI is
**synchronous**: the clock line (SCLK) is the timing reference. As long as
both sides agree on the clock, there's no ambiguity about when a bit is valid.

## The Four Wires

| Signal | Direction (master's view) | Meaning |
|--------|---------------------------|---------|
| **SCLK** | MSP430 → device | Clock — MSP430 (master) always drives this |
| **MOSI** | MSP430 → device | Master Out, Slave In |
| **MISO** | device → MSP430 | Master In, Slave Out |
| **CS**   | MSP430 → device | Chip Select, active LOW — "you're being addressed" |

Every device on the bus shares SCLK, MOSI, and MISO. **CS is per-device** —
each SPI chip gets its own CS pin from the MSP430, and only one may be
pulled LOW at a time. Whichever device sees its own CS LOW is the only one
listening to MOSI/SCLK and driving MISO; every other device on the bus keeps
its MISO output in a high-impedance ("don't care") state.

Our OLED only needs MOSI (it's write-only from the MCU's perspective — the
controller never talks back), so its physical wiring in this project skips
MISO. But the USCI_B0 peripheral itself is still full-duplex internally,
which matters for the loopback test later in this lesson: the SRAM chip
(Lesson 25) *does* use MISO, on the same P1.6 pin, so USCI_B0's RX path has to
work correctly even though the OLED never exercises it.

## Clock Polarity and Phase — the Four "Modes"

Two independent settings determine exactly when data is considered valid
relative to the clock edge:

- **CPOL** (clock polarity) — does SCLK idle LOW (0) or HIGH (1) between
  transactions?
- **CPHA** (clock phase) — is data sampled on the clock's *first* edge after
  CS goes low, or its *second*?

Combined, these give four "SPI modes," numbered 0–3:

| Mode | CPOL | CPHA | Idle clock | Data sampled on |
|------|------|------|------------|------------------|
| 0 | 0 | 0 | LOW | first (rising) edge |
| 1 | 0 | 1 | LOW | second (falling) edge |
| 2 | 1 | 0 | HIGH | first (falling) edge |
| 3 | 1 | 1 | HIGH | second (rising) edge |

**Both the OLED and the 23LC1024 SRAM in this project use Mode 0** — clock
idles low, data is valid on the rising edge. That's the only mode this course
configures. If you ever wire up a part that insists on a different mode,
its datasheet will say so explicitly under "SPI timing" or "electrical
characteristics" — it's device-specific, not something SPI itself mandates.

## MSB-First

One more convention to settle before two devices can talk: which end of the
byte goes out first? Nearly every SPI display and memory chip you'll
encounter — including both parts in this project — send the **most
significant bit first**. USCI_B0 has a `UCMSB` bit for this; we'll set it in
Tutorial 02.

## Chip Select, in Practice

CS isn't part of the SPI clocking scheme at all — it's a plain GPIO output
you control by hand around each transaction:

```
CS   → LOW           (address this device)
... clock out N bytes over SCLK/MOSI/MISO ...
CS   → HIGH           (release the bus)
```

Holding CS low across multiple bytes tells the device "this is one
transaction" — useful when a command needs a multi-byte payload (an OLED
column-address command, for instance, is three bytes: the command byte plus
two argument bytes, all under one CS-low window). Toggling CS high between
every single byte tells the device "these are separate transactions." Which
one you need depends on the device's datasheet — we'll apply this concretely
to the OLED's command/data protocol in Lesson 13.

## What's Next

Tutorial 02 configures USCI_B0 — the MSP430's hardware SPI peripheral — to
actually generate this Mode-0, MSB-first waveform, and builds a `spi_tx_byte`
subroutine you'll reuse for the rest of the course.
