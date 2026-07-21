# Exercise 3 (Milestone) — Extend `handheld/hal/audio.s` with a Sequencer

## Where you're starting from

Your `handheld/hal/audio.s` (Lesson 17) already exposes a blocking
`audio_tone_play(period, duration_ms)`. This milestone adds a
non-blocking sequencer layer on top of it — it does not replace
`audio_tone_play`, which is still useful on its own for single beeps.

## Behavior Required

**A note-frequency table (new):**

A table of period constants, computed with `.equ` arithmetic, covering at
least the range C4 through B5 (two octaves) — the same technique from
this lesson's tutorials, extended to a full useful range. Standard
equal-tempered tuning (A4 = 440 Hz) is the expected reference.

**Sequence data (new):**

A Flash-resident table format for a named sound effect: a flat list of
(period, duration-in-ticks) word pairs, ending in a sentinel value that
unambiguously marks the end of the sequence (see the lesson tutorials for
why `0` works as that sentinel). Build at least five such tables, one
each for: piece move, rotate, drop, line clear, and game over.

**Non-blocking playback (new):**

Starting a sequence must return immediately — it must not block waiting
for the sequence to finish. Advancing a playing sequence happens once per
call to a tick function, driven by the same per-tick interrupt your game
loop already runs on (from your Lesson 09–11 `hal/timer.s`). When a
sequence finishes (its sentinel is reached), the output must go silent
and stay silent until another sequence is started.

## Public Interface

```
audio_play_sequence   ; R12 = address of a sequence table in Flash
                       ; (format above). Starts that sequence playing.
                       ; Returns immediately — does not wait for it to
                       ; finish. Starting a new sequence while one is
                       ; already playing replaces it.

audio_tick             ; no args. Call exactly once per game tick (e.g.
                       ; from your timer ISR or from game_update).
                       ; Advances the currently-playing sequence by one
                       ; tick's worth of progress. Silences the output
                       ; and marks playback finished when the sequence's
                       ; sentinel is reached. Does nothing if no sequence
                       ; is currently playing.
```

## Reference Material

- [`wiring/phase-4-audio.md`](https://github.com/aradanmn/MSP430handheld-hardware/blob/main/wiring/phase-4-audio.md) — frequency/period formula
- Lesson 18 tutorials — sequence table format, ticks vs. milliseconds,
  and why a tick-counting bug drifts rather than crashes
- Your own `hal/timer.s` (Lesson 09–11) — the tick source `audio_tick`
  should be driven by

## Success Criteria

- [ ] `audio_play_sequence` returns immediately; the game loop is not
      blocked while a sequence plays
- [ ] Each of the five named sound effects (move, rotate, drop, line
      clear, game over) plays as a distinct, recognizable short sequence
- [ ] A sequence's tempo stays steady from its first note to its last —
      no audible speeding up or slowing down within a single playback
- [ ] Starting a new sequence while one is already playing cleanly
      replaces it, without leaving the old one's tone stuck on
- [ ] `handheld/main.s` still builds cleanly with this module included
