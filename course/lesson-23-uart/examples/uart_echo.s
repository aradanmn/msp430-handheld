;******************************************************************************
; uart_echo.s — Lesson 23 example
;
; USCI_A0 UART at 9600 baud (P1.1 = RXD, P1.2 = TXD). On boot, transmits a
; greeting string. After that, echoes every received byte back out, forever.
; Everything here is polling-based — see tutorial-02 for why the final
; handheld milestone (ex3) switches RX to interrupt-driven instead.
;
; Test it: flash, then `picocom -b 9600 /dev/cu.usbmodem*`. You should see
; the greeting immediately, and every key you type echoed back.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; Greeting text — sent once at boot, before the echo loop begins.
; GREETING_LEN is computed by the assembler from the label difference, so it
; always matches the string above it even if the text changes.
;==============================================================================
.Lgreeting:
    .ascii  "MSP430 READY\r\n"
.Lgreeting_end:
.equ    GREETING_LEN, (.Lgreeting_end - .Lgreeting)

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

;==============================================================================
; USCI_A0 UART init — 9600 baud @ 1 MHz SMCLK (see tutorial-01 for the
; derivation of 104 / 0x02). Reused verbatim every time this course needs
; UART.
;==============================================================================
    bis.b   #(UART_RX|UART_TX), &P1SEL
    bis.b   #(UART_RX|UART_TX), &P1SEL2
    bis.b   #UCSWRST, &UCA0CTL1
    mov.b   #UCSSEL_2, &UCA0CTL1       ; SMCLK
    mov.b   #104, &UCA0BR0             ; 1MHz/104 ≈ 9600
    mov.b   #0, &UCA0BR1
    mov.b   #0x02, &UCA0MCTL
    bic.b   #UCSWRST, &UCA0CTL1

;==============================================================================
; Send the greeting once, one byte at a time.
;==============================================================================
    mov.w   #.Lgreeting, R14        ; R14 = pointer to next byte to send
    mov.w   #GREETING_LEN, R15      ; R15 = bytes remaining
.Lsend_greeting:
    mov.b   @R14+, R12              ; fetch byte, advance pointer
    call    #uart_tx_byte
    dec.w   R15
    jnz     .Lsend_greeting

;==============================================================================
; main_loop
; How it works: wait for a received byte, then transmit that same byte back
;   out. Both waits are polling loops against IFG2 — the CPU does nothing
;   else while waiting.
;==============================================================================
main_loop:
    bit.b   #UCA0RXIFG, &IFG2       ; has a byte arrived?
    jz      main_loop               ; no — keep waiting
    mov.b   &UCA0RXBUF, R12         ; read it (clears UCA0RXIFG)
    call    #uart_tx_byte           ; echo it back out
    jmp     main_loop

;==============================================================================
; uart_tx_byte
; How it works: busy-waits for UCA0TXIFG (the previous byte has finished
;   shifting out and UCA0TXBUF is free), then writes the new byte.
;   Input:    R12 = byte to send
;   Clobbers: none (R12 preserved)
;==============================================================================
uart_tx_byte:
.Lwait_tx:
    bit.b   #UCA0TXIFG, &IFG2       ; is the transmit buffer free?
    jz      .Lwait_tx               ; no — keep waiting
    mov.b   R12, &UCA0TXBUF
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
