;******************************************************************************
; lpm3_wake.s — Lesson 26 Exercise 1 (Explore)
;
; Target behavior: configure ACLK to run from the internal VLO, enter LPM3,
; and wake on a press of the onboard S2 button (P1.3) via a Port 1
; interrupt. Toggle LED1 once per wake.
;
; The button's GPIO setup (pull-up input) below is the same pattern you've
; used since Lesson 06. What's new this lesson: selecting ACLK's source
; (see Tutorial 02, Part B, and SLAU144's Basic Clock System chapter), and
; using LPM3 instead of a lower-power mode you've used before.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; Button input, pull-up, falling edge (press = LOW) — same pattern
    ; established since Lesson 06.
    bic.b   #BTN, &P1DIR
    bis.b   #BTN, &P1REN
    bis.b   #BTN, &P1OUT
    bis.b   #BTN, &P1IES

    ; --- TODO: enable the Port 1 interrupt on this pin, clear any stale flag ---

    ; --- TODO: configure BCSCTL3 so ACLK runs from the internal VLO ---
    ; See Tutorial 02, Part B — this register/field isn't in
    ; msp430g2553-defs.s; look up SLAU144's Basic Clock System chapter.

.Lsleep:
    ; --- TODO: enter LPM3 (GIE + the appropriate LPM3 bits) ---
    jmp     .Lsleep

; --- TODO: port1_isr — clear the interrupt flag, toggle LED1, wake the CPU ---

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   0           ; 0xFFE4  Port 1 — TODO: point this at your ISR
    .word   0           ; 0xFFE6  Port 2
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI_A0/B0 TX
    .word   0           ; 0xFFEE  USCI_A0/B0 RX
    .word   0           ; 0xFFF0  Timer_A overflow (TAIV)
    .word   0           ; 0xFFF2  Timer_A CC0
    .word   0           ; 0xFFF4  WDT
    .word   0           ; 0xFFF6  Comparator_A+
    .word   0           ; 0xFFF8  Timer1_A1
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
    .end
