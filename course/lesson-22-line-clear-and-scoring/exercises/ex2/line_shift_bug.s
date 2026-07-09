;******************************************************************************
; line_shift_bug.s — Lesson 22 Exercise 2 (Challenge)
;
; Intended behavior: LED1 lands solid. The board below has exactly one
; full row (row 6). Detecting it, clearing it, and shifting everything
; above it down by one should produce a resulting board that exactly
; matches the hand-computed expected result.
;
; Build it, flash it, and observe LED1. See exercises/README.md for what
; you should be checking against.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Constants
;==============================================================================
.equ    BOARD_ROWS,          20
.equ    BOARD_COLS,          10
.equ    BOARD_BYTES,         25
.equ    RAM_BOARD,           0x0200
.equ    EXPECTED_FULL_ROW,   6
.equ    EXPECTED_FULL_COUNT, 1

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
    mov.w   #.Lboard_template, R14
    mov.w   #RAM_BOARD, R15
    mov.w   #BOARD_BYTES, R13
.Lcopy_loop:
    mov.b   @R14+, 0(R15)
    inc.w   R15
    dec.w   R13
    jnz     .Lcopy_loop

    clr.w   R6
    mov.w   #-1, R5
    clr.w   R12
.Lscan_loop:
    push    R12
    call    #.Lrow_full
    mov.w   R12, R13
    pop     R12
    cmp.w   #0, R13
    jz      .Lscan_next
    inc.w   R6
    mov.w   R12, R5
.Lscan_next:
    inc.w   R12
    cmp.w   #BOARD_ROWS, R12
    jl      .Lscan_loop

    cmp.w   #EXPECTED_FULL_COUNT, R6
    jne     .Lfail
    cmp.w   #EXPECTED_FULL_ROW, R5
    jne     .Lfail

    mov.w   R5, R12
    call    #.Lclear_line

    mov.w   #RAM_BOARD, R14
    mov.w   #.Lboard_expected_after, R15
    mov.w   #BOARD_BYTES, R13
.Lcmp_loop:
    mov.b   @R14+, R12
    mov.b   @R15+, R9
    cmp.b   R9, R12
    jne     .Lfail
    dec.w   R13
    jnz     .Lcmp_loop

    bis.b   #LED1, &P1OUT
    jmp     .Lhalt

.Lfail:
    xor.b   #LED1, &P1OUT
    mov.w   #200, R12
    call    #.Ldelay_ms
    jmp     .Lfail

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; .Lrow_full
; In:  R12 = row index (0-19)
; Out: R12 = 1 if that row's 10 columns are all occupied, else 0
; Clobbers: R12-R15
;==============================================================================
.Lrow_full:
    mov.w   R12, R14
    mov.w   R12, R13
    rla.w   R14                         ; row*2
    rla.w   R13                         ; row*2
    rla.w   R13                         ; row*4
    rla.w   R13                         ; row*8
    add.w   R14, R13                    ; row*10 = base_bit

    mov.w   R13, R14
    and.w   #7, R14                     ; bit_off
    rra.w   R13
    rra.w   R13
    rra.w   R13                         ; byte_idx

    mov.w   #RAM_BOARD, R15
    add.w   R13, R15
    mov.b   @R15, R12
    mov.b   1(R15), R13
    swpb    R13
    bis.w   R13, R12                    ; R12 = word16

    tst.w   R14
    jz      .Lrf_shifted
.Lrf_shift_loop:
    rra.w   R12
    dec.w   R14
    jnz     .Lrf_shift_loop
.Lrf_shifted:
    and.w   #0x03FF, R12

    cmp.w   #0x03FF, R12
    jne     .Lrf_not_full
    mov.w   #1, R12
    ret
.Lrf_not_full:
    clr.w   R12
    ret

