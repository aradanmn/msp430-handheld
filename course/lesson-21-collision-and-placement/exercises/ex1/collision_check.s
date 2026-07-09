;******************************************************************************
; collision_check.s — Lesson 21 Exercise 1 (Explore)
;
; Task: implement a piece_can_move-style legality check — bounds AND board
; occupancy, for every occupied cell of the 4x4 piece mask — against the
; hardcoded board and piece below. Then write a runner that walks
; .Ltest_vectors, compares your check's result against each expected value,
; and drives LED1: solid if every case matches, blinking if any doesn't.
;
; See exercises/README.md for what to look up and the full success criteria.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Constants
;==============================================================================
.equ    BOARD_ROWS,         20
.equ    BOARD_COLS,         10
.equ    TEST_PIECE_MASK,    0x0063      ; relative cells (0,0) (0,1) (1,1) (1,2)
.equ    TEST_COUNT,         7

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

    ; TODO: implement your legality check and a test runner here. Walk
    ; .Ltest_vectors (row, col, dx, dy, expected — five words per entry,
    ; TEST_COUNT entries), and for each one:
    ;   1. compute where each occupied cell of TEST_PIECE_MASK would land
    ;      given (dx, dy)
    ;   2. reject if any landing cell is outside BOARD_ROWS x BOARD_COLS
    ;   3. reject if any landing cell is already occupied in .Lex1_board
    ;   4. compare your yes/no result against the entry's expected value
    ; Drive LED1 solid if every case matches; blink it (see .Ldelay_ms
    ; below, already provided) forever if any case doesn't.

.Lhalt:
    jmp     .Lhalt                      ; placeholder — replace with your runner

;==============================================================================
; .Ldelay_ms — busy-wait ~R12 milliseconds at 1 MHz. Arg: R12. Clobbers R13.
; Provided as-is; not the subject of this exercise.
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
; .Lex1_board — 20 rows, one word each, bit c = column c. Empty except a
; small stack in the bottom-right corner: row 18 has column 9 filled, and
; row 19 has columns 6-9 filled.
;==============================================================================
.Lex1_board:
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0        ; rows 0-9
    .word   0, 0, 0, 0, 0, 0, 0, 0               ; rows 10-17
    .word   0x0200                                ; row 18 — col 9 filled
    .word   0x03C0                                ; row 19 — cols 6-9 filled

;==============================================================================
; .Ltest_vectors — (row, col, dx, dy, expected)
;==============================================================================
.Ltest_vectors:
    .word   10,  6,  0,  0,  1     ; baseline, open area          -> legal
    .word   10,  6,  2,  0,  0     ; nudge right into the wall    -> illegal
    .word   10,  6, -6,  0,  1     ; nudge left, still in bounds  -> legal
    .word   10,  6,  0,  8,  0     ; drop onto the corner stack   -> illegal
    .word   10,  6,  0,  9,  0     ; drop off the bottom          -> illegal
    .word   17,  7,  0,  0,  0     ; baseline overlaps the stack  -> illegal
    .word   16,  7,  0,  0,  1     ; one row higher, clear        -> legal

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
