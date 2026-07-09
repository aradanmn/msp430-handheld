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

    ; TODO: toggle LED1 (not just track level) each time you detect a NEW
    ; press of S2 — a transition from released to pressed. Press the
    ; button slowly and normally, several separate times, and watch
    ; closely for any press that seems to toggle the LED more than once,
    ; or not at all. See exercises/README.md for the full exercise write-up.

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
