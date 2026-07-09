# Tutorial 02 — Status Flags & the Constant Generator

## The four flags

The Status Register (SR / R2) holds, among other things, four arithmetic
flags. From `msp430g2553-defs.s`:

```
;   Bit:  15-9   8    7    6     5      4       3    2    1    0
;         ─────  ─    ─    ─     ─      ─       ─    ─    ─    ─
;         unused V    SCG1 SCG0  OSCOFF CPUOFF  GIE  N    Z    C
```

- **C (bit 0) — Carry.** Set if an addition overflows past bit 15 (a carry
  out of the top of the register), or set/cleared by shift/rotate
  instructions.
- **Z (bit 1) — Zero.** Set if the result of the instruction is exactly
  zero. This is the one `jeq`/`jne` read.
- **N (bit 2) — Negative.** Set if bit 15 of the result is 1 (the result,
  interpreted as signed, is negative).
- **V (bit 8) — Overflow.** Set on signed arithmetic overflow (e.g. adding
  two large positives and getting a result that wraps into negative range).

These are CPU-wide, shared state — there is exactly one copy of SR, and
every flag-setting instruction anywhere in your program, main-line code or
subroutine, ISR or not, writes into that same single register.

## Which instructions touch the flags

Not every instruction updates SR. As a rule for this course:

- **CMP, ADD, SUB, AND, XOR, BIT** (and their variants like ADDC/SUBC) —
  all set C/Z/N/V based on their result.
- **MOV never touches the flags** — a `mov.w #5, R12` leaves SR exactly as
  it was before.
- **BIS and BIC never touch the flags either** — despite being bitwise
  instructions, on the MSP430 they're defined to leave SR alone. This is
  worth committing to memory precisely because it's easy to assume "it's a
  logic instruction, so it must set flags like AND does" — it doesn't.

If you're ever unsure whether a specific instruction affects a flag you're
about to depend on, that uncertainty is itself the warning sign: check
before you rely on it.

## The trap: a call between `cmp` and its branch

Here is the scenario this entire lesson is built around. Picture code that
looks completely reasonable at a glance:

```asm
    cmp.w   #5, R12          ; is R12 == 5?
    call    #some_sub        ; do something before deciding
    jeq     target_reached   ; ... act on the comparison
```

The programmer's intent is clear: compare R12 against 5, then branch based
on that comparison. But `some_sub` is a subroutine — and if its body
contains *any* flag-setting instruction (an `ADD`, a `CMP` of its own, or —
overwhelmingly the most common case — its own internal `dec.w`/`jnz`
counted loop for a delay), then by the time control returns from `call` and
reaches `jeq`, the Z flag no longer reflects `cmp.w #5, R12` at all. It
reflects whatever the *last* flag-setting instruction inside `some_sub`
happened to leave behind.

Walk through a concrete version. Suppose `some_sub` is a delay routine
shaped like `leds.s`'s `.Ldelay_ms`:

```asm
some_sub:
.Lloop:
    dec.w   R13
    jnz     .Lloop
    ret
```

The very last thing that happens before `ret` is `dec.w R13` on the
iteration where `R13` reaches zero — which unconditionally sets **Z = 1**,
regardless of what `R12` or the number 5 were doing. Control returns to the
caller with Z pinned to 1. The `jeq target_reached` that follows will now
**always** be taken — not because R12 ever equaled 5, but because a
completely unrelated loop inside `some_sub` happened to count down to zero
last. If `R12` never equals 5, this bug is silent: the branch still fires,
every single time, and nothing in the source code looks wrong.

This is exactly the shape of bug in `exercises/ex2/flag_clobber_bug.s` —
and exactly what `examples/flag_safe_delay.s` is careful to avoid, by making
the branch decision immediately after the comparison and only calling a
flag-clobbering delay subroutine *after* the branch has already committed.

**The rule:** if a conditional branch depends on a flag, no `call` (and no
other flag-setting instruction) may appear between the instruction that set
that flag and the branch that reads it. Decide first. Call second.

## The constant generator (R3 / CG)

R3 is one of the four CPU-reserved registers (R0=PC, R1=SP, R2=SR, R3=CG).
Unlike R0–R2, R3 has no memory-mapped address and no bits you configure —
it's purely a hardware trick built into the CPU's instruction decode logic.

Conceptually: certain addressing-mode encodings, when they specify R3 (or
R2) as the *source* register, don't actually read a register at all. The
CPU recognizes the specific encoding and substitutes one of a small fixed
set of values — **0, 1, 2, 4, 8, or −1** — directly, without spending an
extra instruction word to hold that immediate and without any real register
access happening in hardware. This is why the assembler can sometimes emit
a shorter, faster instruction for `#1`, `#2`, `#4`, `#8`, `#-1`, or `#0` as
a source operand than it would for an arbitrary immediate like `#7` or
`#333` — the six CG-eligible values are cheaper by construction, not by
luck.

You don't need to memorize an encoding table to use this — the assembler
selects the CG-eligible form automatically whenever you write one of those
six values as a source operand. What's worth internalizing is *why* it
works: it's a property of the CPU's addressing-mode hardware, not a named
register value you load or configure. There is no `.equ` for it in
`msp430g2553-defs.s`, and there doesn't need to be — you're not meant to
reference "the constant generator" by name in your own code, only to
understand that it's quietly at work whenever you see one of those six
immediates.

## Next

`examples/flag_safe_delay.s` puts the branch-before-call rule into practice
as a working, self-testing program. `exercises/ex2` asks you to find a real
instance of the trap in code that looks, at a glance, perfectly reasonable.
