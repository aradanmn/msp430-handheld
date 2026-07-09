# CLAUDE.md

This file provides guidance to Claude when working with code in this repository.

## What This Repo Is

A complete 26-lesson MSP430G2553 assembly programming course targeting the TI MSP-EXP430G2 LaunchPad. Everything runs natively on macOS (Apple Silicon or Intel). No VM required.

## Setup (one-time)

```sh
./setup-mac.sh
```

Installs `mspdebug` and `picocom` via Homebrew. The compiler comes from the TI MSP430-GCC full installer (`~/ti/msp430-gcc/`), which includes device-specific linker scripts. `libmsp430.dylib` is built from source for arm64 and installed to `~/.local/lib/`.

## MSP430IDE

A native macOS IDE lives at `~/Documents/MSP430IDE/`. Every exercise and the
`handheld/` project has an `msp430.toml` that the IDE reads automatically.

```sh
# Build and open the IDE
cd ~/Documents/MSP430IDE && make run

# Open any exercise as a project:
# File → Open Folder → select e.g. course/lesson-06-gpio-input/exercises/ex2
# The IDE discovers the msp430.toml and enables Build / Flash / Disasm buttons.

# Open the whole repo as a workspace:
# File → Open Folder → select msp430-handheld/
# IDE auto-discovers all sub-projects (one per exercise + handheld).
```

Each `msp430.toml` uses `mode = "external"` — Build shells out to `make`,
Flash to `make flash`, Disasm to `make disasm`. No extra configuration needed.

## Build Commands (Terminal fallback)

```sh
cd course/lesson-01-architecture/examples
make          # compile → .elf
make flash    # compile + flash to LaunchPad (USB must be connected)
make disasm   # disassemble the compiled binary
make clean    # remove .elf

# First-ever flash (updates eZ-FET firmware):
DYLD_LIBRARY_PATH=~/.local/lib mspdebug --allow-fw-update tilib "prog blink.elf"

# Serial monitor (Lesson 23+, UART)
ls /dev/cu.usbmodem*                  # find the device
picocom -b 9600 /dev/cu.usbmodem*     # exit: Ctrl-A Ctrl-X
```

All Makefiles prefer `~/ti/msp430-gcc/bin/msp430-elf-gcc` (full TI installation with device linker scripts) and use `mspdebug tilib` with `DYLD_LIBRARY_PATH=~/.local/lib` for the eZ-FET lite debugger (USB VID:PID 2047:0013) on Rev 1.5 LaunchPads.

## Course Structure

```
course/
├── common/
│   ├── msp430g2553-defs.s      ← ALL register/bit definitions (included by every .s file)
│   ├── glossary.md              ← MSP430/embedded terminology reference
│   └── Makefile.template       ← Template for new Makefiles
└── lesson-01-architecture/ through lesson-26-complete-game/
    ├── README.md
    ├── tutorial-01-*.md
    ├── tutorial-02-*.md
    ├── examples/               ← Working demo (Makefile + *.s) — study AFTER exercises
    └── exercises/
        ├── README.md
        ├── ex1/                ← Explore: build it from concepts + datasheet
        ├── ex2/                ← Challenge: debug broken code or solve a design problem
        └── ex3/                ← Milestone (L07+): write real handheld/ module from spec

handheld/                           ← Growing skeleton project (the capstone)
├── Makefile                        ← TARGET=main
├── registers.md                    ← Register allocation convention
├── main.s                          ← Minimal stub (student grows this via milestones)
├── hal/                            ← ALL modules are student-created via milestone exercises
│   ├── leds.s                      ← LED init + test pattern                (pre-L07 reference module)
│   ├── input.s                     ← Button debounce + read                 (L07 milestone)
│   │                                  → extended for shift-register input  (L16 milestone)
│   ├── timer.s                     ← Timer_A polling tick                   (L09 milestone)
│   │                                  → converted to CC0 ISR + LPM0         (L11 milestone)
│   ├── spi.s                       ← USCI_B0 SPI driver                    (L12 milestone)
│   ├── display.s                   ← SSD1325/SSD1306 OLED init + commands   (L13 milestone)
│   └── audio.s                     ← Timer_A PWM for buzzer                 (L17 milestone)
│                                      → sound effects & sequencer           (L18 milestone)
├── gfx/
│   ├── framebuf.s                  ← Drawing primitives                     (L14 milestone)
│   │                                  → SRAM-backed framebuffer             (L25 milestone)
│   └── sprites.s                   ← Tile/sprite drawing primitives         (L15 milestone)
└── game/
    ├── tetris.s                    ← Board, pieces, collision, lines        (L19–22 milestones)
    └── ui.s                        ← Menus, score display, UART             (L23 milestone)
```

