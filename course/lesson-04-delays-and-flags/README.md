# Lesson 04 — Delays, Status Flags & the Constant Generator

## Topic

Every timed behavior you've built so far — the blink rate in Lesson 01, the
counted flashes in Lesson 02 — has leaned on a busy-wait loop without asking
exactly how accurate it is or what else that loop is quietly doing to the
CPU. This lesson answers both questions. First: how to reason about a delay
loop in *cycles*, derive a target duration with `.equ` arithmetic instead of
guessing a magic number, and calibrate it against a stopwatch. Second, and
more important: the MSP430's status flags (C/Z/N/V in SR) are a shared,
CPU-wide resource — almost every arithmetic and logic instruction overwrites
them, including the instructions inside a delay loop's own `dec`/`jnz`. If
you `call` a subroutine between a `cmp` and the conditional branch that's
supposed to act on it, the flags that branch reads may no longer belong to
your `cmp` at all. This is one of the most common sources of "it works until
it doesn't" bugs in bare-metal assembly, and it's completely invisible
unless you know to look for it.

Along the way you'll also meet R3, the constant generator (CG) — a piece of
CPU hardware that lets certain small immediates (0, 1, 2, 4, 8, −1) show up
"for free" in an instruction encoding, with no extra instruction word and no
real register read.

## Learning Objectives

By the end of this lesson you will be able to:

- Estimate the cycle count of a counted delay loop at 1 MHz and derive
  `.equ`-based timing constants for an arbitrary target duration
- Explain why an off-by-one instruction inside a delay loop's body produces
  a measurable timing error, and calculate that error for a given case
- Name each SR status flag (C, Z, N, V) and state what sets it
- State which instruction classes affect the flags (CMP, ADD, SUB, AND, XOR,
  BIT, ...) and which never do (MOV, BIS, BIC)
- Explain, in one sentence, why a `call` placed between a `cmp` and its
  conditional branch can silently change which branch is taken
- Describe conceptually what the constant generator (R3/CG) does and why it
  exists, without needing a named constant for it (there isn't one)

## What You'll Build

`examples/flag_safe_delay.s` — a self-testing program that computes a small
known sum, compares it against the expected value, and branches on the
result *immediately* — before any subroutine call gets a chance to disturb
the flags that branch depends on. Only after the branch decision is already
locked in does the program call a delay subroutine (whose own internal
`dec`/`jnz` loop deliberately clobbers flags) to hold the resulting LED
state visible. LED1 lit solid means the self-test passed; a distinct
flashing pattern on LED2 is the fail indicator the same structure would
produce if the comparison had come out differently.

`exercises/ex1` — derive your own calibrated `.equ` delay constants to hit
a specific target blink rate, and verify your accuracy against a stopwatch.

`exercises/ex2` — a bug hunt: a program that's supposed to light LED1 only
once a counter reaches a target value, but doesn't behave that way. You
diagnose why.

There is no `handheld/` milestone this lesson — the first milestone lands
in Lesson 07 (Ex3 tier begins there per the course map).

## Game Connection

Precise timing is the backbone of every game tick — Tetris gravity, the
debounce window on the buttons, and the eventual 60 Hz game loop all depend
on you knowing exactly how many cycles an instruction sequence costs. And
every one of those systems will eventually involve comparing some game
state and branching on it — piece collision checks, score thresholds, level
transitions. The moment any of that comparison logic calls a helper
subroutine before acting on its own result, this lesson's trap is live. The
discipline you build today — decide first, call second — is what keeps a
growing `handheld/` codebase (dozens of `#include`d modules, deep call
chains) from producing bugs that only show up once in a while and vanish
the instant you add a print statement to look for them.

## Datasheet Reference

- **SLAU144, Chapter 3** — System Reset, Interrupts, and Operating Modes
  (status register bit layout)
- **SLAU144, Chapter 4** — CPU: registers, addressing modes, and the
  constant generator
- General CPU timing material in SLAU144's instruction set chapter for
  per-instruction cycle counts

## Success Criteria

- [ ] I can hand-calculate the cycle count and real-world duration of a
      nested counted delay loop given its inner/outer values
- [ ] The calibrated delay in `exercises/ex1` is within a few percent of
      its target duration, measured by timing multiple blinks with a
      stopwatch
- [ ] I can name all four SR flags (C, Z, N, V) and state what sets each one
- [ ] I can list at least three instructions that affect the flags and two
      that never do
- [ ] I can explain, in one sentence, why flags can't be trusted across a
      `call`
- [ ] `examples/flag_safe_delay.s` builds and flashes via `make flash`, and
      LED1 lights solid to indicate the self-test passed (LED2 flashing
      would indicate a fail, which this correct demo never reaches)
- [ ] I can describe, conceptually, what the constant generator (R3) does
      and why the assembler sometimes needs no extra instruction word to
      encode `#0`/`#1`/`#2`/`#4`/`#8`/`#-1`
- [ ] `exercises/ex1` and `exercises/ex2` each build, flash, and behave per
      their own success criteria (see `exercises/README.md`)
