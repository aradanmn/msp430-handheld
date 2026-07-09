# Tutorial 02 — Tick-Driven Sequencing and Drift

## Why blocking doesn't scale past one note

`audio_tone_play(period, duration_ms)` from Lesson 17 does everything in
one call: start the tone, busy-wait for the whole duration, stop the
tone, return. That's fine for a single beep, but a five-note line-clear
jingle called this way would freeze your entire game — no input polling,
no rendering, nothing — for as long as the jingle takes to finish. A
real game needs sound to play *alongside* everything else.

## The pattern you already know: driven by a tick, not a wait

This is the same problem Lesson 07's debounce logic solved for buttons,
and the same one your Lesson 11 game loop solved for timing in general:
instead of a subroutine that blocks until something is done, you split
the work into "start it" (returns immediately) and "advance it a little"
(called once per tick, does one small step, and returns immediately too).

```
audio_play_sequence(table_address)   ; starts playing; returns at once
audio_tick()                          ; called once per game tick;
                                       ; advances the sequence by exactly
                                       ; one tick's worth of progress
```

`audio_tick` needs to remember, between calls, which note is currently
playing and how many ticks are left before it should move to the next
one — state that persists across calls the way your debounce state does.
When the remaining-ticks count reaches zero, `audio_tick` loads the next
(period, duration) pair from the table, or — if it reads the sentinel —
silences the output and marks the sequence finished.

## Ticks, not milliseconds

Notice the duration values in a sequence table are naturally counted in
**ticks** (however often your game's tick interrupt fires), not
milliseconds. If your tick fires every N ms, a duration of "200 ms" is
just "200/N ticks" — computed once with `.equ` arithmetic, same as every
other timing constant this course. This is what makes `audio_tick` cheap:
it does a fixed, tiny amount of work each time it's called, driven by an
interrupt that's already firing for other reasons (the same tick that
advances your debounce state and your game's gravity timer).

## Where drift comes from

A tick-counted duration is only as accurate as the counting logic around
it. A duration meant to be exactly N ticks needs to actually consume
exactly N calls to `audio_tick` before advancing — not N−1, not N+1. An
error of a single tick per note might be inaudible on its own, but a
sequencer that makes the same off-by-one mistake on *every* note
accumulates: by the fifth or sixth note in a sequence, a one-tick-per-note
error has become five or six ticks of drift, and a melody that should
keep a steady tempo audibly speeds up or slows down as it plays.

This is exactly the kind of hazard Lesson 04's discussion of status flags
warned you about: a decrement-and-branch loop is only correct if its exit
condition matches how many times you actually intend to run it. Get that
condition subtly wrong and the loop runs one iteration more or fewer than
intended — silently, every single time, with no crash and no one
obviously wrong note. It's the kind of bug you only catch by timing
something that's supposed to take a fixed, predictable amount of time and
noticing that it doesn't.
