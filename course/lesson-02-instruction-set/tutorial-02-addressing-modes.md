# Tutorial 02 — Addressing Modes

An instruction like `mov.w src, dst` needs to know, for each operand,
*where* to find the value: in a register, baked into the instruction
itself, at a fixed memory address, or computed from a register at run
time. The MSP430 gives you six ways to say this. You've already used two
of them (immediate and absolute) without the formal name; this tutorial
covers all six.

## Register mode

```asm
mov.w   R5, R6      ; R6 = R5
```

The operand is simply a register's contents. No memory access happens —
this is the fastest addressing mode. If `R5 = 0x1234` before this
instruction, `R6 = 0x1234` after, and R5 is unchanged.

## Immediate mode — `#`

```asm
mov.w   #5, R6      ; R6 = 5 (the literal number 5, not memory address 5)
```

The `#` prefix means "this is a literal constant baked into the
instruction," not an address. You've used this in every boilerplate line:
`mov.w #0x0400, SP` sets SP to the literal value `0x0400`, and `mov.w
#(WDTPW|WDTHOLD), &WDTCTL` computes the OR of two `.equ` constants at
assemble time and uses *that* as the literal source.

## Absolute / symbolic mode — `&NAME`

```asm
bis.b   #LED1, &P1OUT   ; set LED1's bit at the fixed address named P1OUT
```

The `&` prefix means "read/write memory at this address," where the
address is either a literal number or — far more commonly in this course —
a name defined with `.equ` in `msp430g2553-defs.s`. `P1OUT` is `.equ`'d to
`0x0021`; when the assembler sees `&P1OUT` it substitutes the address
`0x0021` and emits an absolute-address memory access. This is exactly what
every peripheral register access in Lessons 01 and 02 has done — `&WDTCTL`,
`&P1DIR`, `&DCOCTL` are all absolute addresses reached via names the
assembler resolves for you.

## Indexed mode — `n(Rn)`

```asm
mov.w   2(R5), R6    ; R6 = the word stored at address (R5 + 2)
```

Indexed mode adds a constant offset to a base register to compute the
address to access — the base register itself is unchanged. This is the
natural way to reach a fixed field inside a structure, or a fixed offset
into a table, when the base address is already sitting in a register. If
`R5` holds the address of a 4-entry word table, `2(R5)` reaches the second
entry (each word being 2 bytes) without needing a second pointer register.

## Indirect mode — `@Rn`

```asm
mov.b   @R5, R12     ; R12's low byte = the byte at the address stored in R5
```

`@R5` means "R5 holds an address; use *that* as the memory location," as
opposed to `R5` (register mode, use R5's value directly) or `&R5` (which
isn't valid syntax — `&` is for named/absolute addresses, not registers).
Indirect mode is indexed mode with an implicit offset of zero — `@R5` is
equivalent to `0(R5)`.

## Indirect-autoincrement mode — `@Rn+`

```asm
mov.b   @R5+, R12    ; R12 = byte at [R5]; THEN R5 = R5 + 1 (byte) or +2 (word)
```

This is indirect mode with a side effect: after the access completes, the
CPU automatically advances the pointer register by the size of the access —
1 for `.b`, 2 for `.w`. This is the standard MSP430 idiom for walking
through an array or table one entry at a time without a separate increment
instruction. You'll use it in this lesson's example to walk a 4-entry LED
pattern table, and again in Lesson 08 (framebuffer) and Lesson 10 (sprite
tables) to walk much larger structures the same way.

## Worked trace — walking a table with `@R5+`

Suppose Flash contains a 4-entry byte table:

```asm
pattern_table:
    .byte   0x00     ; entry 0 — address A
    .byte   0x01     ; entry 1 — address A+1
    .byte   0x40     ; entry 2 — address A+2
    .byte   0x41     ; entry 3 — address A+3
```

and a pointer register is initialized with the table's base address using
symbolic absolute addressing:

```asm
mov.w   #pattern_table, R5   ; R5 = A (the address of pattern_table)
```

Now hand-trace three iterations of `mov.b @R5+, R12`:

| Before instruction | Read from address | R12 after | R5 after |
|---|---|---|---|
| R5 = A | A | `0x00` | A + 1 |
| R5 = A + 1 | A + 1 | `0x01` | A + 2 |
| R5 = A + 2 | A + 2 | `0x40` | A + 3 |

Each iteration: the byte at the address currently in R5 is loaded into
R12, and only *afterward* does R5 advance by 1 (since this is a `.b`
access). A fourth iteration would read entry 3 (`0x41`) and leave R5 at
A + 4 — one past the last entry, which is why a real loop needs to compare
R5 against the table's end address (or a fixed count) and reset R5 back to
`pattern_table` to repeat the sequence, rather than reading forever past
the table's last byte.
