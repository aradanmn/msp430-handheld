# MSP430 Handheld Tetris

A 26-lesson MSP430 assembly course that builds toward a handheld Tetris console. Everything runs natively on macOS (Apple Silicon or Intel) — no VM required.

The course and the handheld project are integrated: lessons teach one peripheral or concept at a time, and starting at Lesson 07, each lesson's final exercise (ex3) adds that peripheral's driver to a growing skeleton project in `handheld/`. By the end, the skeleton becomes a complete, playable game platform.

---

## Quick Start

```sh
./setup-mac.sh          # one-time: installs mspdebug + picocom via Homebrew
cd course/lesson-01-architecture/examples
make flash              # compile + flash to LaunchPad (USB must be connected)
```

Requires the [TI MSP430-GCC](https://www.ti.com/tool/MSP430-GCC-OPENSOURCE) full installer at `~/ti/msp430-gcc/`. See `setup-mac.sh` for details.

---

## Repository Structure

```
course/
├── common/
│   ├── msp430g2553-defs.s   ← register/bit definitions (included by every .s file)
│   ├── glossary.md          ← acronym & terminology reference
│   └── Makefile.template
├── lesson-01-architecture/            ← Part I: Assembly Foundations
├── lesson-02-instruction-set/
├── lesson-03-gpio-output/
├── lesson-04-delays-and-flags/
├── lesson-05-subroutines-and-stack/
├── lesson-06-gpio-input/
├── lesson-07-debouncing/
├── lesson-08-clock-system/            ← Part II: Timing & Interrupts
├── lesson-09-timer-a/
├── lesson-10-interrupts/
├── lesson-11-low-power-modes/
├── lesson-12-spi/                     ← Part III: Display Pipeline
├── lesson-13-oled-driver/
├── lesson-14-framebuffer/
├── lesson-15-sprites/
├── lesson-16-shift-register-input/    ← Part IV: Input & Audio
├── lesson-17-pwm-audio/
├── lesson-18-sound-effects/
└── lesson-19-board-representation/ through lesson-26-complete-game/  ← Part V: The Game

handheld/                    ← growing skeleton project (the capstone)
├── main.s                   ← _start, init, LPM0, vector table
├── hal/                     ← hardware abstraction (input, timer, spi, display, audio)
├── gfx/                     ← framebuffer, sprites
└── game/                    ← Tetris logic, UI
```

The **hardware design** — schematic, bill of materials, breadboard layout, and
per-phase wiring guides — lives in the separate hardware repo:
**[aradanmn/MSP430handheld-hardware](https://github.com/aradanmn/MSP430handheld-hardware)**.
This repo (the software side) links to those wiring guides from the lessons
that need them.

Each lesson contains two tutorials, a working example, and 3 exercises: ex1 (Explore — standalone concept practice), ex2 (Challenge — a real constraint problem or design decision), and, from Lesson 07 onward, ex3 (Milestone — adds a real module to `handheld/`). See `CLAUDE.md`'s Course Map for the full lesson-by-lesson breakdown and `ROADMAP.md` for the hardware build phases.

---

## Hardware

- **MCU:** MSP430G2553 on the **MSP-EXP430G2 Rev 1.5** LaunchPad (eZ-FET lite, USB `2047:0013`)
- **Display:** SPI OLED (see [the hardware repo's BOM](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/bom-flat.md) for the current recommended part)
- **Input:** 8 buttons via SN74HC165N shift register (SPI)
- **Audio:** LM386N-1 amp + speaker (Timer_A PWM)
- **Power:** Adafruit 4410 USB-C LiPo charger + 3.7V 2Ah LiPo
- **Flash:** `make flash` uses `mspdebug tilib` with `DYLD_LIBRARY_PATH=~/.local/lib`

---

## Current Progress

The course was redesigned from a 16-lesson to a 26-lesson map and rewritten from scratch. See `CLAUDE.md`'s Course Map for the full plan. Start at `course/lesson-01-architecture/README.md`.
