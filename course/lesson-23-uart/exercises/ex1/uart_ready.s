#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

;==============================================================================
; Exercise 1 — UART Ready
;
; Configure USCI_A0 for UART at 9600 baud (P1.1 = RXD, P1.2 = TXD). On boot,
; transmit the exact string "MSP430 READY\r\n" once. After that, echo every
; byte you receive back out, forever.
;
; Look up:
;   - SLAU144 Chapter 15 — USCI_A0 UART init sequence (clock source, baud
;     rate divisor registers, modulation control), and the reset-hold /
;     reset-release pattern around configuring them
;   - UCA0STAT in SLAU144 Chapter 15 (not needed yet, but worth knowing)
;
; Success criteria:
;   - `make flash` builds and flashes without error
;   - picocom -b 9600 /dev/cu.usbmodem* shows exactly "MSP430 READY" and a
;     newline once, right after reset
;   - Every character typed afterward is echoed back immediately
;   - A power cycle or reset repeats the greeting and resumes echoing
;==============================================================================


    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
