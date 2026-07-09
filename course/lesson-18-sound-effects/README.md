# Lesson 18 — Sound Effects & Sequencer

## Topic

Lesson 17 gave you one blocking call: play this pitch for this long, then
return. A real game needs several distinct sound effects (piece move,
rotate, drop, line clear, game over) built from *sequences* of notes, and
it needs them to play **without freezing the game** while they do —
`audio_tone_play`'s blocking design can't do that; a two-note jingle would
stall your input polling and rendering for its entire duration.

This lesson builds a small sequencer on top of Lesson 17's tone-generation
layer: a table of (pitch, duration) pairs in Flash, and a `audio_tick`
routine that advances through that table one step at a time, driven by
the same tick interrupt your game loop already runs on — the same pattern
you used for debounce timing back in Lesson 07, applied to music instead
of buttons.

## Learning Objectives

- Design a compact Flash-resident data format for a note sequence (pitch +
  duration pairs, with a sentinel marking the end)
- Build a table of note frequencies across an octave range (C4–B5) using
  `.equ` arithmetic, the same technique from Lesson 17 applied
  systematically to a full scale instead of one note
- Convert a **blocking** "play and wait" routine into a **non-blocking**
  one driven by a periodic tick, so a sound effect can play in the
  background while the game keeps running
- Recognize and avoid off-by-one errors in a tick-counted duration loop —
  the kind of bug that doesn't crash anything, just quietly drifts

## What You'll Build

An example that plays a short fixed melody, note by note, from a table in
Flash — a simpler, blocking preview of the real sequencer your milestone
builds properly.

## Game Connection

This is the last purely-hardware lesson before Part V starts building
Tetris itself. By the end of this lesson your handheld can play a
distinct sound for every major game event: move, rotate, drop, line
clear, and game over — the last piece of feedback a player gets besides
the screen.

## Datasheet References

- SLAU144 Ch 12 — Timer_A (carried over from Lesson 17; no new registers
  this lesson, just a new way of driving the ones you already configured)

## Success Criteria

- [ ] `examples/melody_demo.s` builds, flashes, and plays a recognizable
      short melody through the speaker
- [ ] You can explain, in your own words, why a duration measured in
      "ticks" rather than milliseconds makes a sequencer easy to drive
      from an interrupt that already fires at a fixed rate
- [ ] You can describe what a sentinel value in a Flash table is for, and
      why the sequence-player needs one
