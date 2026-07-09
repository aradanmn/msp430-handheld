;******************************************************************************
; isr-convert.s — Lesson 10 Exercise 1 (Explore) — starting point
;
; This program works as-is: LED2 blinks at 2 Hz using Timer_A Up mode and
; TAIFG polling (Lesson 09's style).
;
; Your task: rewrite it so the same 2 Hz blink is driven entirely by a
; Timer_A CC0 interrupt, with no polling loop in main. See exercises/README.md.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants
;==============================================================================
.equ    SMCLK_HZ,           1000000
.equ    TA_DIVIDER,         8                   ; ID_3 → Timer_A input /8
.equ    TA_HZ,              (SMCLK_HZ / TA_DIVIDER)      ; = 125,000
.equ    QUARTER_SEC_TICKS,  (TA_HZ / 4)                  ; = 31,250
.equ    TACCR0_QUARTER_SEC, (QUARTER_SEC_TICKS - 1)      ; = 31,249

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED2, &P1DIR
    bic.b   #LED2, &P1OUT

    mov.w   #TACCR0_QUARTER_SEC, &TACCR0
    mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL

.Lloop:
    bit.w   #TAIFG, &TACTL
    jz      .Lloop
    bic.w   #TAIFG, &TACTL
    xor.b   #LED2, &P1OUT
    jmp     .Lloop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
