;******************************************************************************
; timer-cc0-isr.s — Lesson 10 example
;
; Blinks LED1 at 1 Hz (on 0.5 s / off 0.5 s) using Timer_A's CC0 interrupt
; instead of polling TAIFG (Lesson 09's approach). The main loop does
; nothing but spin — Lesson 11 replaces that spin with true sleep (LPM0).
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants
;==============================================================================
.equ    SMCLK_HZ,           1000000
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
    mov.w   #CCIE, &TACCTL0             ; enable the CC0 compare interrupt

    bis.w   #GIE, SR                    ; global interrupt enable — no LPM yet

.Lspin:
    jmp     .Lspin                       ; nothing to do; the ISR does the work

;==============================================================================
; cc0_isr — fires every 0.5 s on Timer_A CC0 compare match
;==============================================================================
cc0_isr:
    xor.b   #LED1, &P1OUT               ; toggle LED1
    reti                                 ; CCIFG is cleared automatically —
                                         ; restores SR and PC

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
