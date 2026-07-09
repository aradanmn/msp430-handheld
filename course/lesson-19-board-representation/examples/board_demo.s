#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; board_demo.s
;
; Demonstrates the packed 1-bit-per-cell Tetris board representation from
; this lesson. Implements board_init / board_get / board_set inline, as a
; standalone program -- this file does not #include a shared module. The
; real, reusable version is what you build in exercises/ex3 as the first
; handheld/game/tetris.s milestone.
;
; Bit convention (used identically in Lessons 19 and 20 -- pick ONE and use
; it everywhere):
;   - Row-major layout:        bit_index = row * BOARD_COLS + col
;   - MSB-first within a byte: bit 7 of byte N holds bit_index N*8,
;                               bit 0 of byte N holds bit_index N*8 + 7
;   - byte_offset       = bit_index / 8
;   - bit_within_byte   = 7 - (bit_index mod 8)      (because MSB-first)
;
; There is no hardware multiplier in play here: row*10 is computed as
; row*8 + row*2, both of which are single-bit left shifts (RLA), because a
; 4x4/board-sized multiply-by-a-constant is cheaper done that way than any
; other method available at this point in the course.
;
; Self-test: runs a fixed sequence of board_set/board_get round trips
; against known-correct expected values -- row 0 col 0, row 19 col 9 (the
; last bit of the last byte), and a pair of adjacent cells (row 0, col 7/8)
; that straddle a byte boundary. LED1 lights SOLID if every check passes,
; or BLINKS at a visible rate if any check fails.
;==============================================================================

.equ    BOARD_ROWS,     20
.equ    BOARD_COLS,     10
.equ    BOARD_BITS,     (BOARD_ROWS * BOARD_COLS)          ; 200 cells
.equ    BOARD_BYTES,    ((BOARD_BITS + 7) / 8)             ; 25 bytes

    .bss
board:
    .skip   BOARD_BYTES

    .text

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; LED1 = output
    bic.b   #LED1, &P1OUT               ; start OFF

    call    #board_init

    ; --- test 1: row 0 col 0 reads empty before anything is set ---
    mov.w   #0, R12
    mov.w   #0, R13
    call    #board_get
    cmp.w   #0, R12
    jnz     fail

    ; set row 0 col 0, confirm it now reads filled
    mov.w   #0, R12
    mov.w   #0, R13
    mov.w   #1, R14
    call    #board_set
    mov.w   #0, R12
    mov.w   #0, R13
    call    #board_get
    cmp.w   #1, R12
    jnz     fail

    ; --- test 2: row 19 col 9 -- last cell, last byte, bit 0 ---
    mov.w   #19, R12
    mov.w   #9, R13
    mov.w   #1, R14
    call    #board_set
    mov.w   #19, R12
    mov.w   #9, R13
    call    #board_get
    cmp.w   #1, R12
    jnz     fail
    ; its neighbor must not have been disturbed
    mov.w   #19, R12
    mov.w   #8, R13
    call    #board_get
    cmp.w   #0, R12
    jnz     fail

    ; --- test 3: byte-boundary straddle -- row 0 col 7 (bit_index 7, last
    ;     bit of byte 0) and row 0 col 8 (bit_index 8, first bit of byte 1) ---
    mov.w   #0, R12
    mov.w   #7, R13
    mov.w   #1, R14
    call    #board_set
    mov.w   #0, R12
    mov.w   #8, R13
    call    #board_get                  ; col 8 must still read empty
    cmp.w   #0, R12
    jnz     fail

    mov.w   #0, R12
    mov.w   #8, R13
    mov.w   #1, R14
    call    #board_set
    mov.w   #0, R12
    mov.w   #7, R13
    call    #board_get                  ; col 7 must still read filled
    cmp.w   #1, R12
    jnz     fail
    mov.w   #0, R12
    mov.w   #8, R13
    call    #board_get                  ; col 8 now filled too
    cmp.w   #1, R12
    jnz     fail

    ; --- test 4: board_init clears everything, including bits set above ---
    call    #board_init
    mov.w   #19, R12
    mov.w   #9, R13
    call    #board_get
    cmp.w   #0, R12
    jnz     fail
    mov.w   #0, R12
    mov.w   #7, R13
    call    #board_get
    cmp.w   #0, R12
    jnz     fail

