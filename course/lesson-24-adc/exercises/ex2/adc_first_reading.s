;******************************************************************************
; adc_first_reading.s — Lesson 24 Exercise 2 (Challenge)
;
; Intended behavior: read the internal temperature sensor repeatedly,
; converting each reading to an approximate °C value and blinking LED1 that
; many times before pausing and reading again — every reading, from the
; very first one after reset onward, should track the room's actual
; temperature.
;
; Build it, flash it, and observe several reading cycles across a few
; resets. See exercises/README.md for what you should be checking against.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

.equ    BLINK_ON_MS,        150
.equ    BLINK_OFF_MS,       150
.equ    PAUSE_MS,          2000

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    mov.w   #(INCH_10|ADC10SSEL_3|CONSEQ_0), &ADC10CTL1
    mov.w   #(SREF_1|ADC10SHT_3|REFON|ADC10ON), &ADC10CTL0

;==============================================================================
; reading_loop
;==============================================================================
reading_loop:
    bis.w   #(ENC|ADC10SC), &ADC10CTL0
.Lpoll:
    bit.w   #ADC10BUSY, &ADC10CTL1
    jnz     .Lpoll
    mov.w   &ADC10MEM, R5

    ; T°C ≈ (raw - 673) / 4 + 25
    sub.w   #673, R5
    rra.w   R5
    rra.w   R5
    add.w   #25, R5

    cmp.w   #1, R5
    jn      .Lclamp_min
    jmp     .Lgot_count
.Lclamp_min:
    mov.w   #1, R5
.Lgot_count:

    mov.w   R5, R6
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
; .Ldelay_ms — busy-wait for approximately R12 milliseconds at 1 MHz.
;==============================================================================
.Ldelay_ms:
    mov.w   #333, R13
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
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
