;******************************************************************************
; lineclear_demo.s — Lesson 22 example
;
; Self-contained demo of full-row detection and line clearing over a
; tightly-packed board: 20 rows x 10 columns, 1 bit per cell, NO padding
; between rows (200 bits = 25 bytes total). Row r's bits occupy global bit
; range [r*10, r*10+9] — see tutorial-01 for why that always straddles a
; byte boundary and why two bytes are always (and exactly) enough to read
; one row.
;
; This file does not call into handheld/game/tetris.s — the real board's
; internal layout is hidden behind board_get/board_set. This demo builds
; its own small RAM-resident board so the packing mechanics are visible.
;
; Test plan: copy a hardcoded 25-byte board (one full row among several
; partial rows) into RAM, scan all 20 rows for exactly one full row at the
; expected index, clear it, and compare the resulting 25 bytes against a
; hand-computed expected result. LED1 lands solid if everything matches;
; otherwise it blinks forever.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; Constants
;==============================================================================
.equ    BOARD_ROWS,          20
.equ    BOARD_COLS,          10
.equ    BOARD_BYTES,         25
.equ    RAM_BOARD,           0x0200      ; scratch board buffer in RAM
.equ    EXPECTED_FULL_ROW,   5
.equ    EXPECTED_FULL_COUNT, 1

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; LED1 as output
    bic.b   #LED1, &P1OUT               ; start off

;==============================================================================
; main_loop
; 1. copy .Lboard_template (Flash) into RAM_BOARD
; 2. scan all 20 rows; expect exactly one full row, at EXPECTED_FULL_ROW
; 3. clear that row
; 4. compare the resulting RAM board, byte for byte, against
;    .Lboard_expected_after
; No ISR runs in this file, so R5-R7 are ordinary top-level scratch here.
;==============================================================================
main_loop:
    mov.w   #.Lboard_template, R14
    mov.w   #RAM_BOARD, R15
    mov.w   #BOARD_BYTES, R13
.Lcopy_loop:
    mov.b   @R14+, 0(R15)
    inc.w   R15
    dec.w   R13
    jnz     .Lcopy_loop

    clr.w   R6                          ; R6 = count of full rows found
    mov.w   #-1, R5                     ; R5 = index of (the) full row found
    clr.w   R12                         ; R12 = row = 0
.Lscan_loop:
    push    R12
    call    #.Lrow_full                 ; R12 = 1 if this row is full
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
    mov.w   R12, R14                    ; R14 = row (copy -> becomes row*2)
    mov.w   R12, R13                    ; R13 = row (copy -> becomes row*8)
    rla.w   R14                         ; R14 = row*2
    rla.w   R13                         ; R13 = row*2
    rla.w   R13                         ; R13 = row*4
    rla.w   R13                         ; R13 = row*8
    add.w   R14, R13                    ; R13 = row*8 + row*2 = row*10 = base_bit

    mov.w   R13, R14                    ; R14 = base_bit (copy for bit_off)
    and.w   #7, R14                     ; R14 = bit_off (0, 2, 4, or 6)
    rra.w   R13
    rra.w   R13
    rra.w   R13                         ; R13 = base_bit >> 3 = byte_idx

    mov.w   #RAM_BOARD, R15
    add.w   R13, R15                    ; R15 = &board[byte_idx]
    mov.b   @R15, R12                   ; R12 = board[byte_idx]      (low byte)
    mov.b   1(R15), R13                 ; R13 = board[byte_idx + 1]
    swpb    R13                         ; R13 = board[byte_idx+1] << 8
    bis.w   R13, R12                    ; R12 = word16

    tst.w   R14
    jz      .Lrf_shifted
.Lrf_shift_loop:
    rra.w   R12
    dec.w   R14
    jnz     .Lrf_shift_loop
.Lrf_shifted:
    and.w   #0x03FF, R12                ; R12 = this row's 10 columns

    cmp.w   #0x03FF, R12
    jne     .Lrf_not_full
    mov.w   #1, R12
    ret
.Lrf_not_full:
    clr.w   R12
    ret

