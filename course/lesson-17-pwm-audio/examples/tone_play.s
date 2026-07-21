;******************************************************************************
; tone_play.s — Lesson 17 example
;
; Plays a fixed 440 Hz (A4) tone through the LM386/speaker in a repeating
; on/off pattern, with LED1 blinking in sync — audible AND visual
; confirmation that the PWM setup is correct.
;
; Wiring (see Handheld-MSP430 repo -> wiring/phase-4-audio.md):
;   P2.4 (TA1.2, Timer1_A3 CCR2) -> 10uF cap -> LM386 pin 3 -> speaker
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

; --- Timer1_A3 — the second, independent Timer_A instance. Same register
;     layout as Timer_A (TACTL etc.), offset +0x20. Not yet in
;     msp430g2553-defs.s (only Timer0_A3 is), so defined locally here.
.equ    TA1CTL,    0x0180
.equ    TA1CCTL2,  0x0186
.equ    TA1CCR0,   0x0192
.equ    TA1CCR2,   0x0196

.equ    PWM_PIN,        BIT4        ; P2.4 = TA1.2 output

.equ    SMCLK_HZ,       1000000
.equ    TONE_A4_HZ,     440
.equ    TONE_A4_PERIOD, (SMCLK_HZ/TONE_A4_HZ)-1    ; 2271 — matches
                                                      ; Handheld-MSP430 repo -> wiring/phase-4-audio.md
.equ    TONE_A4_DUTY,   (TONE_A4_PERIOD+1)/2        ; 50% duty ~= 1136

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL   ; disable watchdog
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1      ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #leds_init
    call    #tone_init

main_loop:
    bis.b   #PWM_PIN, &P2SEL     ; attach TA1.2 to the pin -> tone sounds
    bis.b   #LED1, &P1OUT
    mov.w   #20000, R13
    call    #delay_loop

    bic.b   #PWM_PIN, &P2SEL     ; detach -> plain GPIO, driven low, silent
    bic.b   #LED1, &P1OUT
    mov.w   #20000, R13
    call    #delay_loop
    jmp     main_loop

;==============================================================================
leds_init:
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT
    ret

;==============================================================================
; tone_init — configure Timer1_A3 for a fixed A4 (440 Hz) square wave on
; P2.4/TA1.2. Starts detached (silent) until main_loop attaches the pin.
;==============================================================================
tone_init:
    bic.b   #PWM_PIN, &P2SEL     ; start detached (silent)
    bis.b   #PWM_PIN, &P2DIR     ; output direction (required either way)
    bic.b   #PWM_PIN, &P2OUT     ; low while detached

    mov.w   #TONE_A4_PERIOD, &TA1CCR0
    mov.w   #TONE_A4_DUTY, &TA1CCR2
    mov.w   #OUTMOD_7, &TA1CCTL2            ; Reset/Set — standard PWM
    mov.w   #(TASSEL_2|MC_1|TACLR), &TA1CTL ; SMCLK, up mode, start clean
    ret

;==============================================================================
; delay_loop — R13 = iteration count (~3 cycles/iteration at 1 MHz)
;==============================================================================
delay_loop:
    dec.w   R13
    jnz     delay_loop
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
