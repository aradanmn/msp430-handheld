#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR         ; P1.0 and P1.6 = outputs

;==============================================================================
; Exercise 2 — Alternating LEDs
;
; LED1 and LED2 must alternate every 500 ms. At every instant, exactly one
; of them is lit — never both at once, never neither. Design your own
; approach.
;
; Success criteria:
;   - `make flash` builds and flashes without error
;   - At any moment you glance at the board, exactly one LED is lit
;   - The two LEDs swap roughly every 500 ms, continuously
;   - No visible instant where both LEDs are lit together, and no visible
;     instant where both are dark together
;==============================================================================


    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
