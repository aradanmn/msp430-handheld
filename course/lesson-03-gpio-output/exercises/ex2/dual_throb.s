#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR       ; LED1 + LED2 = output

    ; Make LED1 and LED2 each "throb" — a breathing-like rhythm of getting
    ; brighter then dimmer — using only on/off bit idioms (no PWM, no
    ; timer peripheral yet; you only have delay loops and BIS/BIC/XOR).
    ; The two LEDs must throb out of phase with each other (when one is
    ; near its brightest point in the cycle, the other should be near its
    ; dimmest), and switching phase must never produce a visible flicker
    ; glitch on either LED. See exercises/README.md for full success
    ; criteria.

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
