#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR        ; LED1 + LED2 outputs
    bic.b   #(LED1|LED2), &P1OUT        ; both off

    bic.b   #BTN, &P1DIR                 ; BTN input
    bis.b   #BTN, &P1REN                 ; enable pull resistor
    bis.b   #BTN, &P1OUT                 ; pull-UP (reads 1 when released)

; -----------------------------------------------------------------------------
; TASK — Edge-count demo
;
; Using your own tick-based debounce and press-edge detection, count
; press-edges and display the count (mod 4) as a 2-bit binary pattern on
; LED1 + LED2 — each new detected press should visibly advance the pattern
; by one, and bounce must never cause it to advance more than once per
; physical press.
;
; Look up: SLAU144 Ch 8 (Digital I/O).
; -----------------------------------------------------------------------------

main_loop:
    jmp     main_loop

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
