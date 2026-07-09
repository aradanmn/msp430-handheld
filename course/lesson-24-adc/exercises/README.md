# Lesson 24 Exercises

Read both tutorials before starting. Wire a potentiometer between VCC and
GND with its wiper on P1.4 before starting Exercise 1 — see
`docs/hardware/` for a wiring reference if you need one. Attempt Exercises
1 and 2 before studying `examples/adc_temp_demo.s` — it's the reference,
not the starting point.

---

## Exercise 1 — Explore: Potentiometer Blink Rate

**File:** `ex1/pot_blink.s`

Read the potentiometer on P1.4 (ADC10 channel 4, `AVCC`/`GND` as the
reference) and use the reading to control how fast LED1 blinks — turn the
pot one way and the blink visibly speeds up, turn it the other way and it
visibly slows down.

Look up:
- SLAU144 Chapter 22 — what `ADC10AE0` does and why it, not `P1SEL`, is
  what routes a pin to the ADC
- SLAU144 Chapter 22 — the meaning of the `SREF` field, and why a
  full-range external signal like a potentiometer wiper doesn't need the
  internal reference the temperature sensor needs
- The `INCH` field's bit position in `ADC10CTL1` (documented in
  `msp430g2553-defs.s`, right above `INCH_10`) — you'll need to derive the
  channel-4 value yourself, since only channel 10 is predefined

**Success criteria:**
- [ ] `make flash` builds and flashes without error
- [ ] Turning the potentiometer from one end of its range to the other
      produces a clearly visible change in LED1's blink rate — not a
      one-time jump, but a live, continuously-updating response as you keep
      turning it
- [ ] The blink rate change is monotonic: turning consistently in one
      direction only ever speeds up (or only ever slows down) the blink,
      never both

---

## Exercise 2 — Challenge: First Reading

**File:** `ex2/adc_first_reading.s`

This file reads the internal temperature sensor repeatedly and blinks LED1
a number of times reflecting each reading, the same shape as this lesson's
example. Build it, flash it, and let it run through several reading
cycles.

**Observed behavior:** the very first reading, immediately after power-up
or reset, consistently blinks far fewer times than the room's actual
temperature would suggest — as if the sensor briefly thought the room was
freezing or below. Every reading after that first one is correct and
stays consistent with the room's actual temperature, cycle after cycle,
reset after reset (the *first* reading after each reset is always the bad
one; it's never the second, third, or later reading).

Find what's different about that first reading and fix it so it's correct
from the very first cycle onward.

**Success criteria:**
- [ ] `make flash` builds and flashes without error
- [ ] The first reading after a fresh reset produces a blink count
      consistent with the room's actual temperature, matching every
      reading after it
- [ ] State in a comment what you changed and why — but leave the file in
      the fixed, working state, not the broken one commented out for
      reference

---

## Exercise 3 — Milestone: Integrate an ADC Source Into the Game

**Requires:** Lessons 01–24 (in particular, the Lesson 09/11 timer
milestone and the Lesson 23 `ui.s` milestone, depending on which
integration path you choose)

**No new file this lesson** — you're modifying existing handheld code, not
creating a module. See `ex3/README.md` for the full spec and the two
acceptable integration paths.

**Build & test:** `cd handheld && make && make flash`

**Success criteria:** compiles cleanly as part of the handheld build; the
chosen ADC source visibly and correctly affects the existing game
parameter you wired it into, per `ex3/README.md`.
