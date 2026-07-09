;******************************************************************************
; timer-blink.s — Lesson 09 example
;
; Blinks LED1 at exactly 1 Hz (on 0.5 s / off 0.5 s) using Timer_A in Up
; mode, polling TAIFG instead of a software-counted delay loop.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants
;==============================================================================
.equ    SMCLK_HZ,           1000000             ; DCO calibrated to 1 MHz
.equ    TA_DIVIDER,         8                   ; ID_3 → Timer_A input /8
.equ    TA_HZ,              (SMCLK_HZ / TA_DIVIDER)      ; = 125,000
.equ    HALF_SEC_TICKS,     (TA_HZ / 2)                  ; = 62,500
.equ    TACCR0_HALF_SEC,    (HALF_SEC_TICKS - 1)         ; = 62,499

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; P1.0 = output
    bic.b   #LED1, &P1OUT               ; start with LED1 off

    mov.w   #TACCR0_HALF_SEC, &TACCR0
    mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL   ; SMCLK/8, Up mode, clear TAR

.Lloop:
    bit.w   #TAIFG, &TACTL              ; has one 0.5 s period elapsed?
    jz      .Lloop
    bic.w   #TAIFG, &TACTL              ; acknowledge the tick
    xor.b   #LED1, &P1OUT               ; toggle LED1
    jmp     .Lloop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