;==============================================================================
; .Lcell_get
; In:  R12=row (0-19), R13=col (0-9)
; Out: R12 = 0/1
; Clobbers: R12-R15
;==============================================================================
.Lcell_get:
    mov.w   R12, R14
    mov.w   R12, R15
    rla.w   R14                         ; row*2
    rla.w   R15
    rla.w   R15
    rla.w   R15                         ; row*8
    add.w   R14, R15                    ; row*10
    add.w   R13, R15                    ; R15 = bit_pos = row*10+col

    mov.w   R15, R14
    and.w   #7, R14                     ; R14 = bit_within_byte
    rra.w   R15
    rra.w   R15
    rra.w   R15                         ; R15 = byte_idx

    mov.w   #RAM_BOARD, R12
    add.w   R15, R12
    mov.b   @R12, R12                   ; R12 = board[byte_idx]

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
; In:  R12=row (0-19), R13=col (0-9), R14=val (0/1)
; Clobbers: R12-R15
;==============================================================================
.Lcell_set:
    push    R14                         ; preserve val across our own math
    mov.w   R12, R15
    rla.w   R15                         ; row*2
    mov.w   R12, R14
    rla.w   R14
    rla.w   R14
    rla.w   R14                         ; row*8
    add.w   R15, R14                    ; row*10
    add.w   R13, R14                    ; R14 = bit_pos = row*10+col

    mov.w   R14, R15
    and.w   #7, R15                     ; R15 = bit_within_byte
    rra.w   R14
    rra.w   R14
    rra.w   R14                         ; R14 = byte_idx

    mov.w   #RAM_BOARD, R12
    add.w   R14, R12                    ; R12 = &board[byte_idx]

    mov.w   #1, R13                     ; build the bit mask
    tst.w   R15
    jz      .Lcs_have_mask
.Lcs_mkmask:
    rla.w   R13
    dec.w   R15
    jnz     .Lcs_mkmask
.Lcs_have_mask:
    pop     R14                         ; restore val
    tst.w   R14
    jz      .Lcs_clear
    bis.b   R13, 0(R12)
    ret
.Lcs_clear:
    bic.b   R13, 0(R12)
    ret

;==============================================================================
; .Lclear_line
; In: R12 = row index of the full row to remove (0-19)
; Effect: rows above `row` each shift down by one; row 0 becomes empty.
;         Rows below `row` are left untouched.
; Clobbers: R12-R15, borrows R8-R10 (saved/restored)
;==============================================================================
.Lclear_line:
    push    R8
    push    R9
    push    R10
    mov.w   R12, R8                     ; R8 = dest_row, counts down to 1

.Lcl_row_loop:
    cmp.w   #0, R8
    jz      .Lcl_zero_row
    clr.w   R9                          ; R9 = col
.Lcl_col_loop:
    mov.w   R8, R12
    dec.w   R12                         ; R12 = source row = dest_row - 1
    mov.w   R9, R13                     ; R13 = col
    call    #.Lcell_get                 ; R12 = source cell value
    mov.w   R12, R10                    ; R10 = value to write
    mov.w   R8, R12                     ; R12 = dest row
    mov.w   R9, R13                     ; R13 = col
    mov.w   R10, R14                    ; R14 = val
    call    #.Lcell_set
    inc.w   R9
    cmp.w   #BOARD_COLS, R9
    jl      .Lcl_col_loop
    dec.w   R8
    jmp     .Lcl_row_loop

.Lcl_zero_row:
    clr.w   R9
.Lcl_zero_col:
    clr.w   R12                         ; row 0
    mov.w   R9, R13
    clr.w   R14                         ; val = 0
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
; .Lboard_template — 25 bytes, 20 rows x 10 packed columns, row-major, no
; padding. Row 5 is the one deliberately full row (all 10 bits set); rows
; 4 and 6 are "nearly full" decoys (9 of 10 bits set) that must NOT be
; flagged full. Row 5's bits straddle byte 6 / byte 7 — see tutorial-01.
;==============================================================================
.Lboard_template:
    .byte   0x00, 0x00, 0x50, 0x95, 0x2A, 0xFE, 0xFF, 0xDF, 0x7F
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x03

;==============================================================================
; .Lboard_expected_after — hand-computed result of clearing row 5 from the
; template above: rows 0-4 shift down into rows 1-5, row 0 becomes empty,
; rows 6-19 are unchanged.
;==============================================================================
.Lboard_expected_after:
    .byte   0x00, 0x00, 0x00, 0x40, 0x55, 0xAA, 0xF8, 0xDF, 0x7F
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x03

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
