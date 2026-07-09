# Lesson 13 Exercises

Read both tutorials first. Wire the OLED per `docs/hardware/phase-2-oled-display.md`
and remove any leftover P1.7 -> P1.6 loopback jumper from Lesson 12. Flash
`examples/display_demo.s` only *after* you've attempted your own exercises.

---

## Exercise 1 — Explore: Raw Bytes to OLED

**Requires:** Lessons 01–12 + Tutorial 01 (command/data protocol, reset, init categories)

**File:** `ex1/ex1.s`

Bring the OLED controller out of its power-on display-off state using only
raw command bytes — no addressing, no GDDRAM writes, no framebuffer. Once
your init sequence is far enough along that the controller will accept
commands, send the **Entire Display ON** override command. On SSD1306-family
controllers this forces every pixel in the panel on, ignoring whatever
GDDRAM currently contains — so you can prove the controller is alive and
correctly initialized without ever addressing or writing a single data byte.

**What to look up:** your controller's command table (SLAU144 doesn't cover
this — it's the OLED controller's own datasheet) for: the display-off/on
commands, whatever minimum set of commands your part needs before it will
accept further commands meaningfully (clock, charge pump, multiplex ratio —
see tutorial-01's category table), and the specific opcode for "entire
display on, ignore RAM."

**Success criteria:** the entire OLED panel lights up — every pixel on,
uniformly, with no addressing commands sent at all.

---

## Exercise 2 — Challenge: Debug Broken Init

**Requires:** Lessons 01–12 + Tutorial 01 + Tutorial 02

**File:** `ex2/ex2.s`

This file runs the same sequence as the lesson example: init, clear the
screen, light a single pixel at (10, 10). Build it and flash it exactly as
you would the example.

**Observed behavior:** the screen stays completely dark. Not dim, not
flickering — nothing lights, ever, on any reset. Wiring is identical to the
working example.

Find what's missing from the init sequence.

**Success criteria:** the pixel at (10, 10) lights, matching the lesson
example's behavior. Leave the file in the state that actually works — don't
leave the broken sequence commented out for reference.

---

## Exercise 3 — Milestone: `handheld/hal/display.s`

**Requires:** Lessons 01–13 + Exercises 1–2

**What to create:** `handheld/hal/display.s`

See `ex3/README.md` for the full spec.

**Build & test:** `cd handheld && make && make flash`

**Success criteria:** compiles cleanly as part of the handheld build;
`display_clear` followed by one `display_set_pixel` call shows exactly one
lit pixel at the requested coordinate on an otherwise blank screen.
