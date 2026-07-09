# Lesson 05 — Subroutines & the Stack

## Topic

Every lesson so far has been one flat block of code: `_start` falls through
instruction after instruction, maybe looping, but never *calling out* to a
piece of logic and coming back. That stops here. `call` and `ret` let you
factor a routine out once and reuse it from many places — but they only work
correctly if you understand exactly what they do to the stack pointer (`SP`,
`R1`), and exactly which registers a routine is allowed to touch.

This lesson covers two things that are really one thing: the mechanics of
`call`/`ret`/`push`/`pop` (what actually happens to `SP` and memory), and the
argument-passing convention — R12–R15 for arguments and scratch, R4–R11
callee-saved — that every module in `handheld/` and every remaining lesson in
this course assumes without re-explaining it.

## Learning Objectives

By the end of this lesson you will be able to:

- Explain exactly what `call` pushes onto the stack and what `ret` pops back
  off it, and predict `SP`'s value after any sequence of `call`/`push`/`pop`/
  `ret`.
- Hand-trace a stack frame — draw what memory near `SP` looks like at each
  step of a call chain.
- Explain why a missing or mismatched `pop` corrupts the stack, and why the
  eventual `ret` is where that corruption becomes visible (as a jump to a
  garbage address) even though the bug was introduced earlier.
- Use the R12–R15 argument/scratch convention to write a subroutine that
  takes its inputs in registers rather than being hardcoded to one caller.
- State which registers a subroutine may clobber freely (R12–R15) and which
  it must preserve if borrowed (R4–R11), and explain why that split exists.

## What You'll Build

`examples/reusable_routines.s` implements two small, genuinely reusable
subroutines:

- **`delay_ms`** — busy-waits for approximately the number of milliseconds
  passed in `R12`.
- **`led_set`** — takes an LED mask in `R12` and an on/off flag in `R13`
  (nonzero = on, zero = off), and drives exactly those LED bits accordingly.

A main loop blinks LED1 at a calibrated ~2 Hz purely by calling these two
subroutines back to back — `call #led_set` / `call #delay_ms` / `call
#led_set` / `call #delay_ms` / repeat. Neither subroutine knows anything
about "blinking" — that behavior lives entirely in how the main loop calls
them, which is exactly the point.

## Game Connection

Every module you'll write from Lesson 07 onward — `move_piece`,
`draw_board`, `game_update`, `spi_tx_byte` — is just a subroutine with an
argument convention. `handheld/registers.md` documents the exact convention
this lesson introduces (R12–R15 scratch/args, R4–R11 callee-saved), because
the ISR in `hal/timer.s` will eventually own R4–R7 across the entire game
loop, and every subroutine it calls has to respect that without being told
each time. Getting comfortable with `call`/`ret`/stack discipline now — on
two small, low-stakes routines — means that discipline is automatic by the
time it's protecting real game state instead of an LED blink rate.

## Success Criteria

- [ ] `delay_ms(500)` produces a real-world delay close to 500 ms — verified
      by the observed blink rate of the main loop, not just by reading the
      code.
- [ ] `led_set` is called with different masks and different on/off values
      and behaves correctly every time — not just for the one call pattern
      the main loop happens to use.
- [ ] No register outside R12–R15 is left corrupted after any subroutine
      call. Verify this yourself: initialize R4–R7 to sentinel values (e.g.
      `mov.w #0xDEAD, R4`) before the main loop starts, and confirm with the
      debugger/disassembly that they're still `0xDEAD` after several
      `delay_ms`/`led_set` calls.
- [ ] You can hand-trace `SP`'s value through a `call` + two `push`es + two
      `pop`s + `ret` sequence without running it — and explain what would go
      wrong (and why) if one `pop` were missing.

See `course/common/glossary.md` for any unfamiliar acronym.
