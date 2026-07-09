;******************************************************************************
; spawn_collision_bug.s — Lesson 21 Exercise 2 (Challenge)
;
; Intended behavior: LED1 lands solid. Every one of the three test cases
; below — an open-area baseline, a wall-boundary case, and a spawn-position
; case against a board whose top two rows are already mostly full — should
; have its legality check match the expected result stated next to it.
;
; Build it, flash it, and observe LED1. See exercises/README.md for what
; you should be checking against.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Constants
;==============================================================================
.equ    BOARD_ROWS,         20
.equ    BOARD_COLS,         10
.equ    TEST_PIECE_MASK,    0x000F      ; relative cells (0,0) (0,1) (0,2) (0,3)
.equ    TEST_COUNT,         3

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

main_loop:
    mov.w   #.Ltest_vectors, R5
    mov.w   #TEST_COUNT, R6
    clr.w   R7                          ; 0 = every case has matched so far

.Ltest_loop:
    mov.w   @R5+, R12                   ; row
    mov.w   @R5+, R13                   ; col
    mov.w   @R5+, R14                   ; dx
    mov.w   @R5+, R15                   ; dy
    call    #.Lcan_move                 ; R12 = actual result (1/0)
    mov.w   @R5+, R14                   ; R14 = expected result
    cmp.w   R14, R12
    jeq     .Ltest_pass
    mov.w   #1, R7
.Ltest_pass:
    dec.w   R6
    jnz     .Ltest_loop

    cmp.w   #0, R7
    jz      .Lall_pass
    jmp     .Lblink_forever

.Lall_pass:
    bis.b   #LED1, &P1OUT
    jmp     .Lhalt

.Lblink_forever:
    xor.b   #LED1, &P1OUT
    mov.w   #200, R12
    call    #.Ldelay_ms
    jmp     .Lblink_forever

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; .Lcan_move
; In:  R12=row, R13=col, R14=dx, R15=dy
; Out: R12 = 1 if legal, 0 if not
; Clobbers: R12-R15, borrows R8-R11 (saved/restored)
;==============================================================================
.Lcan_move:
    push    R8
    push    R9
    push    R10
    push    R11

    mov.w   R12, R8
    add.w   R15, R8                     ; R8 = new_row_base
    mov.w   R13, R9
    add.w   R14, R9                     ; R9 = new_col_base
    mov.w   #TEST_PIECE_MASK, R10
    clr.w   R11                         ; R11 = mask bit index i

.Lcm_loop:
    bit.w   #1, R10
    jz      .Lcm_next

    mov.w   R11, R12
    rra.w   R12
    rra.w   R12                         ; R12 = i >> 2 = relative row
    mov.w   R11, R13
    and.w   #3, R13                     ; R13 = i & 3  = relative col
    add.w   R8, R12                     ; R12 = absolute board row
    add.w   R9, R13                     ; R13 = absolute board col

    cmp.w   #0, R12
    jl      .Lcm_illegal
    cmp.w   #BOARD_ROWS, R12
    jge     .Lcm_illegal
    cmp.w   #0, R13
    jl      .Lcm_illegal
    cmp.w   #BOARD_COLS, R13
    jge     .Lcm_illegal
    jmp     .Lcm_next                   ; bounds are good — this cell is clear

    call    #.Lboard_get                ; R12=row,R13=col -> R12=0/1
    cmp.w   #0, R12
    jnz     .Lcm_illegal

.Lcm_next:
    rra.w   R10
    inc.w   R11
    cmp.w   #16, R11
    jl      .Lcm_loop

    mov.w   #1, R12
    jmp     .Lcm_done
.Lcm_illegal:
    clr.w   R12
.Lcm_done:
    pop     R11
    pop     R10
    pop     R9
    pop     R8
    ret

;==============================================================================
; .Lboard_get
; In:  R12=row (0-19), R13=col (0-9)
; Out: R12 = 1 if occupied, 0 if empty
; Clobbers: R12-R14
;==============================================================================
.Lboard_get:
    rla.w   R12
    add.w   #.Lex2_board, R12
    mov.w   @R12, R12
    rla.w   R13
    add.w   #.Lcol_mask, R13
    mov.w   @R13, R13
    and.w   R13, R12
    jz      .Lbg_empty
    mov.w   #1, R12
    ret
.Lbg_empty:
    clr.w   R12
    ret

;==============================================================================
; .Ldelay_ms — busy-wait ~R12 milliseconds at 1 MHz. Arg: R12. Clobbers R13.
;==============================================================================
.Ldelay_ms:
    mov.w   #333, R13
.Ltms_loop:
    dec.w   R13
    jnz     .Ltms_loop
    dec.w   R12
    jnz     .Ldelay_ms
    ret

;==============================================================================
; .Lcol_mask — (1 << col) for col 0..9
;==============================================================================
.Lcol_mask:
    .word   0x0001, 0x0002, 0x0004, 0x0008, 0x0010
    .word   0x0020, 0x0040, 0x0080, 0x0100, 0x0200

;==============================================================================
; .Lex2_board — 20 rows, one word each, bit c = column c. Top two rows are
; already nearly full (row 0 has columns 4-5 open, row 1 is completely
; full); everything below is clear.
;==============================================================================
.Lex2_board:
    .word   0x03CF                              ; row 0  — cols 4-5 open
    .word   0x03FF                              ; row 1  — completely full
    .word   0, 0, 0, 0, 0, 0                    ; rows 2-7
    .word   0, 0, 0, 0, 0, 0                    ; rows 8-13
    .word   0, 0, 0, 0, 0, 0                    ; rows 14-19

;==============================================================================
; .Ltest_vectors — (row, col, dx, dy, expected)
;==============================================================================
.Ltest_vectors:
    .word   10,  3,  0,  0,  1     ; open area                       -> legal
    .word   10,  8,  0,  0,  0     ; piece runs off the right wall   -> illegal
    .word    0,  3,  0,  0,  0     ; spawn overlaps the top two rows -> illegal

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
