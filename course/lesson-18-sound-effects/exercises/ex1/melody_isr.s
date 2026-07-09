;******************************************************************************
; melody_isr.s — Lesson 18, Exercise 1 (Explore)
;
; See exercises/README.md for the task. Only the standard boilerplate is
; provided below — the rest is yours.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL   ; disable watchdog
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1      ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; --- your code here ---

halt:
    jmp     halt

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
