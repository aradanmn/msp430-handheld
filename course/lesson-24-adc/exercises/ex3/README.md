# Exercise 3 — Milestone: Integrate an ADC Source Into the Game

## No new file this lesson

Unlike every other milestone so far, Lesson 24 doesn't hand you a blank
module to fill in. Both ADC sources in this lesson are complete after
Exercises 1 and 2 — what's missing is wiring one of them into a game
parameter that an earlier milestone already created. This exercise modifies
existing handheld files; it does not add a new one.

Pick **one** of the two integration paths below. Either is an acceptable
milestone; you do not need to do both.

---

## Path A — Potentiometer sets the starting gravity speed

**Integration point:** the period-setting entry point in
`handheld/hal/timer.s` that your Lesson 09/11 milestones created for
programming Timer_A's gravity drop-tick period (by this course's naming
convention — see `CLAUDE.md`'s "Naming convention" note — a module-prefixed
label such as `timer_set_period`; check your own file for its exact name if
you called it something else). That subroutine takes its new period value
in **R12**, matching this project's caller-argument convention.

**What to build:** at title-screen time — before a game round actually
starts, not during active gameplay — read the potentiometer on P1.4 and
map its raw 10-bit reading down to a small number of discrete speed steps
(Tutorial 24.2 covers the shift-based technique). Convert the chosen step
into whatever period value your timer module's period-setter expects, load
it into R12, and call that subroutine once, before gravity starts ticking
for the round.

**What's deliberately not specified:** how many discrete steps you choose,
how a step number maps to an actual period value, and exactly where in
your title-screen code the read-and-call happens. Those depend on choices
your own earlier milestones already made.

**Success criteria:**
- [ ] Turning the potentiometer before starting a round changes the
      round's initial gravity speed, verified by observing a visibly
      different drop rate across at least two different pot positions
- [ ] The pot is not read again mid-round — the speed it sets is fixed for
      the round once play begins (level-based speed increases from Lesson
      22 still apply on top of it as before)

---

## Path B — Temperature sensor as a UART diagnostic value

**Integration point:** `ui_send_score` in `handheld/game/ui.s` (this
project's own Lesson 23 milestone), which takes a 16-bit value in **R12**
and transmits it over UART in human-readable form.

**What to build:** read the internal temperature sensor, convert the raw
result to an approximate °C value (Tutorial 24.2's formula), and transmit
it over UART using `ui_send_score`'s calling convention — load the
temperature value into R12 and call it. Because `ui_send_score` was
designed to report the game score, sending a temperature value through it
unmodified would be ambiguous on the receiving terminal (is "72" a score or
a temperature?). Decide and document a way to make the diagnostic reading
distinguishable from an actual score transmission — the exact scheme
(a distinct byte sent first, a different call site, a wrapper subroutine
that tags the value some way, etc.) is your design choice.

**What's deliberately not specified:** how you disambiguate a diagnostic
temperature transmission from a real score transmission, and when in the
handheld's run loop the temperature gets read and sent (once at boot, once
per title screen, on a button press — your choice, document it).

**Success criteria:**
- [ ] A temperature reading is transmitted over UART at some well-defined
      point you've documented, and is clearly identifiable on the terminal
      as a temperature, not a score
- [ ] The transmitted value is within a couple of degrees of the room's
      actual temperature, verified by comparison to a real thermometer or
      known room temperature

---

## Either path — general success criteria

- [ ] `cd handheld && make` builds cleanly
- [ ] The ADC read added for this milestone does not block or stall the
      rest of the game loop — reuse the non-blocking `ADC10BUSY` poll
      pattern from this lesson's example/exercises, called only at the
      specific integration point above, not from inside the per-tick game
      loop itself
- [ ] A comment at the call site states which path you chose and why
