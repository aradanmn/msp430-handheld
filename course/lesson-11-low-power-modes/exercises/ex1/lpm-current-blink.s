;******************************************************************************
; lpm-current-blink.s — Lesson 11 Exercise 1 (Explore)
;
; Target behavior: blink LED2 (P1.6) at 2 Hz (on 250 ms / off 250 ms), using
; a Timer_A CC0 ISR + LPM0, following the pattern from Tutorial 11.1/11.2.
;
; No polling loop. The main loop must not do real work between ticks — the
; CPU should be asleep in LPM0 the entire time except while the ISR runs.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; --- TODO: configure P1.6 (LED2) as an output ---


    ; --- TODO: configure Timer_A for a tick fast enough to divide evenly
    ;     into a 2 Hz (250 ms) toggle period, enable CCIE ---


    ; --- TODO: enter LPM0 (GIE + CPUOFF, one instruction) ---


.Lunreachable:
    jmp     .Lunreachable               ; should never be reached

;==============================================================================
; TODO: write your CC0 ISR here (toggle LED2 on the appropriate tick,
;       exit via plain reti)
;==============================================================================

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
    .word   0           ; 0xFFF2  Timer_A CC0   ← put your ISR's address here
    .word   0           ; 0xFFF4  WDT
    .word   0           ; 0xFFF6  Comparator_A+
    .word   0           ; 0xFFF8  Timer1_A1
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
    .end
