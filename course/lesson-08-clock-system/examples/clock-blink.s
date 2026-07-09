;******************************************************************************
; clock-blink.s — Lesson 08 example
;
; Calibrates the DCO to 1 MHz (the standard sequence) and blinks LED1 at
; exactly 1 Hz (on 0.5 s / off 0.5 s) using a software delay loop whose
; constants are derived from the calibrated clock frequency with `.equ`
; arithmetic — not guessed-and-checked.
;
; This is still the software-delay approach from Part I. Lesson 09 replaces
; it with a hardware Timer_A tick, which is both more precise and frees the
; CPU to do other work while it waits.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants — derived from the calibrated clock, not hardcoded
;==============================================================================
.equ    DCO_HZ,             1000000     ; DCO calibrated to 1 MHz (CALBC1_1MHZ/CALDCO_1MHZ)
.equ    HALF_SEC_CYCLES,    (DCO_HZ / 2)        ; cycles in 0.5 s at 1 MHz = 500,000

; Inner loop: dec.w (1 cycle) + jnz taken (2 cycles) = 3 cycles/iteration
.equ    CYCLES_PER_ITER,    3
.equ    INNER_COUNT,        500                 ; iterations per outer pass
.equ    INNER_CYCLES,       (INNER_COUNT * CYCLES_PER_ITER)   ; ≈ 1,500 cycles/pass
.equ    OUTER_COUNT,        (HALF_SEC_CYCLES / INNER_CYCLES)  ; outer passes for ~0.5 s

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; P1.0 = output
    bic.b   #LED1, &P1OUT               ; start with LED1 off

.Lblink:
    xor.b   #LED1, &P1OUT               ; toggle LED1
    call    #delay_half_sec
    jmp     .Lblink

;==============================================================================
; delay_half_sec — busy-waits for approximately HALF_SEC_CYCLES cycles
;==============================================================================
delay_half_sec:
    mov.w   #OUTER_COUNT, R14
.Louter:
    mov.w   #INNER_COUNT, R15
.Linner:
    dec.w   R15
    jnz     .Linner
    dec.w   R14
    jnz     .Louter
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
