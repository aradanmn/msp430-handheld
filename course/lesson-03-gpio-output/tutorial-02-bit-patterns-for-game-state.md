# Tutorial 02 — Bit Patterns for Game State

## Game States Are Just Numbers

LED1 and LED2 together can express four distinct on/off combinations — and
each combination is exactly one byte value in `P1OUT`'s bits 0 and 6:

| LED1 (bit 0) | LED2 (bit 6) | Byte value (bits 6,0 only) | Could mean... |
|:---:|:---:|:---:|---|
| off | off | `0x00` | attract / idle |
| on  | off | `0x01` | ready |
| off | on  | `0x40` | (unused here, but available) |
| on  | on  | `0x41` | game-over flash |

Notice the last column isn't derived from anything clever — it's `LED1`,
`LED2`, or `LED1|LED2` from `msp430g2553-defs.s`, exactly as you'd write in
a `bis.b`. The point of this tutorial is that once you have a small,
*fixed* set of states like this, you don't have to hand-write a `bis.b`
and `bic.b` pair for every state transition. You can put the states in a
table and let an index pick one.

## Why a Table Beats a Chain of If/Else

Recall from Lesson 02 how a table of values plus an index (a memory
address plus an offset) lets you look up data instead of branching to find
it. The same idea applies to LED patterns.

Without a table, adding a fourth named state to a sequence means adding
another branch:

```asm
    cmp.w   #0, R10
    jeq     .Lstate_attract
    cmp.w   #1, R10
    jeq     .Lstate_ready
    cmp.w   #2, R10
    jeq     .Lstate_gameover
    ; ...and a fourth cmp/jeq pair for every new state you add
```

Every new state costs you another `cmp`/`jeq` pair, and the list of
compares has to be kept in sync with however many states exist. With a
table, adding a state means adding one row of data — the code that walks
the table doesn't change size or shape no matter how many states you add:

```asm
    ; state_patterns: one byte per state — the P1OUT bits for that state
state_patterns:
    .byte   0x00        ; attract: both off
    .byte   0x01        ; ready:   LED1 only
    .byte   0x41        ; game-over: both on (paired with fast XOR flashing)

    ; ...elsewhere, walking the table with an index in a register:
    mov.b   state_patterns(R10), R11   ; R11 = pattern byte for state R10
```

The tutorial isn't asking you to write this exact table for the example —
`examples/led_patterns.s` demonstrates one full working approach — but the
principle (data table + index, rather than a branch per state) is what
separates code that's easy to extend from code that grows a new `cmp`/`jeq`
every time a designer adds one more game state.

## XOR Toggle vs BIS/BIC Pairs — When Each Fits

Two idioms for changing an LED's state, and they solve different problems:

**BIS/BIC pair** — use when you know the *exact* target state and want to
set it regardless of what it was before:
```asm
bis.b   #LED1, &P1OUT      ; force LED1 ON, no matter what it was
...
bic.b   #LED1, &P1OUT      ; force LED1 OFF, no matter what it was
```
This is what you want for "ready" (LED1 must be *on*, full stop) or
"attract" (both must be *off*, full stop) — the state doesn't care about
history.

**XOR toggle** — use when you want to *flip* the current state without
needing to track what it is:
```asm
xor.b   #(LED1|LED2), &P1OUT   ; whatever LED1/LED2 were, they're now the
                                 ; opposite
```
This is the natural fit for a "flashing" pattern — you don't need a
separate on-phase and off-phase branch; the same instruction alternates the
LEDs each time it runs inside a loop, because the bit it's flipping is
different each time the loop calls it.

The tradeoff: XOR only makes sense when you don't need to *force* a known
starting state first. If a flashing pattern needs to start from a
guaranteed OFF state (so the very first flash reliably turns the LED *on*,
not off), you still need one `bic.b` to establish the starting point before
the XOR loop begins.

## Worked Scenario: Sequencing States With Different Hold Times

Suppose the design calls for: attract (slow blink) held for 2 seconds,
then ready (solid LED1) held for 1 second, then game-over (fast flash)
held for 1.5 seconds, then repeat forever. Each state has its own pattern
*and* its own hold duration and its own "how it animates while held"
(steady vs blinking vs flashing at a different rate).

With a table-driven approach, the *loop structure* that walks through
attract → ready → game-over → repeat doesn't need to know anything
peculiar about any one state — it just needs, for each state: the pattern
byte, how long to hold it, and whether it's static or blinking/flashing
while held. Add a fourth state later (say, a "paused" indicator) and the
walking code is unchanged — only the table grows by one entry. Compare
that to a hand-unrolled version with three separate blocks of
`bis.b`/`bic.b`/delay code repeated with slightly different constants each
time: correct, but every future state means copy-pasting and re-editing an
entire block, and a typo in the copy is easy to miss.

`examples/led_patterns.s` demonstrates one concrete version of this idea end
to end — study it after you've worked through the exercises.
