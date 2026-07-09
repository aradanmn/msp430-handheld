#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; board_ops.s — Lesson 19 Exercise 1 (Explore)
;
; Build board_get(row, col) and board_set(row, col, val) from scratch, plus
; a self-test that proves they round-trip correctly. See exercises/README.md
; for the full spec and success criteria.
;
; The board dimensions and the RAM reservation for it are set up below --
; that part is fixed. Everything else (the bit convention, the addressing
; math, the subroutines, the self-test, and the LED1 pass/fail reporting)
; is yours to design and write.
;==============================================================================

.equ    BOARD_ROWS,     20
.equ    BOARD_COLS,     10
.equ    BOARD_BITS,     (BOARD_ROWS * BOARD_COLS)
.equ    BOARD_BYTES,    ((BOARD_BITS + 7) / 8)

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

    ; Your code goes here: call board_init (you write it too), then run a
    ; self-test of board_get/board_set round trips against cells you choose
    ; -- including at least one edge case. Light LED1 solid if everything
    ; you check comes back correct, or blink it if anything doesn't. See
    ; exercises/README.md for the exact requirements.

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
