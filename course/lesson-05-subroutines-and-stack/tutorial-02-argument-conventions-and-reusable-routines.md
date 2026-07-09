# Tutorial 02 — Argument Conventions & Reusable Routines

## The Problem With `leds.s`'s Routines

Look at `handheld/hal/leds.s`'s `.Lflash_led`:

```asm
.Lflash_led:
    bis.b   R8, &P1OUT  ; Turn ON LED(s)
    mov.w   R9, R12     ; load delay into R12
    call    #.Ldelay_ms   ; wait X ms
    bic.b   R8, &P1OUT  ; Turn OFF LED(s)
    mov.w   R9, R12     ; load delay into R12
    call    #.Ldelay_ms   ; wait X ms
    ret                 ; return to call
```

This works, and it's a fine shape for a routine that's only ever called from
one place (`leds_test`) with an already-established convention (R8 = mask,
R9 = delay, both set up by the caller ahead of time). But notice its
`.Ldelay_ms` already does exactly what this lesson is about: it takes its
argument in `R12`, is called with `call`, and returns with `ret` — that
*is* the R12–R15 argument convention, just not spelled out as a rule yet.

This lesson makes that convention explicit and applies it to routines that
take their arguments **directly**, rather than relying on a caller to have
pre-loaded specific registers ahead of time by convention with no enforcement.

## The Convention

From `handheld/registers.md` (the rule this entire course follows from here
forward):

| Register | Role | Scope |
|----------|------|-------|
| R12–R15 | Scratch / subroutine arguments | Caller-saved — any `call` may clobber these |
| R4–R11 | Persistent / game state | Callee-saved — a subroutine must `push`/`pop` any of these it borrows |

Two rules fall out of this table:

1. **If you're writing a subroutine that needs an argument, put it in R12
   (and R13, R14, R15 if you need more than one).** Any caller can assume
   these registers survive the call *only if the caller didn't need their
   old values* — because any subroutine is allowed to overwrite R12–R15
   freely, without asking and without restoring them.
2. **If a subroutine needs extra scratch space beyond R12–R15 — say it
   wants to use R7 as a loop counter — it must `push R7` at entry and `pop
   R7` before every `ret`.** R4–R11 belong to the caller (ultimately, in
   the full handheld project, to the ISR), and a subroutine has no right to
   silently overwrite them.

This is not an arbitrary house rule — it's the same split the MSP430 GCC ABI
uses (R12–R15 argument/return/scratch, R4–R11 callee-saved), so
`handheld/registers.md` and this lesson describe the same convention, and if
the project ever links a C-compiled module in, the convention already
matches.

## Designing `delay_ms` and `led_set`

**`delay_ms`** — argument: `R12` = milliseconds to wait. Same cycle-counted
inner-loop shape as `leds.s`'s `.Ldelay_ms` (dec/jnz inner loop tuned to ~1
ms per outer iteration at 1 MHz), except this version's argument comes
straight from whatever the caller put in `R12` — no `mov.w R9, R12` shim
required, because the caller puts the value there directly.

**`led_set`** — arguments: `R12` = LED bitmask, `R13` = on/off (nonzero =
on, zero = off). Internally it has to choose between `bis.b` (turn on) and
`bic.b` (turn off) based on `R13` — a single `bit.w`/`jz`-style test on
`R13`, then the appropriate masked write to `P1OUT`. Because the mask comes
from `R12` rather than being hardcoded to `LED1` or `LED2`, one routine
serves every LED (or combination) you'll ever want to drive — the same
reusability `leds.s`'s `.Lflash_led` almost has, except `.Lflash_led` still
bakes in "flash" (on, delay, off, delay) as one fixed behavior. `led_set`
does one job — set the level — and leaves "flash" as something the *caller*
composes by calling `led_set` and `delay_ms` in sequence.

## Worked Scenario: Why Caller-Saved Is Safe Here — And Where It Stops Being Safe

Suppose a caller has a live value in `R14` that it needs *after* a call to
`led_set`:

```asm
        mov.w   #0x1234, R14   ; caller needs this value later
        mov.b   #LED1, R12
        mov.w   #1, R13
        call    #led_set
        ; ... is R14 still 0x1234 here? ...
```

If `led_set`'s implementation happens not to touch R14 internally, this
works by accident. But the convention says **the caller may not assume
that** — R12–R15 are fair game for any subroutine to clobber, whether or not
this particular implementation happens to. If the caller genuinely needs a
value to survive a `call`, the value does not belong in R12–R15 in the first
place — it belongs in a register the callee-saved rule protects (R4–R11), or
the caller must save it itself (e.g. `push R14` before the call, `pop R14`
after).

Now contrast with the callee-saved side. Suppose `led_set` needed an extra
scratch register beyond R12–R15 — say it wanted to use R7 as a temporary —
and the caller (say, a future `hal/timer.s` ISR) is relying on R7 to hold
persistent frame-counter state across the entire call:

```asm
; caller (future ISR) relies on R7 surviving:
        ; R7 currently holds important persistent state
        call    #led_set
        ; ... caller expects R7 unchanged here ...

; led_set, written WITHOUT saving R7:
led_set:
        mov.w   #0, R7          ; uses R7 as scratch, doesn't save it first!
        ; ... rest of the routine ...
        ret
```

Here `led_set` has silently destroyed the caller's R7 — a register the
convention says belongs to the caller, not to scratch use inside a
subroutine. The caller did nothing wrong; `led_set` broke the rule by using
a callee-saved register without `push`/`pop` around the borrow. This is
exactly why the rule exists: R12–R15 clobbering is *expected and safe*
because callers already know not to keep anything important there across a
`call`; R4–R11 clobbering without save/restore is a bug, because callers
(eventually, the game's ISR) depend on those registers surviving calls they
don't control the internals of. `handheld/registers.md` documents this in
full for the growing project — this lesson's two routines don't happen to
need R4–R11 internally, but the rule is the same one you'll apply the first
time one of your subroutines does.
