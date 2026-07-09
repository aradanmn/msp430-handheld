# Exercise 3 — Milestone (Capstone): Final Polish

This is the last exercise in the course. There is no single new module to
write — this is an integration pass across several existing files that
turns the working game engine (Lessons 19–25) into a complete, playable
handheld. Read Tutorials 1 and 2 before starting; the state machine and the
Flash/LPM3 material are both load-bearing here.

Follow the project's established conventions throughout:
`handheld/registers.md` for register usage, `.L`-prefixed local labels,
module-prefixed public labels (CLAUDE.md's "Assembly File Conventions").

The spec below describes **behavior and integration points** — which
existing pieces each change hooks into. As with every milestone so far, no
register pre-assignments and no algorithm outlines are given; those
decisions are yours.

---

## 1. Title Screen

A `TITLE` state, entered:
- once at boot, before any game starts, and
- again whenever a game-over sequence (item 2, below) finishes.

While in `TITLE`, gravity, piece movement, and line-clear logic do not run.
A button press (your choice which one, or reuse whichever button your
Lesson 23 UI work already treats as "start" if you built one) transitions
to `PLAYING`, which must perform whatever initialization a fresh game needs
(empty board, first piece spawned, score reset — the same setup your
board/scoring modules from Lessons 19–22 already know how to do).

What the title screen displays or shows on the LEDs/OLED is your design
choice — it only needs to be clearly distinguishable from the `PLAYING`
state's game screen.

## 2. Game Over

Entered from `PLAYING` the moment a newly spawned piece cannot be placed at
its spawn position — i.e., the moment your Lesson 21 collision/placement
check reports a collision for a piece at spawn time rather than after a
player-initiated move. (You gave that check whatever name your own L21
milestone used; hook into it, whatever you called it.)

On entering `GAME_OVER`, produce some observable indication that is:
- **visually distinct** from both `PLAYING` and `TITLE` (an LED pattern, an
  OLED message, a sound from your Lesson 17–18 audio module, or a
  combination — your choice), and
- **bounded and noticeable** — it must run for a fixed, perceptible
  duration (not instantaneous, not indefinite) before the game
  automatically returns to `TITLE`.

## 3. Pause Toggle

Choose **one** button to toggle between `PLAYING` and a new `PAUSED` state.
Document your choice clearly in a comment at the point where you read
it — this is new behavior for that button, not something any earlier
lesson already specified. (The onboard S2, P1.3, is an acceptable choice if
you want the simplest option; a shift-register button from your Lesson 16
input set is equally acceptable if you'd rather reserve S2 for something
else.)

While `PAUSED`:
- gravity does not advance
- piece movement/rotation input is not processed
- the board and current piece's state must be preserved exactly — pressing
  the pause button again must resume play with nothing lost

## 4. High Score in Info Flash (Segment D Only)

**Safety constraint, restated because it matters:** Info Flash Segment A
(`0x10C0`–`0x10FF`) holds this board's DCO calibration constants. Your
high-score code must never construct an erase or write to any address at
or above `0x10C0`. Use **Segment D** (`0x1000`–`0x103F`) only.

Add two routines (file placement is your choice — `main.s` or elsewhere in
`handheld/`, since this isn't a dedicated new module):

- **`highscore_load`** — no arguments. Returns the persisted high score
  byte, currently stored in Segment D, in **R12**. This is an ordinary
  memory read (no Flash Controller unlock sequence needed) — call it once
  at boot, before the title screen is first shown.

- **`highscore_save`** — **R12** = the new high score byte to persist. No
  return value. Implements the actual unlock → erase Segment D → write →
  lock sequence (Tutorial 02, Part A), restricted to Segment D addresses
  only. Call this whenever the current run's score, at the moment a game
  ends, exceeds the value `highscore_load` returned at boot.

## 5. LPM3 Between Ticks

Replace the game loop's LPM0 entry (established in the Lesson 11 milestone)
with LPM3. This has one required consequence, per Tutorial 02, Part B:
`hal/timer.s`'s tick timer currently sources its periodic interrupt from
`SMCLK`, which stops running in LPM3 — for the tick to still fire and wake
the CPU on schedule, the timer must be reconfigured to source from `ACLK`
(itself sourced from the internal VLO, since this board has no crystal —
`BCSCTL3`'s `LFXT1S` field, Tutorial 02). This changes what value belongs
in the timer's period register, since `ACLK`/VLO runs at a very different
(and uncalibrated) frequency than `SMCLK`/DCO did.

## Integration Summary — What Touches What

| Change | Hooks into |
|--------|------------|
| Title/game-over/paused states | A mode value gating per-tick logic (Tutorial 01) — likely `main.s`'s tick handler |
| Game over trigger | Your Lesson 21 spawn-time collision/placement check |
| Pause toggle | Whichever button input path you choose, and the same gate that skips gravity/movement while paused |
| High score | New `highscore_load`/`highscore_save`, called at boot and at game-end respectively |
| LPM3 | `main.s`'s game loop LPM entry, and `hal/timer.s`'s clock source/period |

## Success Criteria

- [ ] A title screen is shown at boot and again after every game over
- [ ] A button press from the title screen starts a fresh game (board,
      score, and piece state all correctly reset)
- [ ] Game over triggers exactly when a piece can't be placed at spawn, not
      at any other time
- [ ] The game-over indication is visually distinct from both other states
      and lasts a fixed, noticeable duration before returning to the title
      screen
- [ ] A specific, documented button toggles pause; gravity and piece input
      stop while paused; resuming loses no board or piece state
- [ ] `highscore_load` and `highscore_save` exist with the argument/return
      convention above; `highscore_save` never touches an address at or
      above `0x10C0`
- [ ] The persisted high score survives a power cycle (unplug/replug or
      reset) and updates only when the current run beats it
- [ ] The game loop enters LPM3 (not LPM0) between ticks, and the tick
      timer is reconfigured to `ACLK`/VLO so it still wakes the CPU on
      schedule
- [ ] `cd handheld && make flash` builds and flashes cleanly
- [ ] No leftover TODO comments anywhere in the submitted changes
