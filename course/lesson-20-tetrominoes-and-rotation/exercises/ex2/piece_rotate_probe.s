#include "../../../common/msp430g2553-defs.s"

;******************************************************************************
; piece_rotate_probe.s — Lesson 20 Exercise 2 (Challenge)
;
; Intended behavior: starting at rotation 0, this program advances the
; encoded T-piece through six rotation steps in a row. Before each advance,
; it checks whether the piece's current rotation word matches one of the
; four words encoded in piece_table for this shape. Every step is expected
; to still land on one of those four valid encodings.
;
; Build it, flash it, and watch LED1. See exercises/README.md for what you
; should be checking against.
;******************************************************************************

    .text
    .global _start

.equ    NUM_ROTATIONS,      4
.equ    ROTATION_STEPS,     6      ; advance six times in a row

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    mov.w   #0, R4                       ; R4 = current rotation index
    mov.w   #ROTATION_STEPS, R5          ; R5 = remaining steps

check_current:
    mov.w   R4, R12
    call    #piece_word_for_rotation     ; R12 = word at piece_table+rotation*2
    call    #word_is_valid               ; R12 in, R12 = 1/0 out
    cmp.w   #0, R12
    jz      fail

    mov.w   R4, R12
    call    #piece_next_rotation         ; R12 = advanced rotation index
    mov.w   R12, R4

    dec.w   R5
    jnz     check_current

pass:
    bis.b   #LED1, &P1OUT
.Lpass_hold:
    jmp     .Lpass_hold

fail:
.Lfail_loop:
    xor.b   #LED1, &P1OUT
    mov.w   #20000, R12
    call    #delay_loop
    jmp     .Lfail_loop

;==============================================================================
; delay_loop — busy-waits ~R12 iterations
;==============================================================================
delay_loop:
.Ldelay:
    dec.w   R12
    jnz     .Ldelay
    ret

;==============================================================================
; piece_word_for_rotation(rotation) -> word
;   R12 = rotation index (in); R12 = 16-bit rotation word (out)
;==============================================================================
piece_word_for_rotation:
    rla.w   R12                         ; R12 = rotation*2 (byte offset)
    mov.w   piece_table(R12), R12
    ret

;==============================================================================
; piece_next_rotation(rotation) -> new_rotation
;   R12 = current rotation index (in); R12 = next rotation index (out)
;==============================================================================
piece_next_rotation:
    inc.w   R12
    ret

;==============================================================================
; word_is_valid(word) -> 1 if word matches one of the four encoded rotation
; states for this piece, 0 otherwise.
;   R12 = word to check (in/out)
;==============================================================================
word_is_valid:
    mov.w   #reference_table, R14
    mov.w   #NUM_ROTATIONS, R15
.Lcheck_loop:
    cmp.w   @R14, R12
    jeq     .Lvalid
    incd.w  R14
    dec.w   R15
    jnz     .Lcheck_loop
    mov.w   #0, R12
    ret
.Lvalid:
    mov.w   #1, R12
    ret

;==============================================================================
; T-piece rotation table (rotations 0-3), plus other Flash data stored
; immediately after it.
;==============================================================================
piece_table:
    .word   0x04E0, 0x4640, 0x0720, 0x0262
    .word   0x1234                       ; unrelated constant, stored here

reference_table:
    .word   0x04E0, 0x4640, 0x0720, 0x0262

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