`hal/leds.s` was created during initial repo setup (before this milestone scheme existed) and is kept as a working reference module — Lesson 03 (GPIO Output) covers the same material but does not have a formal Ex3 milestone, since the first module-producing milestone is Lesson 07.

## Assembly File Conventions

**Every `.s` file begins with:**
```asm
#include "<relative-path>/common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL
```

**Correct include paths by directory depth:**
- `examples/*.s` → `#include "../../common/msp430g2553-defs.s"`
- `exercises/exN/*.s` → `#include "../../../common/msp430g2553-defs.s"`
- `handheld/main.s` → `#include "../course/common/msp430g2553-defs.s"`

**Interrupt vector table** — use an explicit `.word` table (32 bytes = 16 vectors × 2 bytes):
```asm
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0    ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0      ; 0xFFF0–0xFFFC  unused
    .word   _start               ; 0xFFFE  Reset vector
```

For ISRs, replace the relevant 0 with the ISR label (positions counted from 0xFFE0 in steps of 2):
```asm
    .section ".vectors","ax",@progbits
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   port1_isr   ; 0xFFE4  Port 1
    .word   0           ; 0xFFE6  Port 2
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI_A0/B0 TX
    .word   0           ; 0xFFEE  USCI_A0/B0 RX
    .word   0           ; 0xFFF0  Timer_A overflow (TAIV)
    .word   0           ; 0xFFF2  Timer_A CC0
    .word   0           ; 0xFFF4  WDT
    .word   0           ; 0xFFF6  Comparator_A+
    .word   0           ; 0xFFF8  Timer1_A1
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
```

## Key Peripheral Patterns

**LPM entry/exit** (always use GIE | ... to enable interrupts simultaneously):
```asm
bis.w   #(GIE|CPUOFF), SR           ; enter LPM0
; exit from ISR:
bic.w   #CPUOFF, 0(SP)              ; clear CPUOFF in saved SR
```

**UART 9600 baud @ 1 MHz:**
```asm
bis.b   #(UART_RX|UART_TX), &P1SEL
bis.b   #(UART_RX|UART_TX), &P1SEL2
bis.b   #UCSWRST, &UCA0CTL1
mov.b   #UCSSEL_2, &UCA0CTL1       ; SMCLK
mov.b   #104, &UCA0BR0             ; 1MHz/104 ≈ 9600
mov.b   #0, &UCA0BR1
mov.b   #0x02, &UCA0MCTL
bic.b   #UCSWRST, &UCA0CTL1
```

**ADC10 internal temperature sensor:**
```asm
mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0
; wait ~30µs for reference to settle, then:
bis.w   #(ENC|ADC10SC), &ADC10CTL0
poll:   bit.w   #ADC10BUSY, &ADC10CTL1
        jnz     poll
        mov.w   &ADC10MEM, R5      ; 10-bit result
; T°C ≈ (raw − 673) / 4 + 25
```

**SPI / I2C share USCI_B0 on the same pins** (P1.5=CLK, P1.6=MISO/SDA, P1.7=MOSI/SCL). P1.6 is also LED2 — remove the LED2 jumper when using SPI/I2C.

## Interrupt Vectors Quick Reference

| Address | Peripheral |
|---------|-----------|
| 0xFFE4  | Port 1 |
| 0xFFEA  | ADC10 |
| 0xFFEC  | USCI_A0/B0 TX |
| 0xFFEE  | USCI_A0/B0 RX |
| 0xFFF0  | Timer_A overflow (TAIV) |
| 0xFFF2  | Timer_A CC0 |
| 0xFFF4  | WDT |
| 0xFFFE  | Reset |

## Makefile Template Notes

When creating a new Makefile, copy `course/common/Makefile.template` and:
1. Set `TARGET` to the `.s` filename stem
2. Set `MCU = msp430g2553`
3. `make flash` uses `mspdebug tilib` with `DYLD_LIBRARY_PATH=~/.local/lib` (handled automatically by the Makefile)

## Hardware Notes

