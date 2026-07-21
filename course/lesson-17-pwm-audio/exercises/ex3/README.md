# Exercise 3 (Milestone) — Create `handheld/hal/audio.s`

## Behavior Required

A module that generates a fixed-frequency tone for a fixed duration,
through the LM386/speaker on P2.4 (Timer1_A3, CCR2), then falls silent.
Silence at rest — no sound plays until explicitly requested. Playing one
tone and then another must produce two clearly distinct, audible pitches.

`audio_tone_play` takes a **period**, not a frequency in Hz — see the
lesson's tutorials for why (no hardware divider on this chip; compute the
period from a desired frequency using `.equ` arithmetic at assemble time,
same as [`wiring/phase-4-audio.md`](https://github.com/aradanmn/Handheld-MSP430/blob/main/wiring/phase-4-audio.md)'s worked examples).

## Public Interface

```
audio_init            ; no args. Configure P2.4/TA1.2 and Timer1_A3 for
                       ; PWM output. Silent at rest — call once at startup.

audio_tone_play       ; R12 = timer period (the TACCR0-equivalent value
                       ; for the desired frequency, precomputed by the
                       ; caller). R13 = duration in milliseconds.
                       ; Blocking: plays a square wave at that period for
                       ; the given duration, then silences the output and
                       ; returns to the caller.
```

## Reference Material

- [`wiring/phase-4-audio.md`](https://github.com/aradanmn/Handheld-MSP430/blob/main/wiring/phase-4-audio.md) — wiring + the frequency/period formula
- SLAU144 Ch 12 — Timer_A up mode, compare/output modes
- Lesson 17 tutorials — OUTMOD_7, and why the period argument is a period,
  not a frequency

## Success Criteria

- [ ] `audio_init` leaves the speaker silent until a tone is requested
- [ ] `audio_tone_play` with a period corresponding to a known note (e.g.
      A4) plays that note audibly at the correct pitch for the requested
      duration, then goes silent
- [ ] Two back-to-back calls with different periods produce two clearly
      distinguishable pitches
- [ ] `handheld/main.s` still builds cleanly with this module included
