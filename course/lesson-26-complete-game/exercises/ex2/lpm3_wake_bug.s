;******************************************************************************
; lpm3_wake_bug.s — Lesson 26 Exercise 2 (Challenge)
;
; Intended behavior: ACLK sourced from the internal VLO, CPU asleep in LPM3
; between button presses, LED1 toggling exactly once per press of the
; onboard S2 button (P1.3), indefinitely.
;
; Build it, flash it, and try several button presses in a row. See
; exercises/README.md for what you should be checking against.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

.equ    LFXT1S_3,   0x30      ; BCSCTL3 bits 5-4 = 11 -> ACLK from VLOCLK

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

    bic.b   #BTN, &P1DIR
    bis.b   #BTN, &P1REN
    bis.b   #BTN, &P1OUT
    bis.b   #BTN, &P1IES
    bic.b   #BTN, &P1IFG
    bis.b   #BTN, &P1IE

    bis.b   #LFXT1S_3, &BCSCTL3

.Lsleep:
    bis.w   #(LPM3_bits|GIE), SR
    jmp     .Lsleep

;==============================================================================
; port1_isr
;==============================================================================
port1_isr:
    xor.b   #LED1, &P1OUT
    bic.w   #CPUOFF, 0(SP)
    reti

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   port1_isr   ; 0xFFE4  Port 1
    .word   0           ; 0xFFE6  Port 2
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI_A0/B0 TX
    .word   0           ; 0xFFEE  USCI_A0/B0 RX
    .word   0           ; 0xFFF0  Timer_A overflow (TAIV)
    .word   0           ; 0xFFF2  Timer_A CC0
    .word   0           ; 0xFFF4  WDT
    .word   0           ; 0xFFF6  Comparator_A+
    .word   0           ; 0xFFF8  Timer1_A1
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
    .end