- **MCU:** MSP430G2553 — 16 KB Flash (0xC000–0xFFFF), 512 B RAM (0x0200–0x03FF)
- **LaunchPad:** MSP-EXP430G2 Rev 1.5 with eZ-FET lite debugger (2047:0013)
- **LED1:** P1.0 (Red), **LED2:** P1.6 (Green, shared with I2C SDA)
- **Button S2:** P1.3, active LOW (requires internal pull-up via P1REN)
- **Serial port on macOS:** `/dev/cu.usbmodem*` (not `/dev/ttyACM0`)
- **Stack:** SP must be initialized to `#0x0400` (top of RAM) in `_start` when using `-nostdlib`

## Hardware Notes — Serial Port

On macOS the LaunchPad CDC serial port appears as `/dev/cu.usbmodem*`, not `/dev/ttyACM0`. Use `ls /dev/cu.usbmodem*` to find it.

## Handheld Skeleton — Composition Model

`handheld/main.s` uses `#include "hal/timer.s"` etc. to pull in modules. This avoids multi-file linking complexity. Each module defines its own subroutines; `main.s` calls them from the init sequence and the ISR.

**Naming convention:** All public labels are prefixed by module name — `timer_init`, `timer_isr`, `spi_init`, `spi_tx_byte`, `display_init`, `display_flush`, etc. Local labels use GAS `.L` prefix (e.g., `.Ldone`).

## Register Allocation Convention

See `handheld/registers.md` for the full reference. Summary:

| Register | Role | Scope |
|----------|------|-------|
| R0–R3 | PC, SP, SR, CG — CPU-reserved | Hardware |
| **R4–R7** | Frame counter, input, prev input, game mode | ISR — persistent |
| **R8–R11** | Game-specific state | ISR — assigned per game |
| **R12–R15** | Scratch / subroutine arguments | Caller-saved — any call may clobber |

**Rules:** R4–R11 are callee-saved (push/pop if borrowed). R12–R15 are caller-saved. Aligns with MSP430 GCC ABI.

## Exercise Format Policy

Solution directories do not exist. Do not create them. Do not recreate them.

Each lesson has **3 exercises**:

