#include "../../../common/msp430g2553-defs.s"

;******************************************************************************
; board_probe.s — Lesson 19 Exercise 2 (Challenge)
;
; Intended behavior: this program builds the same packed-bit board from the
; lesson (board_init / board_get / board_set), then runs a short sequence of
; calls representative of how later game code (piece-placement checks,
; Lesson 21) will use these routines. After the sequence runs, it re-reads
; two cells it expects to still hold known values, and also re-checks a
; value stored in RAM immediately after the board array. If everything
; still matches, LED1 lights solid. If anything doesn't match, LED1 blinks.
;
; Build it, flash it, and watch LED1. See exercises/README.md for what
; you should be checking against.
;******************************************************************************

    .text
    .global _start

.equ    BOARD_ROWS,     20
.equ    BOARD_COLS,     10
.equ    BOARD_BITS,     (BOARD_ROWS * BOARD_COLS)
.equ    BOARD_BYTES,    ((BOARD_BITS + 7) / 8)
.equ    CHECK_VALUE,    0x2A            ; sentinel value checked at the end

    .bss
board:
    .skip   BOARD_BYTES
check_byte:
    .skip   1

    .text

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    call    #board_init
    mov.b   #CHECK_VALUE, &check_byte

    ; populate a couple of real board cells, the way a piece-placement
    ; routine would
    mov.w   #5, R12
    mov.w   #3, R13
    mov.w   #1, R14
    call    #board_set

    mov.w   #5, R12
    mov.w   #4, R13
    mov.w   #1, R14
    call    #board_set

    ; a cell check arriving already past the right edge of the board --
    ; the kind of coordinate a piece/rotation offset calculation can
    ; produce before a later lesson's bounds check runs in front of it
    mov.w   #19, R12
    mov.w   #13, R13
    mov.w   #1, R14
    call    #board_set

    ; --- verification ---
    mov.w   #5, R12
    mov.w   #3, R13
    call    #board_get
    cmp.w   #1, R12
    jnz     fail

    mov.w   #5, R12
    mov.w   #4, R13
    call    #board_get
    cmp.w   #1, R12
    jnz     fail

    cmp.b   #CHECK_VALUE, &check_byte
    jnz     fail

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
; board_init — clears every byte of the board to 0
;==============================================================================
board_init:
    mov.w   #0, R15
.Linit_loop:
    clr.b   board(R15)
    inc.w   R15
    cmp.w   #BOARD_BYTES, R15
    jnz     .Linit_loop
    ret

;==============================================================================
; board_get(row, col) -> filled       R12=row, R13=col (in); R12=1/0 (out)
;==============================================================================
board_get:
    mov.w   R12, R14
    rla.w   R12
    rla.w   R14
    rla.w   R14
    rla.w   R14
    add.w   R14, R12
    add.w   R13, R12                    ; R12 = bit_index

    mov.w   R12, R13
    and.w   #0x0007, R13
    mov.w   #7, R14
    sub.w   R13, R14                    ; R14 = bit_pos
    rra.w   R12
    rra.w   R12
    rra.w   R12                         ; R12 = byte_offset

    mov.w   R14, R13
    mov.b   #0x01, R14
.Lget_shift:
    tst.w   R13
    jz      .Lget_shift_done
    rla.b   R14
    dec.w   R13
    jmp     .Lget_shift
.Lget_shift_done:

    bit.b   R14, board(R12)
    jz      .Lget_zero
    mov.w   #1, R12
    ret
.Lget_zero:
    mov.w   #0, R12
    ret

;==============================================================================
; board_set(row, col, val)        R12=row, R13=col, R14=val (in)
;==============================================================================
board_set:
    mov.w   R12, R15
    rla.w   R12
    rla.w   R15
    rla.w   R15
    rla.w   R15
    add.w   R15, R12
    add.w   R13, R12                    ; R12 = bit_index

    mov.w   R12, R13
    and.w   #0x0007, R13
    mov.w   #7, R15
    sub.w   R13, R15                    ; R15 = bit_pos
    rra.w   R12
    rra.w   R12
    rra.w   R12                         ; R12 = byte_offset

    mov.w   R15, R13
    mov.b   #0x01, R15
.Lset_shift:
    tst.w   R13
    jz      .Lset_shift_done
    rla.b   R15
    dec.w   R13
    jmp     .Lset_shift
.Lset_shift_done:

    tst.w   R14
    jz      .Lset_clear
    bis.b   R15, board(R12)
    ret
.Lset_clear:
    bic.b   R15, board(R12)
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
