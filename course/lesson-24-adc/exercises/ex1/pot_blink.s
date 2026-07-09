#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; P1.0 = output
    bic.b   #LED1, &P1OUT                ; start with LED1 off

;==============================================================================
; Exercise 1 — Potentiometer Blink Rate
;
; Read the potentiometer wired to P1.4 (ADC10 channel 4, AVCC/GND as the
; reference — not the temperature sensor's internal reference) and use the
; reading to control LED1's blink rate: turning the pot should visibly
; speed up or slow down the blink, continuously, as you turn it.
;
; Look up:
;   - SLAU144 Ch. 22 — ADC10AE0 (why it, not P1SEL, routes a pin to the ADC)
;   - SLAU144 Ch. 22 — the SREF field, and why a full-range external signal
;     doesn't need the internal reference
;   - The INCH field's bit position in ADC10CTL1 (msp430g2553-defs.s,
;     right above INCH_10) — derive the channel-4 value yourself
;
; Success criteria:
;   - `make flash` builds and flashes without error
;   - Turning the pot end to end visibly and continuously changes the
;     blink rate as you turn it, not just once
;   - The change is monotonic: one turn direction only speeds up, the
;     other only slows down
;==============================================================================


    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
