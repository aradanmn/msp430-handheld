# Lesson 06 — GPIO Input & Polling

## Topic

Lessons 01–05 have all been about *output* — driving LED1 and LED2 from the
CPU's side of the wire. This lesson flips the direction: reading the world
back in. You'll configure the onboard S2 button (P1.3) as a digital input
with an internal pull-up resistor, learn why its logic is *inverted*
(pressed = 0, released = 1), and build the simplest possible reactive
program — a polling loop that samples the button forever and mirrors its
state onto LED1.

Along the way this lesson also puts a real, physical phenomenon in front of
you: contact bounce. A mechanical switch doesn't transition cleanly from
open to closed — its contacts physically chatter for a few milliseconds
before settling. You will not fix this yet. You will only build a program
sensitive enough to *see* it, so that when Lesson 07 introduces a proper
debounce technique, you already understand exactly what problem it's
solving and why it's hard.

## Learning Objectives

By the end of this lesson you will be able to:

- Configure a Port 1 pin as an input with an internal pull-up resistor using
  `P1DIR`, `P1REN`, and `P1OUT`.
- Explain the "P1OUT changes meaning" wrinkle: on an input pin with `P1REN`
  set, `P1OUT`'s bit selects pull-up vs. pull-down instead of driving an
  output level.
- Read `P1IN` and correctly interpret active-low logic — trace, by hand,
  what a status bit does across a press-and-release cycle.
- Write an infinite polling loop that samples an input and reacts to it
  immediately, and explain the CPU cost of that approach.
- Describe, from direct observation, what contact bounce looks like when a
  toggle-on-press program is driving an LED from a mechanical switch.

## What You'll Build

`examples/button_poll.s` configures S2 (P1.3) as an input with an internal
pull-up and LED1 (P1.0) as an output, then loops forever: LED1 lights while
the button is held down, and turns off the instant it's released. This is
*level-tracking*, not toggling — the LED always mirrors the button's current
state, so this example will not show you bounce (level-tracking is
naturally bounce-tolerant, which is itself worth noticing).

The exercises push further: `ex1` asks you to build a *toggle-on-press*
version instead (flip LED1 once per new press, rather than mirroring the
level), which is where bounce becomes visible. `ex2` asks you to design your
own fix for it using only tools you already have — polling and delay loops,
no timer peripheral yet.

## Game Connection

"Press a button to start" is the single most basic input event any game
needs, and every later input concept in this course — debounce (Lesson 07),
edge detection, and eventually reading eight buttons through a shift
register (Lesson 16) — is built on top of the polling primitive you write
today. If you can't reliably answer "is the button down right now?", you
can't reliably answer "did the player just press start?", and you certainly
can't build a Tetris control scheme on top of it. Get comfortable with
`P1IN` now; you'll be reading it, directly or indirectly, in nearly every
lesson from here to the end of the course.

## Success Criteria

- [ ] LED1 tracks the button state live in `examples/button_poll.s`: on
      while S2 is held, off while released, with no noticeable input lag.
- [ ] You can explain, in your own words, why `bit.b #BTN, &P1IN` sets `Z=1`
      when the button is *pressed* rather than when it's released.
- [ ] You can explain why `P1OUT`'s bit for P1.3 means "pull-up vs.
      pull-down" here, instead of "drive high vs. drive low" the way it
      does for LED1.
- [ ] You can observe and describe — to your instructor, or in the
      exercise write-up — at least one instance where a single clean
      physical press of S2 caused more than one LED toggle, or none.

See `course/common/glossary.md` for any unfamiliar acronym.
