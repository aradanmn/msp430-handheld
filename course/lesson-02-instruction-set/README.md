# Lesson 02 — Instruction Set & Addressing Modes

## Topic

Lesson 01 got LED1 blinking using a handful of instructions copied from
boilerplate — `mov.w`, `mov.b`, `bis.b`, `bic.b` — without stopping to name
what they do or why there are several ways to write an address as an
operand. This lesson formalizes that vocabulary: the core MSP430 instruction
set (`MOV`, `ADD`, `SUB`, `AND`, `OR`, `XOR`, `BIC`, `BIS`, `BIT`, `CMP`) and
the addressing modes the CPU supports for reaching an operand — register,
immediate, absolute/symbolic, indexed, indirect, and indirect-autoincrement.

Every later lesson is written in this vocabulary. Debounce logic (Lesson 03)
is `BIT` and `CMP`. Timer setup (Lesson 04) is `BIS`/`BIC` on control
registers you've now named formally. Framebuffers and sprite tables
(Lessons 08 and 10) are walked with the indexed and indirect-autoincrement
addressing modes you'll practice here on a small LED pattern table.

## Learning Objectives

By the end of this lesson you will be able to:

- State what each of `MOV`, `ADD`, `SUB`, `AND`, `OR`, `XOR`, `BIC`, `BIS`,
  `BIT`, and `CMP` does to its destination operand (and which ones don't
  write a destination at all)
- Explain why `BIC`/`BIS` are preferred over plain `AND`/`OR` for touching
  specific bits of a shared peripheral register
- Explain the difference between `BIT` (test) and `AND` (write), and between
  `CMP` (test) and `SUB` (write)
- Choose `.b` vs `.w` correctly based on whether a register is byte-wide
  (e.g. `P1OUT`) or word-wide
- Name and use each addressing mode: register, immediate (`#`),
  absolute/symbolic (`&NAME`), indexed (`n(Rn)`), indirect (`@Rn`), and
  indirect-autoincrement (`@Rn+`)
- Hand-trace a short instruction sequence and predict the resulting
  register value(s) and whether the Zero flag is set

## What You'll Build

`examples/addressing_demo.s` — a program that walks a 4-entry table of LED
bit-patterns stored in Flash, using a single pointer register and
indirect-autoincrement addressing (`@R5+`) instead of four hardcoded
`bis.b`/`bic.b` instructions. The pointer resets to the table's base address
(referenced symbolically) each time it runs off the end, so the sequence
repeats forever.

`exercises/ex1` — derive an LED pattern from arithmetic instead of a table:
a 2-bit binary counter on LED1/LED2 built with `ADD` and a bitmask.

`exercises/ex2` — a design constraint: build a 5+ state LED sequence using
only indexed/indirect addressing through a single pointer register, with a
hard limit on how many absolute references your program is allowed to
contain.

## Game Connection

Every HAL module in `handheld/` — the timer tick, the SPI driver, the OLED
display code — is written entirely in this instruction vocabulary; there is
no higher-level language underneath it. Addressing modes specifically are
how the finished game will walk data structures larger than a single
register: the SRAM framebuffer (Lesson 08), sprite/tile tables (Lesson 10),
and the Tetris board array (Lessons 11-12) are all sequences of bytes or
words in memory that get traversed with a pointer register and indexed or
indirect-autoincrement addressing — exactly the technique
`addressing_demo.s` previews on a 4-byte table.

## Datasheet Reference

- **SLAU144** — the MSP430 Instruction Set Summary and the CPU/instruction
  chapters cover every instruction's semantics and addressing mode encoding
  in detail. Use it to check anything not fully covered in the tutorials.

## Success Criteria

- [ ] I can state what each of `MOV`, `ADD`, `SUB`, `AND`, `OR`, `XOR`,
      `BIC`, `BIS`, `BIT`, and `CMP` does, from memory, without looking at
      the tutorial
- [ ] I can explain why `BIT`/`CMP` don't need a destination write, and what
      that buys you (testing a register without disturbing its value)
- [ ] I can name all six addressing modes covered this lesson and give a
      one-line example of each
- [ ] `examples/addressing_demo.s` visibly cycles the LEDs through 4
      distinct states, in order, forever
- [ ] Reading `addressing_demo.s`, I can point to the single pointer
      register (not four hardcoded instructions) that selects each pattern
- [ ] `exercises/ex1`: LED1/LED2 visibly cycle through a 2-bit binary count
      (00 → 01 → 10 → 11 → 00 → ...) once every ~300 ms, forever
- [ ] `exercises/ex2`: the LEDs cycle through 5 or more distinct states
      forever, and I can confirm from my own source that only one pointer
      register — not per-step hardcoded addresses — selects each pattern
