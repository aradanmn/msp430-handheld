;******************************************************************************
; timer-timing-bug.s — Lesson 09 Exercise 2 (Challenge)
;
; Intended behavior: LED1 blinks at 1 Hz (on 0.5 s / off 0.5 s), timed by
; Timer_A in Up mode.
;
; Build it, flash it, and observe LED1. See exercises/README.md for what
; you should be checking against.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants
;==============================================================================
.equ    SMCLK_HZ,           1000000
.equ    TA_DIVIDER,         8                   ; assumed Timer_A input /8
.equ    TA_HZ,              (SMCLK_HZ / TA_DIVIDER)      ; = 125,000
.equ    HALF_SEC_TICKS,     (TA_HZ / 2)                  ; = 62,500
.equ    TACCR0_HALF_SEC,    (HALF_SEC_TICKS - 1)         ; = 62,499

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

    mov.w   #TACCR0_HALF_SEC, &TACCR0
    mov.w   #(TASSEL_2|ID_1|MC_1|TACLR), &TACTL

.Lloop:
    bit.w   #TAIFG, &TACTL
    jz      .Lloop
    bic.w   #TAIFG, &TACTL
    xor.b   #LED1, &P1OUT
    jmp     .Lloop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
