;******************************************************************************
; tempo_drift.s — Lesson 18, Exercise 2 (Challenge)
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

.equ    PWM_PIN,   BIT4

.equ    SMCLK_HZ,   1000000
.equ    NOTE_C4_HZ, 262
.equ    NOTE_E4_HZ, 330
.equ    NOTE_G4_HZ, 392
.equ    NOTE_C5_HZ, 523
.equ    NOTE_C4,    (SMCLK_HZ/NOTE_C4_HZ)-1
.equ    NOTE_E4,    (SMCLK_HZ/NOTE_E4_HZ)-1
.equ    NOTE_G4,    (SMCLK_HZ/NOTE_G4_HZ)-1
.equ    NOTE_C5,    (SMCLK_HZ/NOTE_C5_HZ)-1

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #tone_init

main_loop:
    mov.w   #melody, R14
.Lnote_loop:
    mov.w   @R14+, R12          ; period (0 = end of table)
    tst.w   R12
    jz      .Lsequence_done
    mov.w   @R14+, R13          ; duration in ticks (1 tick = 1 ms)
    call    #play_note_ticks
    jmp     .Lnote_loop
.Lsequence_done:
    jmp     main_loop            ; repeats back-to-back, no gap

;==============================================================================
tone_init:
    bic.b   #PWM_PIN, &P2SEL
    bis.b   #PWM_PIN, &P2DIR
    bic.b   #PWM_PIN, &P2OUT
    ret

;==============================================================================
; play_note_ticks — R12 = period, R13 = duration in ticks
;==============================================================================
play_note_ticks:
    mov.w   R12, &TA1CCR0
    rra.w   R12
    mov.w   R12, &TA1CCR2
    mov.w   #OUTMOD_7, &TA1CCTL2
    mov.w   #(TASSEL_2|MC_1|TACLR), &TA1CTL
    bis.b   #PWM_PIN, &P2SEL
.Ltick_loop:
    mov.w   #1, R14
    call    #delay_ms
    dec.w   R13
    jnz     .Ltick_loop
    bic.b   #PWM_PIN, &P2SEL
    ret

;==============================================================================
; delay_ms — R14 = milliseconds
;==============================================================================
delay_ms:
.Lms_outer:
    mov.w   #300, R15
.Lms_inner:
    dec.w   R15
    jnz     .Lms_inner
    dec.w   R14
    jnz     .Lms_outer
    ret

;==============================================================================
; melody table — (period, duration_ticks) pairs, 0 period = end of sequence
;==============================================================================
melody:
    .word   NOTE_C4, 200
    .word   NOTE_E4, 200
    .word   NOTE_G4, 200
    .word   NOTE_C5, 200
    .word   NOTE_G4, 200
    .word   NOTE_E4, 200
    .word   NOTE_C4, 200
    .word   NOTE_G4, 200
    .word   0

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
