# Exercise 3 — Milestone: `handheld/game/ui.s`

## What to create

A brand-new file: `handheld/game/ui.s`, `#include`d into `handheld/main.s`
alongside the other modules (see `handheld/main.s`'s existing `#include`
lines for the pattern).

## Behavioral spec

`handheld/game/ui.s` gives the rest of the handheld project a UART link to
a terminal: it can announce the current score, and it can let someone
typing into a terminal override the game's drop speed without touching a
button.

- **Initialization.** Configure USCI_A0 for UART at 9600 baud, matching the
  init sequence from this lesson's tutorials and example. RX must be
  interrupt-driven (`UCA0RXIE` enabled, serviced by an ISR wired to vector
  `0xFFEE`), not polled — this module has to coexist with the rest of the
  game loop's periodic timer tick, and a blocking poll on RX would freeze
  everything else while waiting for a byte that might never come. TX may
  remain polling-based (there's no equivalent conflict on the transmit
  side, since sending only happens when this module explicitly calls
  `ui_send_score`).

- **Sending the score.** Whenever called, take a 16-bit score and transmit
  it over UART in a human-readable form — legible if a person is watching
  `picocom`, not just a raw byte dump. (Tutorial 23.2 walks through one way
  to do this: converting the binary value to ASCII decimal digits. A
  simpler fixed-width transmission is also described there and is an
  acceptable implementation, but document clearly in your file whichever
  format you chose, since the exact byte sequence produced is your design
  decision, not a spec requirement.)

- **Receiving a speed-override command.** A byte arriving from the
  terminal at any time should be captured by the RX interrupt and made
  available for the main loop to pick up later, without the main loop ever
  blocking to wait for it. Calling the poll function on a tick where
  nothing arrived since the last call must not report a stale or repeated
  byte from an earlier tick — only a genuinely new byte counts.

## Public interface

- **`ui_uart_init`** — no arguments. Configures USCI_A0 for UART at 9600
  baud with interrupt-driven RX, per the spec above. Call once during the
  handheld's init sequence, alongside the other `*_init` calls in
  `main.s`.

- **`ui_send_score`** — argument in **R12**: the 16-bit score to transmit.
  Sends it out over UART in human-readable form, per the spec above. May
  clobber R12–R15 (standard caller-saved scratch convention).

- **`ui_poll_speed_override`** — no arguments. Returns in **R12**: a new
  speed value if a command byte was received over UART since the last call
  to this function, or a defined sentinel value if nothing new arrived.
  You choose and document the sentinel (in a comment at the top of the
  file) — it must be a value that could never be confused with a
  legitimate speed command byte your design accepts. May clobber
  R12–R15.

## What's deliberately not specified

No register assignments for internal state, no ISR structure, no format
for the transmitted score, no encoding for the speed command byte or the
sentinel. Those are your design decisions — document each one with a
comment where you make it.

## Success criteria

- [ ] `handheld/game/ui.s` exists and is `#include`d into `handheld/main.s`
- [ ] `cd handheld && make` builds cleanly
- [ ] `ui_uart_init` brings up USCI_A0 UART at 9600 baud with RX handled by
      an interrupt, not a poll
- [ ] `ui_send_score` produces a human-readable score on a terminal at 9600
      baud when called with a score value in R12
- [ ] `ui_poll_speed_override` returns the documented sentinel on ticks
      where no byte arrived, and the correct decoded value on ticks
      following a byte's arrival — verified by typing a command byte in
      `picocom` and observing the next call pick it up exactly once
