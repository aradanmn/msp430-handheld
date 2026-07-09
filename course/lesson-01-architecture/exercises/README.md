# Lesson 01 Exercises

Two exercises this lesson. There is no Ex3 milestone — Lesson 01 is
foundational, and the Course Map's first `handheld/` milestone
(`hal/leds.s`) doesn't begin until Lesson 02.

## Ex1 — Explore: Faster Blink

**File:** `ex1/fast_blink.s`

Starter file with the standard boilerplate (stack pointer, watchdog hold,
DCO calibration) and LED1 configured as an output, already in place. Your
job: make LED1 blink at approximately 4 Hz instead of the 1 Hz rate from
`examples/blink.s`, deriving your own delay constants rather than reusing
the lesson example's.

Look up:
- SLAU144 Chapter 8 (Digital I/O) if you need to revisit `P1DIR`/`P1OUT`
- SLAU144 Chapter 1 (CPU) for how many cycles arithmetic and jump
  instructions actually take at the calibrated 1 MHz clock rate

**Success criteria:**
- [ ] `make flash` builds and flashes without error
- [ ] LED1 blinks visibly faster than the Lesson 01 example
- [ ] Ten full on/off cycles take roughly 2.5 seconds end to end
      (timeable with a stopwatch) — i.e., close to 4 Hz
- [ ] LED2 stays off throughout

## Ex2 — Challenge: Alternating LEDs

**File:** `ex2/alternating_leds.s`

Starter file with both LEDs configured as outputs. Design constraint: LED1
and LED2 must alternate every 500 ms. At every instant, **exactly one** of
them is lit — never both at once, never neither. Design your own approach
to enforcing that constraint.

**Success criteria:**
- [ ] `make flash` builds and flashes without error
- [ ] At any moment you glance at the board, exactly one LED is lit
- [ ] The two LEDs swap roughly every 500 ms, continuously
- [ ] There is no visible instant where both LEDs are lit together, and no
      visible instant where both are dark together