pass:
    bis.b   #LED1, &P1OUT               ; every check passed: LED1 solid ON
.Lpass_hold:
    jmp     .Lpass_hold

fail:
.Lfail_loop:
    xor.b   #LED1, &P1OUT               ; something failed: LED1 blinks
    mov.w   #20000, R12
    call    #delay_loop
    jmp     .Lfail_loop

;==============================================================================
; delay_loop — busy-waits ~R12 iterations (3 cycles each). Only used by the
; failure blink above; not part of the board API.
;==============================================================================
delay_loop:
.Ldelay:
    dec.w   R12
    jnz     .Ldelay
    ret

;==============================================================================
; board_init — clears every byte of the board to 0 (all cells empty).
; No arguments. RAM is not guaranteed to power up zeroed, so this must run
; before any board_get/board_set call.
;==============================================================================
board_init:
    mov.w   #0, R15                     ; R15 = byte index
.Linit_loop:
    clr.b   board(R15)
    inc.w   R15
    cmp.w   #BOARD_BYTES, R15
    jnz     .Linit_loop
    ret

;==============================================================================
; board_get(row, col) -> filled
;   R12 = row (0-19), R13 = col (0-9)  (in)
;   R12 = 1 if the cell is filled, 0 if empty                       (out)
;==============================================================================
board_get:
    mov.w   R12, R14                    ; R14 = row (copy for the *8 chain)
    rla.w   R12                         ; R12 = row*2
    rla.w   R14                         ; R14 = row*2
    rla.w   R14                         ; R14 = row*4
    rla.w   R14                         ; R14 = row*8
    add.w   R14, R12                    ; R12 = row*2 + row*8 = row*10
    add.w   R13, R12                    ; R12 = bit_index = row*10 + col

    mov.w   R12, R13                    ; R13 = bit_index copy
    and.w   #0x0007, R13                ; R13 = bit_index mod 8
    mov.w   #7, R14
    sub.w   R13, R14                    ; R14 = bit_pos, MSB-first, 0-7
    rra.w   R12
    rra.w   R12
    rra.w   R12                         ; R12 = byte_offset = bit_index / 8

    mov.w   R14, R13                    ; R13 = shift count = bit_pos
    mov.b   #0x01, R14                  ; R14 = mask, starts at bit 0
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
; board_set(row, col, val)
;   R12 = row (0-19), R13 = col (0-9), R14 = val (0 = clear, nonzero = fill)
;==============================================================================
board_set:
    mov.w   R12, R15                    ; R15 = row (copy for the *8 chain)
    rla.w   R12                         ; R12 = row*2
    rla.w   R15                         ; R15 = row*2
    rla.w   R15                         ; R15 = row*4
    rla.w   R15                         ; R15 = row*8
    add.w   R15, R12                    ; R12 = row*10
    add.w   R13, R12                    ; R12 = bit_index

    mov.w   R12, R13                    ; R13 = bit_index copy
    and.w   #0x0007, R13                ; R13 = bit_index mod 8
    mov.w   #7, R15
    sub.w   R13, R15                    ; R15 = bit_pos, MSB-first, 0-7
    rra.w   R12
    rra.w   R12
    rra.w   R12                         ; R12 = byte_offset

    mov.w   R15, R13                    ; R13 = shift count = bit_pos
    mov.b   #0x01, R15                  ; R15 = mask, starts at bit 0
.Lset_shift:
    tst.w   R13
    jz      .Lset_shift_done
    rla.b   R15
    dec.w   R13
    jmp     .Lset_shift
.Lset_shift_done:

    tst.w   R14                         ; val == 0 ?
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
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
