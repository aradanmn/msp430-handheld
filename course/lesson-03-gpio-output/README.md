# Lesson 03 — GPIO Output & Bit Idioms

## Topic

Lessons 01–02 got LED1 blinking and introduced the MSP430's instruction
vocabulary. This lesson goes deeper on the two registers that make GPIO
*output* work — `P1DIR` and `P1OUT` — and on the bit-manipulation idioms
(`BIS`, `BIC`, `XOR`) that let you drive **one** pin without disturbing the
**other seven** that happen to live in the same 8-bit register.

That "shared register" problem is not academic. `P1OUT` controls LED1
(P1.0), LED2 (P1.6), the button pull-up (P1.3, once you get to input), and —
much later — SPI pins on the same port. Every peripheral you add from here
forward has to coexist in the same byte. Getting the masking habit right now
means you don't have to unlearn a bad habit later when a careless `mov.b`
silently turns off a pin you didn't mean to touch.

## Learning Objectives

By the end of this lesson you will be able to:

- Explain what `P1DIR` and `P1OUT` each control, and why direction must be
  set before an output write means anything.
- Use `bis.b`, `bic.b`, and `xor.b` to set, clear, and toggle specific pins
  without affecting the rest of the port.
- Explain *why* `mov.b #mask, &P1OUT` is dangerous on a shared register, and
  predict the exact bit pattern it produces given a starting state.
- Represent a small set of discrete states (e.g. game states) as a table of
  LED bit-patterns, and drive a state machine from that table instead of a
  chain of `if`-style branches.
- Build a multi-pattern LED sequence using only delay loops — no timer
  peripheral yet (that's Lesson 04).

## What You'll Build

`examples/led_patterns.s` cycles LED1 and LED2 through three named
bit-patterns forever:

- **attract** — both LEDs off, slowly blinking together (like an arcade
  cabinet's idle screen)
- **ready** — LED1 solid on (green light: "player, go")
- **game-over** — both LEDs flashing together, fast

Each pattern holds for a distinct duration before the next one takes over.

## Game Connection

Long before the handheld has an OLED display, LED1 and LED2 are the *only*
way it can tell the player anything. "Attract mode," "ready," and "game
over" are exactly the kind of states the real Tetris-style game will need to
signal — first with two LEDs, later with graphics on the SSD1325 display
built in Lesson 07. The bit-pattern-table technique you build here is a
direct rehearsal of the state-indication problem the display will solve
later: a small number of named states, each represented as data, driven by
an index rather than hand-written per-state code.

## Success Criteria

- [ ] Each named pattern (attract / ready / game-over) is visually distinct
      and holds for its own designated duration — you should be able to
      identify which state you're in just by watching the LEDs.
- [ ] Switching from one pattern to the next never causes a visible
      flicker or glitch on an LED that is supposed to stay in the same
      state across the transition (e.g. if LED1 is on at the end of one
      pattern and stays on at the start of the next, it must not blink off
      in between).
- [ ] Only the bits for the LED(s) actually being changed are touched in
      any single instruction — inspect your own `bis.b`/`bic.b`/`xor.b`
      masks and confirm none of them is a bare `mov.b` to `P1OUT` that
      could clobber a pin you don't own.
- [ ] The program loops forever with no manual reset needed between
      cycles.

See `course/common/glossary.md` for any unfamiliar acronym.
