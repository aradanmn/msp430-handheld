# Tutorial 02 — Polling Loops

## The polling-loop pattern

Every program you've written so far runs on a fixed script: do this, wait,
do that, repeat. Reading an input changes the shape of the program, because
now the CPU's next action depends on something happening *outside* itself.
The simplest way to make that connection is a **polling loop**: an infinite
loop that repeatedly samples an input register and reacts immediately based
on what it sees.

```asm
.Lpoll:
    bit.b   #BTN, &P1IN      ; Z=1 if button is pressed (active-low)
    jz      .Lpressed
    ; ... handle "released" ...
    jmp     .Lpoll
.Lpressed:
    ; ... handle "pressed" ...
    jmp     .Lpoll
```

Structurally this is nothing new — it's the same infinite-loop idiom you've
used since Lesson 01, with a conditional branch added at the top. What's new
is the *meaning*: this loop's entire job, forever, is to keep asking "what's
the input doing right now?" as fast as it possibly can, and respond without
delay.

## The tradeoff: polling ties up the CPU

Notice what the CPU is doing between one sample and the next: nothing else.
It samples, it branches, it (maybe) updates an LED, and it immediately goes
back to sampling again. For a program whose *only* job is watching one
button and driving one LED, that's completely fine — there's nothing else
for the CPU to do anyway.

But it won't stay that simple. Later in this course the handheld will need
to read input, update game state, redraw a display, and generate audio, all
while staying responsive — and a CPU stuck in a tight polling loop can't do
those other things in between samples. Lesson 10 introduces **interrupts**,
which flip this relationship around: instead of the CPU repeatedly asking
"has anything happened yet?", the hardware itself notifies the CPU only
when something actually changes, freeing the CPU to do other work the rest
of the time. That's a forward pointer only — for now, polling is the right
tool, because it's the simplest one that works, and understanding exactly
what it costs you is what will make interrupts click later.

## Contact bounce: the signal isn't as clean as the model

Tutorial 01 walked through button state as if it changes in one clean
instant: released, then *pressed*, full stop. Electrically, that is not
what actually happens. A mechanical switch has physical metal contacts that
have to move and touch. When they first make (or break) contact, they don't
settle immediately — they physically vibrate, bouncing apart and together
again several times over the space of a few milliseconds, before finally
coming to rest in their new state.

A rough picture of what P1.3's voltage actually looks like across a single
physical press, if you zoomed a scope in far enough:

```
released (high) ─┐   ╭╮ ╭─╮
                  │   ││ │ │
                  └───┘╰─╯ └────────────── pressed (low, settled)
                  ↑
             first contact — looks like several
             quick down-up-down transitions before
             it settles low and stays there
```

To your eye and finger, that's one clean press. To a polling loop reading
`P1IN` fast enough — and even a simple `bit.b`/`jz` loop with no delay reads
comfortably faster than a few milliseconds — it looks like several
independent press-then-release-then-press events, each one just as "real"
as far as the CPU can tell, because `P1IN` has no memory: every read is a
fresh, independent snapshot (Tutorial 01). The loop has no way to know
"this is still the same physical press as last time I checked" unless you
give it one.

## Why this breaks a toggle-on-press LED

Imagine a program that, instead of mirroring the button's live level onto
LED1, *toggles* LED1 each time it detects a **new** press — that is, each
time it sees the input transition from released to pressed (not just "is
currently pressed," but "just became pressed since last time I looked").
That's a reasonable, common thing to want: "press the button to switch
state," rather than "the LED matches whether my finger happens to be on the
button right now."

Now play the bounce waveform above through that logic. The first
down-transition looks like a new press — toggle #1. The bounce back up
looks like a release. The next down-bounce looks like *another* new press —
toggle #2. If the bounce happens to have an odd number of transitions
before settling, you get an odd number of toggles for one physical press
(the LED lands where you'd expect, but flickered on the way). If it happens
to have an even number, you get an even number of toggles (the LED can end
up in the exact opposite state from what the player intended, having
"cancelled itself out"). Which one happens is not something you control or
can predict — it depends on microscopic mechanical details of that
particular press, that particular switch, even the ambient temperature.

This is precisely the failure mode Lesson 06's Exercise 1 asks you to go
observe directly, and Exercise 2 asks you to do something about, using only
the tools you have right now (polling and delay loops — no timer
peripheral, no interrupts). Lesson 07 will come back and replace whatever
you build in Exercise 2 with a proper, non-blocking, tick-based debounce
technique — so don't feel like Exercise 2 needs to be a permanent,
production-grade answer. It needs to work, and it needs to teach you
exactly what problem you're solving before you get a more powerful tool to
solve it with.

## Reference

SLAU144 Chapter 8 (Digital I/O) again — the register descriptions don't
mention bounce (it's a mechanical property of the switch, not something the
digital I/O peripheral does), but re-reading `PxIN` with this lesson's
waveform in mind is worth doing once.
