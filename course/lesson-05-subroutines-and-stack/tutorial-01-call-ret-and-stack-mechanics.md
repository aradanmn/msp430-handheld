# Tutorial 01 — `call`, `ret`, and Stack Mechanics

## The Stack, Concretely

Every `_start` in this course begins:

```asm
mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
```

`SP` is `R1`. RAM on the G2553 runs from `0x0200` to `0x03FF`, so `0x0400` is
one byte *past* the top of RAM — the stack starts empty, at the highest
address, and **grows downward** as things are pushed onto it. This is the
single fact that everything else in this tutorial follows from.

## `push` and `pop`

`push src` does two things, in this order:

1. Decrement `SP` by 2.
2. Store `src` (a full 16-bit word) at the address `SP` now points to.

`pop dst` does the reverse, in this order:

1. Read the word at the address `SP` currently points to, into `dst`.
2. Increment `SP` by 2.

Two things to notice:

- `push`/`pop` always move 16-bit words, never bytes — the stack is
  word-aligned.
- `SP` always points *at* the most recently pushed word (the "top" of the
  stack), not one past it. A `pop` reads before it advances.

## `call` and `ret`

`call target` does exactly what a `push` of the return address would do,
plus a jump:

1. Decrement `SP` by 2.
2. Store the address of the instruction *after* the `call` (the return
   address) at the address `SP` now points to.
3. Load `PC` (`R0`) with `target` — execution continues there.

`ret` is exactly a `pop` into `PC`:

1. Read the word at the address `SP` currently points to.
2. Increment `SP` by 2.
3. Load `PC` with that word — execution resumes right after the original
   `call`.

This is the entire mechanism. There is no separate "call stack" data
structure — it's the same stack `push`/`pop` use, and `call`/`ret` are just
`push`/`pop` of the program counter with a jump attached.

## Frame Layout Diagram

Say `SP` starts at `0x0400` (empty stack, as `_start` leaves it), and code
does:

```asm
        call    #sub          ; A
sub:
        push    R9            ; B
        push    R8            ; C
        ; ... body ...
        pop     R8            ; D
        pop     R9            ; E
        ret                   ; F
```

Stack contents and `SP` after each lettered step (addresses grow *up* the
page, so `SP` moving down means the stack picture grows *downward* on the
page — shown here with the lowest address at the bottom, matching how the
stack actually grows):

```
Before A:
  SP = 0x0400
  (nothing on the stack)

After A (call #sub):
  0x03FE: [return address]   ← SP = 0x03FE
  ---------------------------
  0x0400: (unused)

After B (push R9):
  0x03FC: [R9's value]       ← SP = 0x03FC
  0x03FE: [return address]
  ---------------------------
  0x0400: (unused)

After C (push R8):
  0x03FA: [R8's value]       ← SP = 0x03FA
  0x03FC: [R9's value]
  0x03FE: [return address]
  ---------------------------
  0x0400: (unused)

After D (pop R8):
  0x03FC: [R9's value]       ← SP = 0x03FC   (R8's old slot is now "stale" —
  0x03FE: [return address]                     still has bytes in it, but no
  ---------------------------                   longer considered part of
  0x0400: (unused)                               the stack)

After E (pop R9):
  0x03FE: [return address]   ← SP = 0x03FE
  ---------------------------
  0x0400: (unused)

After F (ret):
  SP = 0x0400                (back to where we started — balanced!)
  PC  = the instruction right after the original "call #sub"
```

Notice the discipline: every `push` after the `call` has a matching `pop`
*before* the `ret`, in reverse order (last pushed, first popped — R8 was
pushed last, popped first). When that pattern holds, `SP` returns to exactly
the value it had before the `call`, and the word `ret` pops is exactly the
return address `call` pushed. This is not a style preference — it is the
only way `ret` can find the right address.

## What Breaks If a `pop` Is Missing

Now suppose step E (`pop R9`) is accidentally deleted:

```asm
sub:
        push    R9            ; B
        push    R8            ; C
        ; ... body ...
        pop     R8            ; D
        ret                   ; F  ← E is missing!
```

Trace it again:

```
After D (pop R8):
  0x03FC: [R9's value]       ← SP = 0x03FC
  0x03FE: [return address]
  ---------------------------
  0x0400: (unused)

F (ret) reads the word at SP (0x03FC) into PC.
  But 0x03FC holds R9's saved value, NOT the return address!
  SP becomes 0x03FE — still one word short of where it should end up.
```

`ret` doesn't know or care what's actually stored at the address `SP` points
to — it unconditionally loads whatever word is there into `PC` and jumps.
Since the missing `pop` left `SP` pointing one slot too low, `ret` loads
`R9`'s saved value (some arbitrary data the routine happened to be using)
into `PC` instead of the real return address. The processor then starts
executing whatever instruction happens to live at that address — which is
effectively a jump to garbage. Depending on what's there, the chip might
lock up, silently corrupt other memory, or (most commonly, since the
watchdog is running in later lessons) reset.

The dangerous part: the *symptom* only appears at the `ret` — potentially
many instructions, or many calls deep, after the actual mistake (the missing
`pop`). If this routine is called from a loop, it can even *appear to work
correctly* for the first call or two (if the stale leftover data at the
wrong address happens to look like a plausible address) before the mismatch
compounds and the jump finally lands somewhere fatal. This is exactly the
shape of bug Exercise 2 asks you to find: nothing about the code *looks*
wrong at any single line, but the push/pop accounting doesn't balance.

**Rule of thumb:** every `push` inside a subroutine must have exactly one
matching `pop`, on every path through that subroutine, before its `ret`
executes. Count them. If a subroutine has an early-exit branch, make sure
that branch pops everything the earlier code pushed too.
