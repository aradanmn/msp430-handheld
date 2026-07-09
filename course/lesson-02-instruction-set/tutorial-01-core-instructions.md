# Tutorial 01 — Core Instructions

You've already used `mov.w`, `mov.b`, `bis.b`, and `bic.b` in every L01
boilerplate line without a formal introduction. This tutorial names what
they (and their close relatives) do, one at a time, then puts three of them
together in a hand trace.

Every instruction below has the general form:

```
INSTR.suffix  src, dst
```

`src` is read; `dst` is both read (if the operation needs the old value)
and written (except where noted). `.suffix` is `.b` (byte, 8 bits) or `.w`
(word, 16 bits) — more on that at the end of this tutorial.

## MOV — copy, no flags

```asm
mov.w   R5, R6      ; R6 = R5 (R5 unchanged)
mov.b   #0x05, R12  ; R12's low byte = 0x05
```

`MOV` copies `src` into `dst`. It does **not** affect any status flags —
this matters later when you chain a `MOV` before a conditional branch and
need to remember the branch is testing whatever instruction ran *before*
the `MOV`, not the `MOV` itself.

## ADD / SUB — arithmetic

```asm
add.w   R5, R6      ; R6 = R6 + R5
sub.w   R5, R6      ; R6 = R6 - R5
```

`ADD` and `SUB` do ordinary arithmetic and, unlike `MOV`, **do** update the
status flags — Carry (C), Zero (Z), Negative (N), and Overflow (V). You
already know these bits exist (they're documented in `msp430g2553-defs.s`
next to the `SR` layout); this lesson doesn't need you to reason about them
yet. Lesson 04 covers flags and conditional branches in depth. For now,
just know: after an `ADD`/`SUB`, the flags reflect the result, and `MOV`
never disturbs them.

## AND / OR / XOR — bitwise

```asm
and.b   #0x0F, R12  ; R12 = R12 & 0x0F  (keep only the low nibble)
or.b    #0x80, R12  ; R12 = R12 | 0x80  (force bit 7 on)
xor.b   #0xFF, R12  ; R12 = R12 ^ 0xFF  (flip every bit)
```

These write the bitwise result back into `dst`, updating flags along the
way. `AND`/`OR` can do exactly what `BIC`/`BIS` do (see below) — the
difference is in the mask you supply and which idiom the rest of this
codebase uses.

## BIC / BIS — the "clear specific bits" / "set specific bits" idioms

You've been writing these since Lesson 01:

```asm
bis.b   #(LED1|LED2), &P1DIR   ; P1DIR |=  (LED1|LED2)  — set those bits
bic.b   #(LED1|LED2), &P1OUT   ; P1OUT &= ~(LED1|LED2)  — clear those bits
```

Formally: `BIS #mask, dst` sets every bit that's 1 in `mask`, leaving all
other bits of `dst` untouched. `BIC #mask, dst` clears every bit that's 1 in
`mask`, leaving all other bits untouched.

Contrast with `AND`/`OR`: `OR #mask, dst` and `BIS #mask, dst` do the exact
same bit-level operation — but by convention this course (and the MSP430
idiom generally) reaches for `BIS`/`BIC` whenever the intent is "touch these
specific bits of a shared peripheral register," and reserves `AND`/`OR` for
general-purpose arithmetic-flavored bit twiddling (masking off a nibble,
merging two values). The reason: `BIC #mask, dst` reads as "clear this
mask" directly. To do the same thing with `AND` you'd have to invert the
mask yourself (`AND #~mask, dst`), which is easy to get wrong by hand. When
you see `BIS`/`BIC` in this codebase, the mask you pass **is** the set of
bits being touched — no inversion required.

## BIT — test without writing

```asm
bit.b   #BTN, R12   ; test whether the BTN bit is set in R12; R12 unchanged
```

`BIT #mask, dst` computes `mask & dst` — exactly like `AND` — but throws the
result away and only keeps the flags. `Z` is set to 1 if `mask & dst == 0`
(none of the tested bits are set) and 0 otherwise (at least one tested bit
is set). This is the standard way to ask "is this bit on?" without
disturbing the register you're testing — critical when that register is a
live hardware status register you don't want to accidentally clear or
modify by writing to it.

## CMP — subtract without storing

```asm
cmp.w   #4, R12     ; compute R12 - 4, keep only the flags; R12 unchanged
```

`CMP src, dst` computes `dst - src` and discards the numeric result,
keeping only the flags. This is what every conditional branch after it
keys off — `jeq`/`jz` branches if the subtraction produced zero (`dst ==
src`), `jne`/`jnz` if it didn't, and so on. Lesson 04 covers the full set of
conditional branches and flag semantics; for now, just recognize `CMP` as
"the `SUB` you use when you only want to compare, not modify."

## Byte (`.b`) vs. word (`.w`)

The MSP430 CPU registers (R4-R15) are 16 bits wide, but many peripheral
registers are only 8 bits wide. `P1OUT`, `P1DIR`, `P1IN`, and every other
Port 1/2 register are byte-wide — writing to them with `.b` touches exactly
the 8 bits that exist. Using `.w` on an 8-bit peripheral register is a bug:
it reads or writes a phantom second byte that either doesn't exist or
belongs to an unrelated adjacent register.

Some peripheral registers — `TACTL`, `WDTCTL`, `TACCR0` (Timer_A, covered
starting Lesson 04) — are genuinely 16 bits wide and need `.w`. The rule is
simple: match the suffix to the width of the register you're touching, not
to habit. When in doubt, `msp430g2553-defs.s` tells you: every `.equ` is
commented with the register's bit width.

## Worked trace

Given this sequence, starting from R12 in an unknown state:

```asm
mov.b   #0x05, R12   ; step 1
add.b   #0x03, R12   ; step 2
bit.b   #0x08, R12   ; step 3
```

**Step 1 — `mov.b #0x05, R12`.** R12's low byte is set to `0x05` (`0000
0101`). `MOV` doesn't touch flags, so whatever Z was before is still
whatever it was.

**Step 2 — `add.b #0x03, R12`.** `0x05 + 0x03 = 0x08` (`0000 0101 + 0000
0011 = 0000 1000`). R12's low byte is now `0x08`. The result is nonzero, so
`Z = 0` after this instruction.

**Step 3 — `bit.b #0x08, R12`.** This computes `0x08 & 0x08 = 0x08` and
keeps only the flag result — R12 is **not** modified by `BIT`, it's still
`0x08` from step 2. Since `0x08 & 0x08 = 0x08` (nonzero), `Z = 0`. In plain
language: "is bit 3 of R12 set?" — yes, so the test result is nonzero and Z
comes out 0 (the MSP430 convention: `BIT` sets `Z = 1` only when *all*
masked bits are 0 — i.e. when the tested bits are absent).

Final state: **R12 = 0x08, Z = 0**.

Try re-running the trace by hand with `bit.b #0x10, R12` as step 3 instead
(testing bit 4, which is 0 in `0x08`) and confirm you get `Z = 1`.
