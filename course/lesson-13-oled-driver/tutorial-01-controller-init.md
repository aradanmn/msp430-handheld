# Tutorial 01 — Controller Init: Commands, Data, and Reset

## The Chip Behind the Glass

The OLED panel itself has no brains — a separate driver IC (SSD1306,
SSD1325, SSD1309, and relatives are all in the same family) sits between
your MSP430 and the actual pixels. That controller has its own onboard
memory (GDDRAM — Graphic Display Data RAM) that holds the current image,
completely separate from the 512 bytes of RAM on your MSP430. Every pixel
you "draw" is really a write into the controller's GDDRAM over SPI; the
controller continuously refreshes the physical panel from that memory on
its own, with no further help from you.

Two consequences follow immediately:

1. The controller needs to be told, once at startup, how to drive its own
   panel — clock speed, contrast, addressing mode, and so on. Nothing shows
   up until this init sequence runs.
2. Because GDDRAM lives on the controller, not the MSP430, and this
   project's SPI wiring doesn't connect MISO to the OLED at all (Lesson 12),
   you cannot read back what's currently in GDDRAM. Every write is
   write-only. This has a real consequence for pixel-level drawing —
   Tutorial 02 covers it.

## Command Bytes vs. Data Bytes

Every byte you send to the controller is either a **command** (configure
the controller itself — set contrast, change addressing mode, turn the
display on) or **data** (pixel content destined for GDDRAM). The controller
needs to know, for every single byte, which kind it's receiving — and it
does *not* figure this out from the SPI protocol. There's a dedicated pin
for it:

**DC (Data/Command)** — a plain GPIO output, wired to P2.1 in this project.
LOW means "the next byte(s) are a command." HIGH means "the next byte(s)
are data." You set DC before each SPI transaction and leave it there for as
many bytes as that transaction needs.

```
DC = LOW,  CS = LOW  → spi_tx_byte(0xAE)     ; command: display off
DC = HIGH, CS = LOW  → spi_tx_byte(pixel byte) ; data: goes into GDDRAM
```

CS (P2.0) behaves exactly as it did in Lesson 12 — LOW claims the bus for
this device, HIGH releases it. Whether you drop CS between every single
byte or hold it low across a whole multi-byte command depends on what
you're sending; this course holds CS low for the duration of each logical
operation (one command + its argument bytes, or one whole GDDRAM burst) and
raises it in between operations.

## Hardware Reset

Before any commands are sent, the controller needs a hardware reset pulse
on its RST pin (P2.2): drive it LOW for at least the minimum pulse width
your datasheet specifies (comfortably covered by a short software delay —
tens of microseconds is typical, but check your part), then bring it back
HIGH. Skipping this, or reusing a previous power-on state, is a common
source of "it worked yesterday, now it shows garbage" — the controller may
have been left mid-command from a prior session.

```asm
bic.b   #OLED_RST, &P2OUT     ; RST low
; ~short delay
bis.b   #OLED_RST, &P2OUT     ; RST high — controller resets
```

## The Init Sequence — Categories, Not Gospel

Every SSD1306-family controller needs, in some order, commands from roughly
these categories before it will show a correct image:

| Category | Purpose |
|----------|---------|
| Display off | Stop refreshing while you reconfigure everything else |
| Clock/oscillator | Set the internal refresh clock divide ratio |
| Multiplex ratio | Tell the controller how many rows the panel actually has |
| Display offset / start line | Correct for any vertical offset in the panel's wiring |
| Charge pump / VCC | Enable the internal voltage generator that actually drives the OLED pixels |
| Segment remap / COM scan direction | Correct for how the panel glass is oriented relative to the driver IC |
| Contrast | Set brightness |
| Addressing mode | Choose how successive data bytes auto-increment through GDDRAM (Tutorial 02) |
| Display on | Start refreshing the panel from GDDRAM |

**This course will not print a "trust me" hex dump and call it done.** The
SSD1306 datasheet (and Adafruit's widely-published open-source SSD1306
driver, if you want a second reference) lists exact command byte values for
each of these — a very commonly cited example sequence is `0xAE` (display
off) ... `0xD5, 0x80` (clock divide) ... `0xA8, 0x3F` (multiplex, for a
64-row panel) ... `0x8D, 0x14` (enable charge pump) ... `0x81, 0xCF`
(contrast) ... `0xAF` (display on) — but treat any such list, including this
one, as a starting point to verify against your actual controller's
datasheet, not as ground truth. Part revisions and vendors do vary values
like the charge-pump byte or the COM-pins configuration byte. Reading the
"Command Table" or "Command Descriptions" section of your part's datasheet
and matching each command's second-byte encoding against what you intend to
set is part of this lesson, not optional background reading.

## What's Next

Tutorial 02 covers the addressing model these init commands set up, and
walks through what actually happens — byte by byte — when you ask the
controller to light exactly one pixel.
