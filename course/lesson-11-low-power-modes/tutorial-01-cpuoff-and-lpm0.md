# Tutorial 11.1 — CPUOFF, LPM0, and Two Ways to Wake Up

## What `CPUOFF` actually does

`SR` (the status register) has bits reserved for controlling clock gating
and CPU execution, on top of the arithmetic flags you already know:

```
.equ    CPUOFF,     0x0010      ; bit 4 — CPU off
.equ    OSCOFF,     0x0020      ; bit 5 — Oscillator off
.equ    SCG0,       0x0040      ; bit 6 — System clock gen 0 off
.equ    SCG1,       0x0080      ; bit 7 — System clock gen 1 off
```

Setting `CPUOFF` stops instruction fetch/execute entirely — the CPU is not
"executing a loop that does nothing," it is not executing *anything*.
Compare that to Lesson 10's `.Lspin: jmp .Lspin`: that loop still fetches
and executes a jump instruction every cycle, drawing full active-mode
current the entire time, purely to have *something* running while waiting.
`CPUOFF` removes that waste — the CPU genuinely stops until an interrupt
wakes it.

Different combinations of these bits, plus `SCG0`/`SCG1` (which additionally
gate the DCO and SMCLK), define the four low-power modes this course uses:

```
.equ    LPM0_bits,  CPUOFF                      ; CPU off, clocks running
.equ    LPM1_bits,  SCG0|CPUOFF                 ; CPU + DCO off
.equ    LPM3_bits,  SCG1|SCG0|CPUOFF            ; CPU + DCO + SMCLK off, ACLK on
.equ    LPM4_bits,  SCG1|SCG0|OSCOFF|CPUOFF     ; everything off
```

This lesson uses **LPM0** exclusively: only the CPU stops. SMCLK keeps
running, which means Timer_A keeps counting and can still generate the
interrupt that wakes the CPU back up. (LPM3, which also stops SMCLK and
relies on ACLK to keep a timer alive at much lower power, is previewed for
Lesson 26's battery-life polish — not needed yet, since our tick source is
SMCLK-driven.)

## Entering LPM0 — one instruction, two bits at once

```asm
bis.w   #(GIE|CPUOFF), SR           ; enter LPM0
```

This sets `GIE` and `CPUOFF` in the same instruction, atomically. That
matters: if you set `GIE` and `CPUOFF` in two separate instructions, there's
a window between them where an interrupt could arrive after `GIE` is set but
before `CPUOFF` takes effect — not itself dangerous here, but the combined
form is simpler, is exactly what SLAU144's examples use, and is the pattern
this course always uses for LPM entry. Once this instruction executes, the
CPU is asleep. It won't execute another instruction until an enabled
interrupt fires.

## Two ways an ISR can hand control back

When the sleeping CPU wakes to service an interrupt, hardware pushes the
*sleeping* `SR` (with `CPUOFF` set) onto the stack, same as any interrupt
(Tutorial 10.1). What the ISR does next determines what happens after
`reti`:

**Pattern A — plain `reti` (go right back to sleep):**

```asm
cc0_isr:
    ; ... do the tick's work entirely inside the ISR ...
    reti                     ; restores the saved SR — CPUOFF is still set
                              ; → CPU re-enters LPM0 immediately
```

Use this when the ISR does *everything* the tick needs — no main-loop work
is pending. This is the pattern this lesson's example uses: the ISR
decrements a countdown and toggles an LED entirely within itself, so there's
never anything left for `main` to do after waking.

**Pattern B — clear `CPUOFF` before `reti` (stay awake):**

```asm
cc0_isr:
    ; ... signal that there's work to do (e.g. set a flag, or just fall
    ;     straight through since main resumes right after its LPM0 entry) ...
    bic.w   #CPUOFF, 0(SP)   ; clear CPUOFF in the SAVED SR on the stack
    reti                     ; restores SR without CPUOFF → CPU stays awake
```

Use this when the ISR's job is to *wake the main loop up* so it can do
something the ISR itself shouldn't (or can't cheaply) do — process a full
game frame, update the display, run game logic that doesn't belong in an
ISR's tight timing budget (Tutorial 10.2). After `reti`, execution resumes
in `main` at the instruction right after wherever `bis.w #(GIE|CPUOFF), SR`
was executed — main-line code gets to run once, and if it wants to go back
to sleep, it explicitly re-executes the LPM0-entry instruction itself.

Both patterns are correct MSP430 idioms. Picking between them is a design
decision based on *where* the tick's work belongs — inside the ISR (Pattern
A) or handed off to the main loop (Pattern B) — not a matter of one being
"more correct." Exercise 2 asks you to reason about a design that gets this
choice wrong.

## Check your understanding

1. What's the practical difference, in terms of measured current draw,
   between `.Lspin: jmp .Lspin` (Lesson 10) and `bis.w #(GIE|CPUOFF), SR`
   (this lesson)? Both "do nothing" from the program's point of view.
2. If an ISR ends with a plain `reti` and the CPU was asleep in LPM0 when
   the interrupt fired, what state does the CPU return to?
3. You want the main loop to run a full game-update routine every tick, not
   just toggle a single LED inside the ISR. Which pattern (A or B) do you
   need, and what specifically has to change in the ISR to get it?
