;******************************************************************************
; timer-blink-4hz.s — Lesson 09 Exercise 1 (Explore)
;
; Target behavior: blink LED2 (P1.6) at 4 Hz (on 125 ms / off 125 ms) using
; Timer_A Up mode + TAIFG polling. SMCLK is calibrated to 1 MHz.
;
; Choose your own input divider and derive TACCR0 with `.equ` arithmetic.
; See Tutorial 09.1. No software delay loop.
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


    ; --- TODO: configure TACCR0 and TACTL for a 4 Hz toggle rate ---
    ; Derive TACCR0 from SMCLK_HZ = 1,000,000 and whatever divider you pick.


.Lloop:
    ; --- TODO: poll TAIFG, clear it, toggle LED2 ---
    jmp     .Lloop                      ; placeholder — replace with your poll loop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
