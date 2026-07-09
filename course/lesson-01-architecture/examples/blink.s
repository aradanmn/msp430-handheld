#include "../../common/msp430g2553-defs.s"

;==============================================================================
; blink.s — Lesson 01 example
;
; Blinks LED1 (P1.0, red) at a steady 1 Hz: 500 ms on, 500 ms off, forever.
; LED2 (P1.6) is left untouched.
;
; Delay math (see tutorial-01): at a calibrated 1 MHz clock, one cycle takes
; 1 microsecond. The inner loop below is a two-instruction countdown:
;   dec.w Rn   → 1 cycle
;   jnz   .L   → 2 cycles
; 3 cycles per inner iteration. 333 iterations × 3 cycles ≈ 999 cycles ≈ 1 ms.
; Counting that inner loop DELAY_MS_ITERS times per outer "1 ms tick", and
; the outer loop ON_TIME_MS / OFF_TIME_MS times, gives the total delay.
;==============================================================================

.equ    DELAY_MS_ITERS, 333     ; inner-loop iterations ≈ 1 ms at 1 MHz
.equ    ON_TIME_MS,     500     ; LED1 on duration
.equ    OFF_TIME_MS,    500     ; LED1 off duration

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
; main_loop
; How it works: turn LED1 on, wait ON_TIME_MS, turn LED1 off, wait
;   OFF_TIME_MS, repeat forever.
;==============================================================================
main_loop:
    bis.b   #LED1, &P1OUT               ; LED1 on
    mov.w   #ON_TIME_MS, R12
    call    #.Ldelay_ms
    bic.b   #LED1, &P1OUT               ; LED1 off
    mov.w   #OFF_TIME_MS, R12
    call    #.Ldelay_ms
    jmp     main_loop

;==============================================================================
; .Ldelay_ms
; How it works: busy-wait for approximately R12 milliseconds at 1 MHz.
;   Input:    R12 = number of milliseconds to wait
;   Clobbers: R12, R13
;==============================================================================
.Ldelay_ms:
    mov.w   #DELAY_MS_ITERS, R13    ; reload inner-loop counter
.Ltms_loop:
    dec.w   R13                     ; one cycle
    jnz     .Ltms_loop              ; two cycles
    dec.w   R12                     ; one ms elapsed
    jnz     .Ldelay_ms              ; more ms to wait? loop again
    ret                             ; done — return to caller

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
