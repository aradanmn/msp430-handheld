# Tutorial 01 — The Top-Level Game State Machine

## Every Tick Asks "What Mode Am I In?"

Since Lesson 11, the handheld's game loop has had a heartbeat: wake once
per tick (an interrupt, historically LPM0), do a unit of work, go back to
sleep. Up through Lesson 22, "a unit of work" meant essentially one thing —
advance gravity, read input, update the board, redraw. That was enough
while the whole project *was* "playing Tetris." It stops being enough the
moment there's a title screen to sit at before a game starts, a pause state
that must freeze gravity without losing the board, and a game-over state
that shouldn't respond to "rotate" or "move left" at all.

The fix is the same one nearly every game (and most embedded UIs) uses: one
persistent value representing *which top-level state the game is
currently in*, checked at the top of each tick to decide what that tick's
"unit of work" even means. `handheld/registers.md` already reserves
exactly this role — R7 is documented as "Game state / mode flags,"
persistent across ticks, exactly like the frame counter in R4. This lesson
is the first one that actually needs it for its originally intended
purpose.

## The States and Their Transitions

```
        ┌─────────┐   button press    ┌──────────┐
   ┌───►│  TITLE  │ ─────────────────►│  PLAYING │◄───┐
   │    └─────────┘                   └────┬─────┘    │
   │                                        │pause     │resume
   │                                        ▼          │
   │                                  ┌──────────┐     │
   │                                  │  PAUSED  │─────┘
   │                                  └──────────┘
   │                                        │
   │       piece can't spawn (collision)    │
   │                                        ▼
   │                                 ┌───────────┐
   └─────────────────────────────────│ GAME_OVER │
          timeout / button press     └───────────┘
```

- **TITLE** — the idle/attract state, entered at boot and re-entered after
  a game-over sequence finishes. A button press starts a new game (which
  means resetting whatever board/score/piece state a fresh game needs —
  the same initialization your board module already does when a game
  begins).
- **PLAYING** — the state every lesson through L22 already implemented:
  gravity, input, collision, line-clear, scoring, all running each tick.
- **PAUSED** — entered from PLAYING on a specific button press (this
  project's choice of button is a milestone decision — see `ex3/README.md`).
  Gravity and piece-input processing don't run in this state; the board and
  piece stay exactly as they were. The same button (or another of your
  choosing, documented) returns to PLAYING with no state lost.
- **GAME_OVER** — entered from PLAYING the moment a new piece can't be
  placed at its spawn position — precisely the collision check your Lesson
  21 milestone already implements, just invoked at a new moment (spawn
  time) with its failure now meaning something beyond "don't move there."
  After some bounded, visually distinct indication (your design choice —
  see `ex3/README.md`), the game returns to TITLE.

## Why a Single Persistent Value, and Not Four Different Code Paths

You could imagine giving `main.s`'s tick handler four completely separate
bodies, selected by some higher-level dispatch. In practice, that's exactly
what "gate on the mode value" *is* — the mode value is the dispatch key,
and each tick's logic starts by asking "what am I allowed to do right now?"
A `PAUSED` tick, for instance, isn't a different game loop; it's the same
tick handler recognizing that gravity and piece input shouldn't run this
time, while still handling the button that will transition back to
`PLAYING`. Whether you implement that as an explicit branch table, a chain
of compares, or something else is an implementation decision left to you —
the spec in `ex3/README.md` describes behavior and integration points,
never internal structure.

## What Doesn't Change

Nothing about this tutorial replaces or reworks the board logic, collision
detection, scoring, or rendering you already built in Lessons 19–22 and
25. Those modules keep doing exactly what they already do. What's new is
*when* they get called, and what happens around them — the mode value
gating whether this tick's "unit of work" is "run the game" at all, or
"wait for a button in the title screen," or "hold everything still until
resumed."

## Check Your Understanding

1. Which existing per-tick behavior (from Lessons 19–22) should *not* run
   while the mode value is `PAUSED`?
2. What existing function, originally written to answer "can this piece go
   here?", becomes the game-over trigger when it's called at piece-spawn
   time instead of during normal movement?
3. Why is a single "current mode" value simpler to reason about than
   scattering separate boolean flags (`is_paused`, `is_game_over`,
   `is_title_screen`, ...) across several registers?
