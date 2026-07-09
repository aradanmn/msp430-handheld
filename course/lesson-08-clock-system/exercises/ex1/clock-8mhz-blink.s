;******************************************************************************
; clock-8mhz-blink.s — Lesson 08 Exercise 1 (Explore)
;
; Target behavior: calibrate the DCO to 8 MHz and blink LED1 at 2 Hz
; (on 250 ms / off 250 ms).
;
; Derive your own delay constants from the 8 MHz frequency using `.equ`
; arithmetic. See Tutorial 08.1 and SLAU144 Ch. 5.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second

    ; --- TODO: calibrate the DCO to 8 MHz here ---
    ; (Which Info Flash constant pair gives you 8 MHz instead of 1 MHz?)


    ; --- TODO: configure P1.0 (LED1) as an output ---


    ; --- TODO: blink LED1 at 2 Hz ---
    ; Define your timing constants with `.equ` arithmetic based on
    ; DCO_HZ = 8000000. Do not reuse the 1 MHz example's numbers.

.Lforever:
    jmp     .Lforever                   ; placeholder — replace with your blink loop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
