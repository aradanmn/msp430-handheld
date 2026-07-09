# Lesson 11 Exercises

Three tiers: Explore (ex1), Challenge (ex2), Milestone (ex3).

## Ex1 — Explore: Measure LPM Current

**Directory:** `ex1/`

Build your own LPM0 heartbeat: blink **LED2** at **2 Hz** (on 250 ms / off
250 ms), using the same idiom as `examples/lpm0-heartbeat.s` — a Timer_A CC0
ISR, a countdown register, `bis.w #(GIE|CPUOFF), SR` to enter LPM0, and a
plain `reti` to return to sleep. No polling loop, no busy-wait spin doing
real work between ticks.

The starter file gives you boilerplate only — the tick configuration,
countdown logic, and LPM0 entry are yours to derive from Tutorial 11.1/11.2
and SLAU144 Ch. 1.

**If you have a multimeter** capable of reading milliamps: measure the
LaunchPad's current draw while this program runs, then compare it against
temporarily replacing the `bis.w #(GIE|CPUOFF), SR` line with a `.Lspin: jmp
.Lspin` busy-wait (Lesson 10's style) instead, leaving everything else the
same. Record both readings. This is optional if you don't have the
equipment — the code-level criteria below stand on their own.

**Success criteria:**
- [ ] LED2 blinks at 2 Hz using only the ISR — no polling loop in `main`
- [ ] The CPU enters LPM0 via `bis.w #(GIE|CPUOFF), SR` exactly once, not
      inside any loop
- [ ] The ISR exits via a plain `reti` (no explicit `CPUOFF` clearing needed
      for this exercise, since the ISR does the whole job itself)
- [ ] (Optional) I recorded an approximate current-draw comparison between
      the LPM0 version and a busy-spin version

## Ex2 — Challenge: Auto-Wake Design

**Directory:** `ex2/`

**Constraint:** the CPU should spend nearly all of its time asleep in LPM0.
Real work — updating LED2's state — only needs to happen once every 2
seconds. LED1 is wired in this exercise as a "CPU busy" indicator purely for
grading purposes: **it should remain OFF** during normal operation, since
there's no legitimate reason for the main loop to be doing anything between
LED2 updates.

`ex2/auto-wake-design.s` is a complete, compiling program that attempts this
design. Build it, flash it, and watch **both** LEDs for at least 10 seconds.

**Observable failure:** LED2 blinks correctly, every 2 seconds, exactly as
intended. But LED1 — which should stay dark the entire time — visibly
glows or flickers continuously instead of staying off.

Your job: figure out why the CPU isn't actually resting between LED2
updates, using this lesson's two wake-up patterns (Tutorial 11.1) as your
framework, and redesign it so LED1 stays off while LED2 still updates
correctly every 2 seconds.

**Success criteria:**
- [ ] I can explain why LED1 glowing/flickering indicates the CPU isn't
      reaching real LPM0 rest between LED2 updates
- [ ] I can state which of the two wake-up patterns (plain `reti` vs.
      explicit `CPUOFF` clearing) the original design used, and why that
      choice was wrong for this constraint
- [ ] After my fix, LED1 stays off for the entire observation period and
      LED2 still updates every 2 seconds

## Ex3 — Milestone: `handheld/hal/timer.s` → CC0 ISR + LPM0

**Directory:** `ex3/`

See `ex3/README.md` for the full behavioral spec. This converts the polling
tick you built in Lesson 09 into the interrupt-driven, low-power design
that the rest of the handheld project runs on, and adds the game-loop shell
to `handheld/main.s`.

`ex3/ex3.s` is an intentionally empty placeholder — the real work happens in
`handheld/hal/timer.s` and `handheld/main.s`.
