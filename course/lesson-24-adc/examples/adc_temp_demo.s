;******************************************************************************
; adc_temp_demo.s — Lesson 24 example
;
; Reads the MSP430G2553's internal temperature sensor (ADC10 channel 10)
; repeatedly, converts each raw reading to an approximate °C value, and
; blinks LED1 that many times before pausing and reading again. Warmer rooms
; produce more blinks per cycle; colder rooms produce fewer.
;
; ADC10 is configured once, using the exact reference pattern this course's
; material has used throughout (see tutorial-01) — including the settle
; delay after enabling the internal reference. Only ENC|ADC10SC are
; re-triggered on each subsequent reading; the reference is never turned
; off and on again, so it never needs to re-settle after the first sample.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; Timing / conversion constants
;==============================================================================
.equ    ADC_SETTLE_ITERS,  10      ; ~30 cycles @ 3 cycles/iter ≈ 30 µs @ 1 MHz
.equ    BLINK_ON_MS,        150
.equ    BLINK_OFF_MS,       150
.equ    PAUSE_MS,          2000    ; pause between temperature readings

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
; ADC10 init — internal temperature sensor, channel 10. Configured once;
; only ENC|ADC10SC are re-triggered per reading from here on.
;==============================================================================
    mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
    mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0

    ; wait ~30 µs for the internal reference to settle before the very
    ; first conversion (see tutorial-01 and exercise 2 for what happens if
    ; you skip this).
    mov.w   #ADC_SETTLE_ITERS, R14
.Lsettle:
    dec.w   R14
    jnz     .Lsettle

;==============================================================================
; reading_loop
; How it works: trigger a conversion, wait for it, convert the raw result
;   to an approximate °C value, blink LED1 that many times, pause, repeat.
;==============================================================================
reading_loop:
    bis.w   #(ENC|ADC10SC), &ADC10CTL0
.Lpoll:
    bit.w   #ADC10BUSY, &ADC10CTL1
    jnz     .Lpoll
    mov.w   &ADC10MEM, R5               ; R5 = raw 10-bit result

    ; T°C ≈ (raw - 673) / 4 + 25  (see tutorial-02)
    sub.w   #673, R5                    ; may go negative in a cold room
    rra.w   R5                          ; /2 (sign-preserving shift)
    rra.w   R5                          ; /2 again -> net /4
    add.w   #25, R5                     ; R5 = approx T in °C

    ; Clamp to a sane minimum before using it as a blink count — a
    ; zero or negative count would underflow the countdown loop below
    ; into a very long run instead of skipping the blink cleanly.
    cmp.w   #1, R5
    jn      .Lclamp_min
    jmp     .Lgot_count
.Lclamp_min:
    mov.w   #1, R5
.Lgot_count:

    mov.w   R5, R6                      ; R6 = blink countdown
.Lblink_loop:
    bis.b   #LED1, &P1OUT
    mov.w   #BLINK_ON_MS, R12
    call    #.Ldelay_ms
    bic.b   #LED1, &P1OUT
    mov.w   #BLINK_OFF_MS, R12
    call    #.Ldelay_ms
    dec.w   R6
    jnz     .Lblink_loop

    mov.w   #PAUSE_MS, R12
    call    #.Ldelay_ms
    jmp     reading_loop

;==============================================================================
; .Ldelay_ms
; How it works: busy-wait for approximately R12 milliseconds at 1 MHz.
;   Input:    R12 = number of milliseconds to wait
;   Clobbers: R12, R13
;==============================================================================
.Ldelay_ms:
    mov.w   #333, R13               ; 333 iterations ≈ 1 ms at 1 MHz
.Ltms_loop:
    dec.w   R13
    jnz     .Ltms_loop
    dec.w   R12
    jnz     .Ldelay_ms
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