;==============================================================================
; .Lcell_get
; In:  R12=row, R13=col ; Out: R12=0/1 ; Clobbers: R12-R15
;==============================================================================
.Lcell_get:
    mov.w   R12, R14
    mov.w   R12, R15
    rla.w   R14
    rla.w   R15
    rla.w   R15
    rla.w   R15
    add.w   R14, R15                    ; row*10
    add.w   R13, R15                    ; bit_pos

    mov.w   R15, R14
    and.w   #7, R14                     ; bit_within_byte
    rra.w   R15
    rra.w   R15
    rra.w   R15                         ; byte_idx

    mov.w   #RAM_BOARD, R12
    add.w   R15, R12
    mov.b   @R12, R12

    tst.w   R14
    jz      .Lcg_test
.Lcg_shift:
    rra.w   R12
    dec.w   R14
    jnz     .Lcg_shift
.Lcg_test:
    and.w   #1, R12
    ret

;==============================================================================
; .Lcell_set
; In: R12=row, R13=col, R14=val ; Clobbers: R12-R15
;==============================================================================
.Lcell_set:
    push    R14
    mov.w   R12, R15
    rla.w   R15
    mov.w   R12, R14
    rla.w   R14
    rla.w   R14
    rla.w   R14
    add.w   R15, R14                    ; row*10
    add.w   R13, R14                    ; bit_pos

    mov.w   R14, R15
    and.w   #7, R15                     ; bit_within_byte
    rra.w   R14
    rra.w   R14
    rra.w   R14                         ; byte_idx

    mov.w   #RAM_BOARD, R12
    add.w   R14, R12

    mov.w   #1, R13
    tst.w   R15
    jz      .Lcs_have_mask
.Lcs_mkmask:
    rla.w   R13
    dec.w   R15
    jnz     .Lcs_mkmask
.Lcs_have_mask:
    pop     R14
    tst.w   R14
    jz      .Lcs_clear
    bis.b   R13, 0(R12)
    ret
.Lcs_clear:
    bic.b   R13, 0(R12)
    ret

;==============================================================================
; .Lclear_line
; In: R12 = row index of the full row to remove
; Effect: rows above `row` each shift down by one; row 0 becomes empty.
; Clobbers: R12-R15, borrows R8-R10 (saved/restored)
;==============================================================================
.Lclear_line:
    push    R8
    push    R9
    push    R10
    mov.w   R12, R8
    inc.w   R8                          ; shift begins one row past the
    inc.w   R8                          ;   cleared line

.Lcl_row_loop:
    cmp.w   #0, R8
    jz      .Lcl_zero_row
    clr.w   R9
.Lcl_col_loop:
    mov.w   R8, R12
    dec.w   R12
    mov.w   R9, R13
    call    #.Lcell_get
    mov.w   R12, R10
    mov.w   R8, R12
    mov.w   R9, R13
    mov.w   R10, R14
    call    #.Lcell_set
    inc.w   R9
    cmp.w   #BOARD_COLS, R9
    jl      .Lcl_col_loop
    dec.w   R8
    jmp     .Lcl_row_loop

.Lcl_zero_row:
    clr.w   R9
.Lcl_zero_col:
    clr.w   R12
    mov.w   R9, R13
    clr.w   R14
    call    #.Lcell_set
    inc.w   R9
    cmp.w   #BOARD_COLS, R9
    jl      .Lcl_zero_col

    pop     R10
    pop     R9
    pop     R8
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
; .Lboard_template — 25 bytes, 20 rows x 10 packed columns. Row 6 is the
; one full row. Row 5 is a "nearly full" decoy (9 of 10 bits).
;==============================================================================
.Lboard_template:
    .byte   0x00, 0x44, 0x04, 0xCF, 0x71, 0xAA, 0xFA, 0xFF, 0xFF
    .byte   0x3F, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

;==============================================================================
; .Lboard_expected_after — hand-computed result of clearing row 6: rows
; 0-5 shift down into rows 1-6, row 0 becomes empty, rows 7-19 unchanged.
;==============================================================================
.Lboard_expected_after:
    .byte   0x00, 0x00, 0x10, 0x11, 0x3C, 0xC7, 0xA9, 0xEA, 0xFF
    .byte   0x3F, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
