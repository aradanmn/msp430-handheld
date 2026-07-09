;******************************************************************************
; clock-mixup.s — Lesson 08 Exercise 2 (Challenge)
;
; Intended behavior: LED1 blinks at 1 Hz (on 0.5 s / off 0.5 s).
;
; Build it, flash it, and observe LED1. See exercises/README.md for what
; you should be checking against.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants
;==============================================================================
.equ    DCO_HZ,             1000000
.equ    HALF_SEC_CYCLES,    (DCO_HZ / 2)

.equ    CYCLES_PER_ITER,    3
.equ    INNER_COUNT,        500
.equ    INNER_CYCLES,       (INNER_COUNT * CYCLES_PER_ITER)
.equ    OUTER_COUNT,        (HALF_SEC_CYCLES / INNER_CYCLES)

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_8MHZ, &BCSCTL1
    mov.b   &CALDCO_8MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

.Lblink:
    xor.b   #LED1, &P1OUT
    call    #delay_half_sec
    jmp     .Lblink

;==============================================================================
; delay_half_sec — busy-waits for approximately HALF_SEC_CYCLES cycles
;==============================================================================
delay_half_sec:
    mov.w   #OUTER_COUNT, R14
.Louter:
    mov.w   #INNER_COUNT, R15
.Linner:
    dec.w   R15
    jnz     .Linner
    dec.w   R14
    jnz     .Louter
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
