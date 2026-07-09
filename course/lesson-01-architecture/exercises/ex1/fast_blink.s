#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR                ; P1.0 = output
    bic.b   #LED1, &P1OUT                ; start with LED1 off

;==============================================================================
; Exercise 1 — Faster Blink
;
; Make LED1 (P1.0) blink at approximately 4 Hz instead of the 1 Hz rate
; from examples/blink.s. Derive your own delay constants — do not reuse
; the 500 ms values from the lesson example.
;
; Look up:
;   - SLAU144 Chapter 8 (Digital I/O) if you need to revisit P1DIR/P1OUT
;   - SLAU144 Chapter 1 (CPU) for how many cycles arithmetic and jump
;     instructions take at the calibrated 1 MHz clock rate
;
; Success criteria:
;   - `make flash` builds and flashes without error
;   - LED1 blinks visibly faster than the Lesson 01 example
;   - Ten full on/off cycles take roughly 2.5 seconds end to end
;     (timeable with a stopwatch) — i.e., close to 4 Hz
;   - LED2 stays off throughout
;==============================================================================


    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