- **Ex1 — Explore:** Standalone LaunchPad demo. Student derives configuration from tutorials + SLAU144. No pseudocode, no loop structure hints, no "what changes from last exercise."
- **Ex2 — Challenge:** A real constraint problem or design decision. State the problem only — no hints about what's wrong or how to fix it.
- **Ex3 — Milestone (L07+):** Write a `handheld/` module from a behavioural spec + public interface (function names + args only). No register pre-assignments, no algorithm outlines. L01–L06 have no milestone (foundations only — the first module-producing milestone is L07's `hal/input.s`).

**Scaffold rules — enforced per tier:**

| Tier | Allowed | Forbidden |
|------|---------|-----------|
| Ex1 | Behaviour spec, what to look up in SLAU144, success criteria | Pseudocode, register bit patterns, loop structure hints |
| Ex2 | Problem statement, observable failure mode | What's broken, how to fix it, which register |
| Ex3 | Behaviour spec, public function names + arg registers | Register assignments, algorithm outlines, subroutine templates |

**Grading rules:**
- Grade against the spec, not a solution file
- Leftover TODO comment in working code: **−1**
- First attempt had a structural bug requiring correction: **−2**
- One cosmetic note max per grade
- Do not show the correct implementation — ever
- When student is stuck: point to ONE specific line or ask ONE question. Never give the answer.
- When student misreads the spec: hold the original interpretation. Do not agree with the misreading.

**Interaction rules:**
- Do not introduce instructions not yet covered in the curriculum
- Do not contradict a previous answer without explicitly stating "I was wrong about X"
- `.equ` arithmetic is the expected style for all timing constants from L04 onward
- `clr.w` has been used by the student but not formally introduced — do not teach it as a new concept; treat it as known

## Course Map

The handheld skeleton grows with each milestone. Part I–II (L01–11) run on the bare LaunchPad; Part III (L12–15) adds the OLED; Part IV (L16–18) adds the shift-register buttons and audio amp; Part V (L19–26) builds the complete Tetris game on top of the platform.

**Part I — Assembly Foundations** *(LaunchPad only)*

| L | Topic | Ex1 | Ex2 | Ex3 Milestone |
|---|-------|-----|-----|---------------|
| 01 | Architecture & Toolchain | Faster blink | Alternating LEDs | — |
| 02 | Instruction Set & Addressing Modes | Arithmetic patterns | Addressing-mode puzzle | — |
| 03 | GPIO Output & Bit Idioms | Counted flash | Dual throb | — |
| 04 | Delays, Flags & Constant Generator | Calibrated delay | Flag-clobber bug hunt | — |
| 05 | Subroutines & the Stack | Reusable `delay_ms` | Stack-corruption bug | — |
| 06 | GPIO Input & Polling | Bounce demo | Design a debounce | — |
| 07 | Debouncing & Edge Detection | Edge-count demo | Debounce timing design | `hal/input.s` |

**Part II — Timing & Interrupts** *(LaunchPad only)*

| L | Topic | Ex1 | Ex2 | Ex3 Milestone |
|---|-------|-----|-----|---------------|
| 08 | Clock System (DCO/MCLK/SMCLK/ACLK) | 8 MHz recalibration | Clock-source mixup bug | — |
| 09 | Timer_A Up-Mode & Polling | Polling blink | Timing analysis | `hal/timer.s` (polling) |
| 10 | Interrupts & ISRs | Convert to ISR | ISR timing budget | — |
| 11 | Low-Power Modes & Game Loop | Measure LPM current | Auto-wake design | `hal/timer.s` → ISR + LPM0; game loop shell in `main.s` |

**Part III — Display Pipeline** *(add SSD1306/SSD1325 OLED)*

| L | Topic | Ex1 | Ex2 | Ex3 Milestone |
|---|-------|-----|-----|---------------|
| 12 | SPI (USCI_B0 Master) | Bit-bang SPI | USCI_B0 loopback bug | `hal/spi.s` |
| 13 | OLED Driver | Raw bytes to OLED | Debug broken init | `hal/display.s` (init + clear + pixel) |
| 14 | Framebuffer & Drawing Primitives | Pixel/line to byte array | Dirty-page optimisation | `gfx/framebuf.s` |
| 15 | Sprites & Tiles | Render bitmap | Move without artifacts | `gfx/sprites.s` |

**Part IV — Input & Audio** *(add shift register + amp/speaker)*

| L | Topic | Ex1 | Ex2 | Ex3 Milestone |
|---|-------|-----|-----|---------------|
| 16 | Shift-Register Input | 8-button SPI read | Ghost-press bug hunt | `hal/input.s` (extended) |
| 17 | PWM & Tone Generation | Single tone | Duty-cycle puzzle | `hal/audio.s` |
| 18 | Sound Effects & Sequencer | Melody sequencer | Tempo-drift bug | `hal/audio.s` (extended) |

**Part V — The Game** *(optional LiPo power)*

| L | Topic | Ex1 | Ex2 | Ex3 Milestone |
|---|-------|-----|-----|---------------|
| 19 | Board Representation | Bit-array read/write | Packing puzzle | `game/tetris.s` (board) |
| 20 | Tetrominoes & Rotation | Represent + rotate piece | Rotation edge case | `game/tetris.s` (pieces) |
| 21 | Collision & Placement | Bounds check | Collision bug hunt | `game/tetris.s` (physics) |
| 22 | Line Clear & Scoring | Line detect + clear | Scoring + level speed | `game/tetris.s` (rules) |
| 23 | UART | Send score to terminal | Receive speed command | `game/ui.s` |
| 24 | ADC10 | Internal temp sensor | Potentiometer input | — (integrate into game) |
| 25 | External SRAM | SRAM read/write | Dirty-page SRAM sync | `gfx/framebuf.s` → SRAM-backed |
| 26 | Complete Game + Polish | Title screen | Pause-menu edge case | Final `handheld/` — playable Tetris |

**Handheld build order matters.** Each module `#include`d into `main.s` must compile cleanly before the next milestone starts. The Makefile target is always `cd handheld && make flash`.

## Datasheet References

The student should download these free PDFs from TI:

- **MSP430x2xx Family User's Guide (SLAU144)** — the primary reference for all peripheral configuration
  - Ch 8: Digital I/O (GPIO)
  - Ch 12: Timer_A
  - Ch 15: USCI — UART Mode
  - Ch 16: USCI — SPI Mode
  - Ch 17: USCI — I2C Mode
  - Ch 22: ADC10
- **MSP430G2553 Datasheet (SLAS735)** — pinout, electrical specs, pin function tables

## Student Progress

**Last session:** 2026-07-09 — course redesigned and rewritten from scratch (16-lesson map → 26-lesson map spanning Parts I–V). All prior lesson content, review exercises, and grade files were removed as part of the redesign; this is a clean start.

**Current position:** Not yet started. Begin at Lesson 01.

**Completed:** None yet.

**Pending:**
- L01 Ex1–Ex3
- All subsequent lessons through L26

Grade files belong in `grades/` (not adjacent to exercises) once grading resumes.
