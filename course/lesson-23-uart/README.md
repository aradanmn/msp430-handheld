# Lesson 23 — UART

## Topic

Every lesson up to this point has been a closed loop: the LaunchPad talks
only to its own LEDs, its own button, its own OLED, its own speaker. This
lesson opens a wire out to the rest of the world. **USCI_A0** in UART mode
turns two GPIO pins (P1.1 = RXD, P1.2 = TXD) into a serial link a laptop can
read with a plain terminal program (`picocom`) — no special driver, no
protocol analyzer, just text.

You'll configure USCI_A0 for 9600 baud against the 1 MHz calibrated DCO,
transmit bytes by polling `UCA0TXIFG`, and receive bytes both by polling
`UCA0RXIFG` and — because the final game loop can't afford to sit and block
on incoming serial data while it's also supposed to be servicing a timer
tick — by handling RX with an interrupt instead. This is also this Part's
UART milestone: `handheld/game/ui.s`, a brand-new module that sends the
score out over UART and lets an external command byte override the game's
speed.

## Learning Objectives

By the end of this lesson you will be able to:

- Explain why `UCA0BR0 = 104` only *approximately* hits 9600 baud at 1 MHz
  SMCLK, and what class of problem `UCA0MCTL`'s modulation bits correct for
- Configure USCI_A0 for UART mode using the standard init sequence
  (`UCSWRST` held during configuration, cleared when done)
- Transmit a byte by polling `UCA0TXIFG` in `IFG2`, and explain why skipping
  that poll before writing `UCA0TXBUF` corrupts output under bursty input
- Receive a byte by polling `UCA0RXIFG`, and alternatively by enabling
  `UCA0RXIE` and handling the USCI_A0/B0 RX vector (`0xFFEE`)
- Explain why interrupt-driven RX is the right choice for a game loop that
  must also keep servicing a periodic timer tick, where polling-and-blocking
  on RX is not

## What You'll Build

`examples/uart_echo.s` — transmits a greeting string once at boot, then
echoes every byte it receives back out, all by polling.

`exercises/ex1` — the same shape of program, built by you from the tutorials
and SLAU144, not copied from the example.

`exercises/ex2` — a working echo program with a real, reproducible failure
under rapid input. Find it and fix it.

`exercises/ex3` (**Milestone**) — `handheld/game/ui.s`: UART init, sending
the score to a terminal, and polling for a speed-override command byte. See
`exercises/ex3/README.md` for the spec.

## Game Connection

Two uses matter for the finished handheld. First, a debugging line: while
you're building and tuning collision detection, scoring, and level speed in
Lessons 19–22, being able to print the score (or any other internal value)
to a terminal over a USB cable is far faster than guessing from LED
patterns or an OLED readout alone. Second, a genuine external control
channel: a single byte typed into the terminal can override the game's
drop speed on the fly — useful for testing high levels without playing
through every line clear to reach them, and a preview of the same
byte-command idea Lesson 26's pause menu will build on.

## Datasheet Reference

- **SLAU144, Chapter 15** — USCI — UART Mode (`UCAxCTL0/1`, baud rate
  generation, `UCAxSTAT`, interrupt flags)

## Success Criteria

- [ ] I can state the bit-period / SMCLK-cycles-per-bit calculation that
      leads to `UCA0BR0 = 104` and explain why the result isn't a whole
      number
- [ ] I can explain, at a conceptual level, what problem `UCA0MCTL`'s
      modulation bits solve
- [ ] I can write the full USCI_A0 UART init sequence from memory (or from
      the tutorial) without copying it character-for-character from
      `examples/uart_echo.s`
- [ ] `examples/uart_echo.s` builds, flashes, prints its greeting over
      `picocom` at 9600 baud, and echoes typed characters back
- [ ] I can explain why writing `UCA0TXBUF` without first polling
      `UCA0TXIFG` is unsafe, and describe an observable symptom of getting
      it wrong
- [ ] I can contrast polling-based RX with interrupt-driven RX and explain
      why the game loop needs the latter
- [ ] `exercises/ex1`, `ex2`, and `ex3` each meet their own success criteria
      (see `exercises/README.md` and `exercises/ex3/README.md`)
