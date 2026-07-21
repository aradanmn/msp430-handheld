# MSP430G2553 Handheld Tetris — Course Roadmap

Build a Game Boy-style handheld running Tetris, one lesson at a time. Every lesson teaches a new MSP430 concept and adds a working piece of the game or its hardware.

**Target hardware** (assembled progressively on a breadboard):

| Component | Part | ~Cost |
|-----------|------|-------|
| MCU | MSP-EXP430G2 LaunchPad (MSP430G2553) | ~$10 |
| Display | SSD1306/SSD1309 OLED SPI (see [the hardware repo's BOM](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/bom-flat.md) for exact part) | ~$4–50 |
| Buttons | SN74HC165N 8-bit parallel-in shift register × 1 | ~$1 |
| Audio | LM386N-1 audio amp + 8Ω speaker | ~$3 |
| Power | Adafruit 4410 USB-C LiPo charger + 3.7V 2Ah LiPo | ~$15 |
| Passives | Breadboard, resistors, caps, diodes | ~$5 |

This roadmap and `CLAUDE.md`'s Course Map are kept in sync — always the same 26 lessons, same numbering. If you ever see them disagree, that's a bug; `CLAUDE.md` is what Claude reads for lesson-writing/grading context, this file is the human-facing overview.

---

## Phase 1 — Assembly Foundations (Lessons 1–7)
*Hardware: LaunchPad only (LEDs + onboard button)*

**Lesson 01 — Architecture & Toolchain**
- MSP430G2553 memory map, register file, status register
- Toolchain: msp430-elf-gcc, mspdebug, Makefile workflow
- Hello world: blink LED1 (P1.0) at 1 Hz
- *Game connection:* understand the canvas we'll draw on

**Lesson 02 — Instruction Set & Addressing Modes**
- MOV, ADD, SUB, AND, OR, BIC, BIS, BIT, XOR, CMP
- Register, indexed, indirect, immediate, symbolic addressing
- *Game connection:* the vocabulary every later lesson builds on

**Lesson 03 — GPIO Output & Bit Idioms**
- Port direction, output registers, toggle trick
- Multi-LED patterns, bit-manipulation idioms
- *Game connection:* represent game states with LED patterns (start, game-over flash)

**Lesson 04 — Delays, Status Flags & the Constant Generator**
- Software delay loops, cycle counting
- SR flags (Z/C/N/V), what clobbers them, R3 constant-generator encoding
- *Game connection:* precise timing is the backbone of every game tick

**Lesson 05 — Subroutines & the Stack**
- CALL/RET, stack pointer mechanics, frame layout
- R12–R15 argument-passing convention, PUSH/POPM
- *Game connection:* modular game functions — move_piece, draw_board, etc.

**Lesson 06 — GPIO Input & Polling**
- Input registers, internal pull-ups (P1REN)
- Active-low button logic, polling loop, onboard S2 button (P1.3)
- *Game connection:* "press button to start" → triggers game start later

**Lesson 07 — Debouncing & Edge Detection**
- Software debounce (tick-based, not delay-based), press/release/held edges
- *Game connection:* the input system every later lesson depends on
- **Milestone:** `handheld/hal/input.s`

---

## Phase 2 — Timing & Interrupts (Lessons 8–11)
*Hardware: LaunchPad only*

**Lesson 08 — Clock System**
- DCO calibration to 1 MHz and 8 MHz, MCLK/SMCLK/ACLK sources and dividers
- *Game connection:* choosing the right clock for the right peripheral

**Lesson 09 — Timer_A Up-Mode & Polling**
- Timer_A modes: stop, up, continuous, up/down; CCR0 compare match
- Building a periodic tick via TAIFG polling
- *Game connection:* Tetris gravity = piece drops one row every N ticks
- **Milestone:** `handheld/hal/timer.s` (polling)

**Lesson 10 — Interrupts & ISRs**
- Interrupt vector table, ISR entry/exit, GIE, interrupt latency and priority
- *Game connection:* button presses and the tick timer both use interrupts in the final game

**Lesson 11 — Low-Power Modes & the Game Loop**
- CPUOFF/LPM0, waking on CC0 interrupt, measuring current draw
- Building a 60 Hz game-loop heartbeat that sleeps between ticks
- *Game connection:* the game loop shell every future lesson calls into
- **Milestone:** `handheld/hal/timer.s` → CC0 ISR + LPM0; game-loop shell in `main.s`

---

## Phase 3 — Display Pipeline (Lessons 12–15)
*Hardware: Add SPI OLED (see [the hardware repo's BOM](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/bom-flat.md)) + breadboard*

**What to add:** Wire the OLED to P1.5 (SCLK), P1.7 (MOSI), P2.0 (CS), P2.1 (DC), P2.2 (RST). 3.3V from LaunchPad.

**Lesson 12 — SPI with USCI_B0**
- USCI_B0 SPI master setup (CPOL=0, CPHA=0, MSB first), `spi_tx_byte`
- Chip-select protocol, DC pin
- *Game connection:* every pixel sent to the display goes through this
- **Milestone:** `handheld/hal/spi.s`

**Lesson 13 — OLED Driver**
- Controller initialization sequence, row/column addressing
- `display_init`, `display_clear`, `display_set_pixel`
- *Game connection:* draw a single pixel — foundation for everything visual
- **Milestone:** `handheld/hal/display.s`

**Lesson 14 — Framebuffer & Drawing Primitives**
- Framebuffer strategy given 512 B RAM vs. display buffer size
- Draw filled rectangle, horizontal/vertical line
- *Game connection:* draw the Tetris board border and a single tetromino block
- **Milestone:** `handheld/gfx/framebuf.s`

**Lesson 15 — Sprites & Tiles**
- Tile/sprite bitmap layout, artifact-free movement (erase-then-draw)
- *Game connection:* draw a moving tetromino cleanly
- **Milestone:** `handheld/gfx/sprites.s`

---

## Phase 4 — Input & Audio (Lessons 16–18)
*Hardware: Add SN74HC165N shift register + 8 tactile buttons, LM386N-1 + speaker*

**What to add:** SN74HC165N PL to P2.3, CLK to P1.5 (shared SPI CLK), Q7 to P1.6 (MISO). 8 buttons to A–H inputs with pull-up resistors. PWM output from P2.4 (TA1.2) → 10µF cap → LM386 pin 3, speaker on pins 5/GND.

**Lesson 16 — Shift-Register Input**
- SPI in receive mode; SN74HC165N protocol: pulse PL low, read 8 bits
- `buttons_read` → 8-bit button state
- *Game connection:* read D-pad + A/B/Start/Select in one SPI transaction
- **Milestone:** `handheld/hal/input.s` (extended for shift-register source)

**Lesson 17 — PWM & Tone Generation**
- Timer_A up-mode with CCR1/CCR2 for PWM, duty cycle control
- `tone_play(freq, duration)`
- *Game connection:* piece-move blip, rotate click, line-clear jingle
- **Milestone:** `handheld/hal/audio.s`

**Lesson 18 — Sound Effects & Sequencer**
- Frequency table in Flash, sequence player (tempo, notes array)
- Game sounds: move, rotate, drop, line clear, game over, level up
- *Game connection:* complete audio feedback system
- **Milestone:** `handheld/hal/audio.s` (extended with sequencer)

---

## Phase 5 — The Game (Lessons 19–26)
*Hardware: Optionally add LiPo power system for portable play*

**Lesson 19 — Board Representation**
- 10×20 board in RAM as a packed bit array
- `board_get(row, col)`, `board_set(row, col, val)`
- *Game connection:* the core data structure of Tetris
- **Milestone:** `game/tetris.s` (board)

**Lesson 20 — Tetrominoes & Rotation**
- 7 pieces encoded as 4×4 bitmasks in Flash (4 rotations each)
- Rotation state machine
- *Game connection:* every piece you'll drop
- **Milestone:** `game/tetris.s` (pieces)

**Lesson 21 — Collision, Movement & Placement**
- Bounds + board collision check, stamping a piece onto the board
- Hard drop, soft drop
- *Game connection:* the physics of Tetris
- **Milestone:** `game/tetris.s` (physics)

**Lesson 22 — Line Clear & Scoring**
- Scan rows for full lines, shift rows down, Tetris scoring (100/300/500/800)
- Level system: gravity speeds up every 10 lines
- *Game connection:* the win condition and progression
- **Milestone:** `game/tetris.s` (rules)

**Lesson 23 — UART**
- USCI_A0 UART at 9600 baud, send score to terminal, receive a speed command
- *Game connection:* debugging line + a simple external control channel
- **Milestone:** `game/ui.s`

**Lesson 24 — ADC10**
- Internal temperature sensor, external potentiometer input
- *Game connection:* alternate control input / diagnostic readout
- **Milestone:** integrate into game (no new module)

**Lesson 25 — External SRAM**
- 23LC1024 SPI SRAM read/write, dirty-page sync strategy
- *Game connection:* framebuffer that outgrows on-chip RAM
- **Milestone:** `gfx/framebuf.s` → SRAM-backed

**Lesson 26 — Complete Game + Polish**
- Title screen, "GAME OVER" animation, pause menu
- High score in Flash (Info Flash segment), LPM3 auto-sleep between ticks
- *Game connection:* **ship it** — full playable Tetris on your handheld
- **Milestone:** final `handheld/` build — playable Tetris

---

## Repo Organization

Software repo: **github.com/aradanmn/MSP430handheld-firmware** (this repo — course + firmware). Hardware lives in a companion repo (see below).

```
MSP430handheld-firmware/
├── ROADMAP.md              ← this file
├── CLAUDE.md               ← AI assistant context (canonical course map + conventions)
├── README.md
├── setup-mac.sh            ← one-time macOS toolchain install
├── build-libmsp430.sh      ← builds libmsp430.dylib for mspdebug
├── course/
│   ├── common/             ← msp430g2553-defs.s, glossary.md, Makefile.template
│   ├── lesson-01-architecture/
│   ├── lesson-02-instruction-set/
│   ├── ...
│   └── lesson-26-complete-game/
├── handheld/               ← the capstone firmware skeleton (main.s, hal/, gfx/, game/)
└── journal/                ← session-by-session learning log
```

The **hardware design** — bill of materials, KiCad schematic, breadboard
layout, and per-phase wiring guides — lives in the separate hardware repo
**[aradanmn/MSP430handheld-hardware](https://github.com/aradanmn/MSP430handheld-hardware)**
(`bom-*`, `schematic/`, `breadboard/`, `scripts/`, `wiring/`). The lessons
below link to those wiring guides where a phase adds new hardware.

---

## What You Need Right Now (Phase 1)

Just the **MSP-EXP430G2 LaunchPad** — you likely already have it.

**To start Phase 3** (Lesson 12), order:
- SPI OLED module (see [the hardware repo's BOM](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/bom-flat.md) for the current recommended part)
- Full-size breadboard + jumper wires

**To start Phase 4** (Lesson 16), order:
- SN74HC165N (DIP-16) × 1 — DigiKey or Mouser
- 6mm tactile push buttons × 8
- 10kΩ resistors × 8 (pull-ups)
- LM386N-1 (DIP-8) × 1
- 8Ω 0.5W speaker
- 10µF and 250µF electrolytic caps

---

## Where to Start

Open `course/lesson-01-architecture/` and read `README.md`. Every lesson has the same structure: read the tutorials, run the example, then attempt the exercises before moving on.
