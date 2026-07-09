# Tutorial 01 — Note Tables and Sequence Data in Flash

## From one note to a scale

Lesson 17 computed a single period constant for A4. A sequencer needs many
notes available at once, so you build the same calculation into a small
table, once, covering the range you need (the brief for this lesson
targets C4 through B5 — two full octaves, plenty for short game jingles):

```asm
.equ    SMCLK_HZ,   1000000

.equ    NOTE_C4_HZ, 262
.equ    NOTE_E4_HZ, 330
.equ    NOTE_G4_HZ, 392
.equ    NOTE_C5_HZ, 523

.equ    NOTE_C4,    (SMCLK_HZ/NOTE_C4_HZ)-1
.equ    NOTE_E4,    (SMCLK_HZ/NOTE_E4_HZ)-1
.equ    NOTE_G4,    (SMCLK_HZ/NOTE_G4_HZ)-1
.equ    NOTE_C5,    (SMCLK_HZ/NOTE_C5_HZ)-1
```

Each `NOTE_xx` constant is exactly the period value Lesson 17's
`audio_tone_play` expects — computed once, at assemble time, by name,
instead of as a bare unlabeled number every time you want to play that
pitch. A full C4–B5 table is the same pattern extended to all 24 notes in
that range; standard equal-tempered note frequencies (A4 = 440 Hz is the
universal tuning reference every other note is derived from) are freely
available from any music-theory or tuning reference.

## A sequence is just data

A short melody, encoded as data rather than a series of subroutine calls,
is what makes a sequencer possible. The simplest useful format is a flat
list of (period, duration) word pairs, ending in a sentinel the player can
recognize as "stop here":

```asm
melody:
    .word   NOTE_C4, 200      ; play C4 for 200 (ticks or ms, your choice)
    .word   NOTE_E4, 200
    .word   NOTE_G4, 200
    .word   NOTE_C5, 400
    .word   0                 ; sentinel — 0 is never a valid period, so
                                ; it unambiguously marks "sequence over"
```

Why 0 works as a sentinel: a real note's period is always a large positive
number (thousands, at 1 MHz SMCLK, for anything in a playable range) —
`0` can never occur as a legitimate note period, so a player routine can
safely treat "period read as 0" as "there is no note here, stop."

## Walking the table with auto-increment addressing

Reading pairs out of a table like this is a natural fit for MSP430's
auto-increment indirect addressing mode, which you've had since Lesson 02:

```asm
mov.w   #melody, R14      ; R14 = pointer to the table
...
mov.w   @R14+, R12         ; R12 = period, R14 advances by 2 (one word)
mov.w   @R14+, R13         ; R13 = duration, R14 advances again
```

Each `@R14+` reads the word at the address in `R14` and then advances
`R14` past it — exactly the "walk forward through a list" pattern a
sequence table needs, without any separate index-tracking arithmetic.

## What the milestone's sequence format needs to support

The lesson example plays a melody as one blocking pass through a table
like the one above. The milestone (`hal/audio.s`, extended with a real
sequencer) needs the same table *format* — but played back non-blocking,
one tick at a time, so the game loop never stalls waiting for a jingle to
finish. That's the subject of Tutorial 02.
