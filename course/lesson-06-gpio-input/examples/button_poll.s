#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

;==============================================================================
; button_poll
; How it works: LED1 (P1.0) live-tracks the state of S2 (P1.3).
;   Held down  → LED1 on
;   Released   → LED1 off
; This is level-tracking, not toggling — every pass through the loop just
; re-reads the current pin state and re-draws it. Because it never asks
; "did this just change since last time," it doesn't care how many times
; the input chattered on the way — it only ever shows the last thing it
; saw. That's what makes level-tracking naturally bounce-tolerant, in
; contrast with the toggle-on-press exercises later in this lesson.
;==============================================================================
    ; LED1 (P1.0): output, start OFF
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; S2 / BTN (P1.3): input, internal pull-up (reads 1 released, 0 pressed)
    bic.b   #BTN, &P1DIR    ; input (this is the reset default; be explicit)
    bis.b   #BTN, &P1REN    ; enable the pull resistor on P1.3
    bis.b   #BTN, &P1OUT    ; ...and pull it UP (not down)

.Lpoll:
    bit.b   #BTN, &P1IN     ; Z=1 if BTN reads 0 → button is pressed
    jz      .Lheld
    bic.b   #LED1, &P1OUT   ; released → LED1 off
    jmp     .Lpoll
.Lheld:
    bis.b   #LED1, &P1OUT   ; pressed → LED1 on
    jmp     .Lpoll

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
