;******************************************************************************
; row_full_check.s — Lesson 22 Exercise 1 (Explore)
;
; Task: implement an "is this row full" check against the packed board
; below (already copied into RAM for you), and a runner that walks
; .Ltest_vectors, compares your check's result against each expected
; value, and drives LED1: solid if every case matches, blinking if any
; doesn't.
;
; See exercises/README.md for what to look up and the full success criteria.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Constants
;==============================================================================
.equ    BOARD_ROWS,   20
.equ    BOARD_BYTES,  25
.equ    RAM_BOARD,    0x0200      ; board buffer in RAM
.equ    TEST_COUNT,   5

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

    ; Board copy — already done for you: .Lex1_board_template (Flash) into
    ; RAM_BOARD, byte for byte.
    mov.w   #.Lex1_board_template, R14
    mov.w   #RAM_BOARD, R15
    mov.w   #BOARD_BYTES, R13
.Lcopy_loop:
    mov.b   @R14+, 0(R15)
    inc.w   R15
    dec.w   R13
    jnz     .Lcopy_loop

    ; TODO: implement your row-full check and a test runner here. Walk
    ; .Ltest_vectors (row, expected — two words per entry, TEST_COUNT
    ; entries), and for each one:
    ;   1. compute that row's base bit index (row * 10), then split it into
    ;      a byte index and a bit-within-byte offset
    ;   2. read the two relevant bytes from RAM_BOARD, combine them, shift,
    ;      and mask to get that row's 10 columns right-aligned
    ;   3. compare against an all-ones (10-bit) mask to decide full/not full
    ;   4. compare your result against the entry's expected value
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
; .Lex1_board_template — 25 bytes, 20 rows x 10 packed columns, row-major,
; no padding. Row 8 is the one deliberately full row. Rows 2 and 7 are
; "nearly full" decoys (9 of 10 bits set) that must NOT be flagged full.
;==============================================================================
.Lex1_board_template:
    .byte   0x00, 0xA8, 0xFA, 0x1F, 0x00, 0x00, 0x00, 0x00, 0x80
    .byte   0xFF, 0xFF, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

;==============================================================================
; .Ltest_vectors — (row, expected)
;==============================================================================
.Ltest_vectors:
    .word    8,  1     ; the deliberately full row       -> full
    .word    2,  0     ; 9 of 10 columns — a decoy        -> not full
    .word    7,  0     ; 9 of 10 columns — a decoy        -> not full
    .word    1,  0     ; partial row                      -> not full
    .word    0,  0     ; empty row                        -> not full

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
