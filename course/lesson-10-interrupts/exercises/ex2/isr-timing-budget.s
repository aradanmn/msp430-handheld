;******************************************************************************
; isr-timing-budget.s — Lesson 10 Exercise 2 (Challenge)
;
; Intended behavior: LED1 blinks at a clean, steady 1 Hz (on 0.5 s / off
; 0.5 s), driven entirely by a Timer_A CC0 interrupt.
;
; Build it, flash it, and watch LED1 for at least 15-20 seconds. See
; exercises/README.md for what you should be checking against.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants
;==============================================================================
.equ    SMCLK_HZ,           1000000
.equ    TA_DIVIDER,         8
.equ    TA_HZ,              (SMCLK_HZ / TA_DIVIDER)
.equ    HALF_SEC_TICKS,     (TA_HZ / 2)
.equ    TACCR0_HALF_SEC,    (HALF_SEC_TICKS - 1)

.equ    OVERRUN_CYCLES,     600000
.equ    OVERRUN_INNER,      1000
.equ    CYCLES_PER_ITER,    3
.equ    OVERRUN_INNER_CYCLES, (OVERRUN_INNER * CYCLES_PER_ITER)
.equ    OVERRUN_OUTER,      (OVERRUN_CYCLES / OVERRUN_INNER_CYCLES)
.equ    OVERRUN_PERIOD_TICKS, 4

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
    clr.w   R4                          ; tick counter

    mov.w   #TACCR0_HALF_SEC, &TACCR0
    mov.w   #(TASSEL_2|ID_3|MC_1|TACLR), &TACTL
    mov.w   #CCIE, &TACCTL0

    bis.w   #GIE, SR

.Lspin:
    jmp     .Lspin

;==============================================================================
; cc0_isr — fires every 0.5 s on Timer_A CC0 compare match
;==============================================================================
cc0_isr:
    xor.b   #LED1, &P1OUT
    inc.w   R4
    cmp.w   #OVERRUN_PERIOD_TICKS, R4
    jne     .Lno_extra_work
    clr.w   R4
    mov.w   #OVERRUN_OUTER, R14
.Lextra_outer:
    mov.w   #OVERRUN_INNER, R15
.Lextra_inner:
    dec.w   R15
    jnz     .Lextra_inner
    dec.w   R14
    jnz     .Lextra_outer
.Lno_extra_work:
    reti

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   0           ; 0xFFE4  Port 1
    .word   0           ; 0xFFE6  Port 2
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI_A0/B0 TX
    .word   0           ; 0xFFEE  USCI_A0/B0 RX
    .word   0           ; 0xFFF0  Timer_A overflow (TAIV)
    .word   cc0_isr     ; 0xFFF2  Timer_A CC0
    .word   0           ; 0xFFF4  WDT
    .word   0           ; 0xFFF6  Comparator_A+
    .word   0           ; 0xFFF8  Timer1_A1
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
    .end
