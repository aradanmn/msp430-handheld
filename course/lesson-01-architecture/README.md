# Lesson 01 — Architecture & Toolchain

## Topic

Before any peripheral makes sense, you need to know what you're actually
programming: the MSP430G2553's memory map, its 16-register CPU, and the
toolchain that turns a `.s` file into bits sitting in Flash. This lesson
covers no peripherals beyond the two GPIO pins needed to blink an LED — the
entire point is to get the foundation solid: where code and data live, what
the special registers (PC, SP, SR, CG) do, why the very first four
instructions of every program in this course look identical, and how
`make` / `make flash` actually get a program onto the chip.

By the end of this lesson you will have written, built, and flashed your
first real program: LED1 blinking at a steady 1 Hz.

## Learning Objectives

By the end of this lesson you will be able to:

- Describe the MSP430G2553 memory map (Flash, RAM, peripheral space, Info
  Flash) and state the address range of each region
- Name the four special-purpose registers (R0–R3) and what each one does
- Explain why the stack pointer must be initialized to `0x0400` before
  anything else happens, and why the stack grows downward from there
- Explain the WDTPW password mechanism and why a watchdog write without it
  resets the chip
- Walk through the DCO calibration sequence (`clr.b &DCOCTL` →
  `mov.b &CALBC1_1MHZ, &BCSCTL1` → `mov.b &CALDCO_1MHZ, &DCOCTL`) and why the
  order matters
- Explain what the `.vectors` section is, why it lives at a fixed address,
  and what the CPU does with it at power-up
- Use `make`, `make flash`, `make disasm`, and `make clean` to build and
  deploy a program to the LaunchPad

## What You'll Build

`examples/blink.s` — a complete program that blinks LED1 (P1.0, red) at a
steady 1 Hz: 500 ms on, 500 ms off, forever, using a calibrated 1 MHz clock
and a counted delay loop.

`exercises/ex1` — the same idea, but you derive your own delay constants to
hit a different (faster) blink rate.

`exercises/ex2` — a design problem: make two LEDs alternate correctly, with
no gap and no overlap.

There is no `handheld/` milestone this lesson — Lesson 01 is foundational.
The Course Map's first milestone (`hal/leds.s`) begins in Lesson 02.

## Game Connection

Everything in the finished handheld — the OLED framebuffer, the Tetris
board state, the audio driver — is just bytes sitting somewhere in this same
16 KB of Flash and 512 B of RAM, moved around by the same 16-register CPU
you're meeting today. The LaunchPad and its two LEDs are the very first
sliver of the handheld you're building: this lesson pours the foundation
slab. Every later lesson adds one layer on top of the boilerplate you write
here — the same four setup instructions (`SP` init, watchdog hold, DCO
calibration) will open literally every `.s` file for the rest of the course,
including `handheld/main.s` itself.

## Datasheet Reference

- **SLAU144, Chapter 1** — CPU architecture: register file, addressing modes
- **SLAU144, Chapter 3** — System Reset, Interrupts, and Operating Modes
  (watchdog behavior, vector table)
- **SLAU144, Chapter 5** — Basic Clock Module+ (DCO calibration)
- **SLAS735** — MSP430G2553 datasheet: memory map, Info Flash calibration
  byte addresses

## Success Criteria

- [ ] I can state the four memory regions (Flash, RAM, peripherals, Info
      Flash) and their address ranges from memory
- [ ] I can explain what R0–R3 are for without looking them up
- [ ] I can explain why `SP` is set to `0x0400` and why that must happen
      before anything else in `_start`
- [ ] I can explain what happens if a `WDTCTL` write omits `WDTPW`
- [ ] `examples/blink.s` builds and flashes without error via `make flash`
- [ ] LED1 (red, P1.0) blinks at approximately 1 Hz (500 ms on, 500 ms off)
      continuously
- [ ] LED2 stays off (untouched) throughout
- [ ] Removing power and re-applying it resumes the same blink — the
      program does not depend on the debugger staying attached
- [ ] `exercises/ex1` and `exercises/ex2` each build, flash, and behave per
      their own success criteria (see `exercises/README.md`)
