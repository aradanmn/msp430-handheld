#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; LED1 (P1.0): output, start OFF
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; S2 / BTN (P1.3): input, internal pull-up (reads 1 released, 0 pressed)
    bic.b   #BTN, &P1DIR    ; input (this is the reset default; be explicit)
    bis.b   #BTN, &P1REN    ; enable the pull resistor on P1.3
    bis.b   #BTN, &P1OUT    ; ...and pull it UP (not down)

    ; TODO: using only what you know so far (polling + delay loops — no
    ; timer peripheral, no interrupts yet), make a single physical press
    ; of S2 toggle LED1 exactly once, and a single physical release
    ; produce no extra toggle, even with the bounce behavior you observed
    ; in ex1. You may block (tie up the CPU) while you do this — that
    ; tradeoff is intentional and will be revisited in Lesson 07.
    ; See exercises/README.md for full success criteria.

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
