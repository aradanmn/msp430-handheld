;******************************************************************************
; melody_demo.s — Lesson 18 example
;
; Plays a short fixed melody, note by note, from a table in Flash. This is
; a blocking preview of the idea — each note fully plays before the next
; starts — not the non-blocking, tick-driven sequencer the milestone
; builds. That distinction is the whole point of this lesson's tutorials.
;
; Wiring: same as Lesson 17 (P2.4 / TA1.2 -> LM386 -> speaker).
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

; --- Timer1_A3 (see Lesson 17) — not yet in msp430g2553-defs.s ---
.equ    TA1CTL,    0x0180
.equ    TA1CCTL2,  0x0186
.equ    TA1CCR0,   0x0192
.equ    TA1CCR2,   0x0196

.equ    PWM_PIN,   BIT4        ; P2.4 = TA1.2 output

; --- note table: period, computed once at assemble time from Hz ---
.equ    SMCLK_HZ,   1000000
.equ    NOTE_C4_HZ, 262
.equ    NOTE_E4_HZ, 330
.equ    NOTE_G4_HZ, 392
.equ    NOTE_C5_HZ, 523
.equ    NOTE_C4,    (SMCLK_HZ/NOTE_C4_HZ)-1
.equ    NOTE_E4,    (SMCLK_HZ/NOTE_E4_HZ)-1
.equ    NOTE_G4,    (SMCLK_HZ/NOTE_G4_HZ)-1
.equ    NOTE_C5,    (SMCLK_HZ/NOTE_C5_HZ)-1

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL   ; disable watchdog
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1      ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #tone_init

main_loop:
    mov.w   #melody, R14
.Lnote_loop:
    mov.w   @R14+, R12          ; period (0 = end of table)
    tst.w   R12
    jz      .Lmelody_done
    mov.w   @R14+, R13          ; duration in ms
    call    #play_note
    jmp     .Lnote_loop
.Lmelody_done:
    mov.w   #40000, R13
    call    #delay_loop
    jmp     main_loop

;==============================================================================
; tone_init — pin setup only; each note configures its own period/duty
;==============================================================================
tone_init:
    bic.b   #PWM_PIN, &P2SEL
    bis.b   #PWM_PIN, &P2DIR
    bic.b   #PWM_PIN, &P2OUT
    ret

;==============================================================================
; play_note — R12 = period, R13 = duration (ms). Blocking.
;==============================================================================
play_note:
    mov.w   R12, &TA1CCR0
    rra.w   R12                 ; R12 = period/2 -> 50% duty
    mov.w   R12, &TA1CCR2
    mov.w   #OUTMOD_7, &TA1CCTL2
    mov.w   #(TASSEL_2|MC_1|TACLR), &TA1CTL
    bis.b   #PWM_PIN, &P2SEL    ; attach -> audible

    mov.w   R13, R14
    call    #delay_ms

    bic.b   #PWM_PIN, &P2SEL    ; detach -> silent
    ret

;==============================================================================
; delay_ms — R14 = milliseconds (333 iterations/ms at 1 MHz)
;==============================================================================
delay_ms:
.Lms_outer:
    mov.w   #333, R15
.Lms_inner:
    dec.w   R15
    jnz     .Lms_inner
    dec.w   R14
    jnz     .Lms_outer
    ret

;==============================================================================
; delay_loop — R13 = iteration count
;==============================================================================
delay_loop:
    dec.w   R13
    jnz     delay_loop
    ret

;==============================================================================
; melody table — (period, duration_ms) pairs, 0 period = end of sequence
;==============================================================================
melody:
    .word   NOTE_C4, 200
    .word   NOTE_E4, 200
    .word   NOTE_G4, 200
    .word   NOTE_C5, 400
    .word   0

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
