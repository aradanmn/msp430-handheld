;******************************************************************************
; duty_puzzle.s — Lesson 17, Exercise 2 (Challenge)
;
; Wire up the LM386/speaker exactly as in the lesson example and flash
; this program. See exercises/README.md for what you should observe and
; what you need to fix.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    TA1CTL,    0x0180
.equ    TA1CCTL2,  0x0186
.equ    TA1CCR0,   0x0192
.equ    TA1CCR2,   0x0196

.equ    PWM_PIN,        BIT4

.equ    SMCLK_HZ,       1000000
.equ    TONE_A4_HZ,     440
.equ    TONE_A4_PERIOD, (SMCLK_HZ/TONE_A4_HZ)-1

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #leds_init
    call    #tone_init

main_loop:
    bis.b   #PWM_PIN, &P2SEL
    bis.b   #LED1, &P1OUT
    mov.w   #20000, R13
    call    #delay_loop

    bic.b   #PWM_PIN, &P2SEL
    bic.b   #LED1, &P1OUT
    mov.w   #20000, R13
    call    #delay_loop
    jmp     main_loop

;==============================================================================
leds_init:
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT
    ret

;==============================================================================
tone_init:
    bic.b   #PWM_PIN, &P2SEL
    bis.b   #PWM_PIN, &P2DIR
    bic.b   #PWM_PIN, &P2OUT

    mov.w   #TONE_A4_PERIOD, &TA1CCR0
    mov.w   #TONE_A4_PERIOD, &TA1CCR2       ; duty register
    mov.w   #OUTMOD_7, &TA1CCTL2
    mov.w   #(TASSEL_2|MC_1|TACLR), &TA1CTL
    ret

;==============================================================================
delay_loop:
    dec.w   R13
    jnz     delay_loop
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
