;******************************************************************************
; Lesson 12 — Exercise 1: Bit-Bang SPI
;
; Transmit the byte 0xA5 over a manually-toggled clock (P1.5) and data
; (P1.7) line, MSB first, obeying SPI Mode 0 timing (clock idles LOW, data
; set up before the clock's rising edge). Read the bits back on P1.6 using
; the P1.7 -> P1.6 loopback jumper from the lesson setup, reconstructing the
; byte you sent.
;
; No USCI_B0 registers in this file — P1.5/P1.6/P1.7 stay in GPIO mode
; (P1SEL/P1SEL2 untouched).
;
; LED1 ON  = the byte you bit-banged and read back equals 0xA5
; LED1 OFF = it doesn't
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ TEST_BYTE, 0xA5

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; Configure P1.5 (clock) and P1.7 (data out) as GPIO outputs.
    ; Configure P1.6 (data in) as a GPIO input.
    ; Clock idles LOW.

    ; Your bit-bang transmit/receive loop here.

    ; Compare the reconstructed byte against TEST_BYTE and drive LED1.

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
