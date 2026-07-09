# Lesson 23 Exercises

Read both tutorials before starting. Attempt Exercises 1 and 2 before you
study `examples/uart_echo.s` — it's the reference, not the starting point.
You'll need `picocom -b 9600 /dev/cu.usbmodem*` (exit: Ctrl-A Ctrl-X) for
every exercise in this lesson.

---

## Exercise 1 — Explore: UART Ready

**File:** `ex1/uart_ready.s`

Build a program that, on boot, transmits the exact string `MSP430 READY\r\n`
once over USCI_A0 at 9600 baud, and then echoes every byte it receives back
out, indefinitely.

Look up:
- SLAU144 Chapter 15's USCI_A0 UART init sequence (clock source, baud-rate
  divisor registers, modulation control) and the reset-hold/reset-release
  pattern around configuring them
- `UCA0STAT` in SLAU144 Chapter 15 — you don't need it for this exercise,
  but knowing what it reports (framing errors, overrun errors) will matter
  once you're debugging real serial traffic later in the course

**Success criteria:**
- [ ] `make flash` builds and flashes without error
- [ ] Opening `picocom -b 9600 /dev/cu.usbmodem*` and resetting the board
      shows exactly `MSP430 READY` followed by a newline, once
- [ ] Every character typed afterward is echoed back immediately
- [ ] Resetting the board (power cycle or reset button) repeats the
      greeting and resumes echoing — the behavior doesn't depend on the
      debugger staying attached

---

## Exercise 2 — Challenge: Burst Echo

**File:** `ex2/burst_echo.s`

This file builds and flashes a working echo program: greeting on boot, then
echo. Flash it and confirm it works normally — type one character at a
time, slowly, and watch each one come back correctly.

**Observed behavior:** when you paste a long line of text into the terminal
so it arrives and echoes back rapidly (most terminal programs let you paste
directly, or you can hold a key down to auto-repeat quickly), occasional
characters come back dropped, duplicated, or corrupted. Typing at normal,
one-key-at-a-time human speed never reproduces it, no matter how long you
try.

Find what's different between the slow case and the fast case, and fix the
file so rapid input echoes back exactly as sent, byte for byte, no matter
how fast it arrives.

**Success criteria:**
- [ ] `make flash` builds and flashes without error
- [ ] Typing slowly still echoes correctly (as before your fix)
- [ ] Pasting or rapidly repeating a long line of text (at least 40
      characters) echoes back byte-for-byte identical to what was sent,
      with no dropped, duplicated, or corrupted characters
- [ ] State in a comment which register you were missing a check on and why
      — but leave the file in the fixed, working state, not the broken one
      commented out for reference

---

## Exercise 3 — Milestone: `handheld/game/ui.s`

**Requires:** Lessons 01–23 (in particular, whatever score and level state
exists from the Lesson 19–22 milestones)

**What to create:** `handheld/game/ui.s`

See `ex3/README.md` for the full behavioral spec and public interface.

**Build & test:** `cd handheld && make && make flash`

**Success criteria:** compiles cleanly as part of the handheld build;
`ui_send_score` produces a readable score on a terminal at 9600 baud;
`ui_poll_speed_override` correctly reports a new value only on ticks where a
command byte actually arrived, and the documented sentinel otherwise.
