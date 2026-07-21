# Handheld — Hardware

Hardware design for the MSP430G2553 handheld game console: parts, wiring,
breadboard layout, KiCad schematic, and the engineering design history.

This directory is the single source of truth for the **hardware side** of the
project. The firmware/course lives alongside it in `course/` and `handheld/`.

## Components

| Component | Part | Purpose |
|-----------|------|---------|
| MCU | MSP430G2553 (LaunchPad MSP-EXP430G2) | Main controller |
| Display | SSD1325 2.7″ OLED, 128×64 grayscale SPI | Video output |
| SRAM | 23LC1024-I/P (128 KB SPI, DIP-8) | Off-chip framebuffer backing store |
| Flash | W25Q128 (16 MB SPI, DIP breakout) | Asset / level storage |
| Shift register | SN74HC165N (DIP-16) | 8-button input over the SPI bus |
| Audio amp | LM386N-1 (DIP-8) | PWM → speaker |
| Speaker | 8 Ω 0.5 W | Audio output |
| LiPo charger | Adafruit 4410 (USB-C) | Battery charging |
| Battery | Adafruit 2011 (3.7 V LiPo, JST-PH) | Power |

Full ordering detail is in the BOM: [`../bom-structured.md`](../bom-structured.md),
[`../bom-flat.md`](../bom-flat.md), and [`../bom-order.csv`](../bom-order.csv).

## Bus & pin map

All SPI peripherals share the MSP430's **USCI_B0** bus and are selected by
individual chip-select lines (only one CS low at a time):

| Signal | MSP430 pin |
|--------|-----------|
| SCLK | P1.5 (UCB0CLK) |
| MOSI | P1.7 (UCB0SIMO) |
| MISO | P1.6 (UCB0SOMI) |

Chip-selects and control lines are assigned per phase — see the phase docs
below, and the authoritative rev 5.0 assignments in the schematic
`title_block` of
[`schematic/msp430_gameboy.kicad_sch`](schematic/msp430_gameboy.kicad_sch).

## Build phases

Hardware is added incrementally as the course progresses:

- [`phase-1-launchpad-only.md`](phase-1-launchpad-only.md) — bare LaunchPad (Lessons 1–5)
- [`phase-2-oled-display.md`](phase-2-oled-display.md) — OLED + SRAM + Flash on the SPI bus
- [`phase-3-buttons-shift-register.md`](phase-3-buttons-shift-register.md) — 8-button SN74HC165N input
- [`phase-4-audio.md`](phase-4-audio.md) — LM386 amplifier + speaker

## Breadboard

Elenco 9440 (4-panel) prototype layout, MSP430 centred with peripherals
around the outside:

- [`breadboard/breadboard_guide.md`](breadboard/breadboard_guide.md) — wiring reference
- [`breadboard/breadboard_layout.html`](breadboard/breadboard_layout.html) — SVG visual

## Schematic

The KiCad 9 schematic is generated programmatically rather than drawn by hand.

```bash
python3 scripts/gen_kicad7.py     # writes schematic/msp430_gameboy.kicad_sch
```

Optional validation: `pip install kiutils`.

- Current: [`schematic/msp430_gameboy.kicad_sch`](schematic/msp430_gameboy.kicad_sch) — rev 5.0 (adds OLED CS/DC/RST, SRAM, Flash)
- Generator: [`scripts/gen_kicad7.py`](scripts/gen_kicad7.py) (current), `scripts/gen_kicad6.py` (prior)
- Timestamped snapshots kept alongside the current file for history.

## Design history

Versioned engineering notes and session logs from the breadboard / rev 4.0
schematic bring-up. These record the KiCad 9 format lessons, the grid-alignment
debugging that fixed "nothing connected", component-position tables, and net
lists. Migrated from the former standalone `handheld-msp430` repo and preserved
verbatim as design history.

- [`notes/`](notes/) — versioned engineering notes (`yyyymmdd_HHmmss.md`) + `SESSION_NOTES.md`
- [`logs/`](logs/) — session conversation logs

## Status

- [x] BOM (DigiKey, ~$53 core)
- [x] Breadboard layout (Elenco 9440, 4-panel)
- [x] KiCad 9 schematic — rev 5.0 (grid-aligned, connections verified)
- [ ] PCB layout
- [ ] Enclosure
