#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; LED1 as output
    bic.b   #LED1, &P1OUT               ; LED1 off

;==============================================================================
; Simulate a press counter (R12) that advances once per pass through the
; main loop, standing in for a debounced button-press count you'd normally
; read from hal/input.s. LED1 should stay dark until the counter reaches
; TARGET_COUNT, then light up.
;==============================================================================
.equ    TARGET_COUNT, 5

    mov.w   #0, R12                     ; press counter starts at 0

main_loop:
    inc.w   R12                         ; one more "press" happened
    cmp.w   #TARGET_COUNT, R12          ; has the counter reached its target?

    ; Give the reading a brief settle before acting on it, the same idea
    ; as a debounce window, just simplified to a fixed pause here.
    mov.w   #200, R13
    call    #settle_delay

    jeq     target_reached
    jmp     not_yet

target_reached:
    bis.b   #LED1, &P1OUT
    jmp     hold

not_yet:
    bic.b   #LED1, &P1OUT

hold:
    mov.w   #300, R13
    call    #settle_delay
    jmp     main_loop

;==============================================================================
; settle_delay
; Busy-wait for R13 x ~1 ms at 1 MHz.
;==============================================================================
settle_delay:
.Lsettle_outer:
    mov.w   #333, R14
.Lsettle_inner:
    dec.w   R14
    jnz     .Lsettle_inner
    dec.w   R13
    jnz     .Lsettle_outer
    ret

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
