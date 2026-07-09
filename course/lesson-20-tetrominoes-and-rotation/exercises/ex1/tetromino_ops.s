#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; tetromino_ops.s — Lesson 20 Exercise 1 (Explore)
;
; Encode all 7 tetrominoes' spawn orientation as a Flash table, and build a
; rotation function for ONE piece of your choosing that derives (or looks
; up) its next rotation state. Self-test via LED1. See exercises/README.md
; for the full spec and success criteria.
;
; Boilerplate and LED1 setup only below -- the table, the encoding, the
; rotation function, the self-test, and the LED1 pass/fail reporting are
; all yours to design and write.
;==============================================================================

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; LED1 = output
    bic.b   #LED1, &P1OUT               ; start OFF

    ; Your code goes here.

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
