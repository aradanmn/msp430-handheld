;******************************************************************************
; burst_echo.s — Lesson 23 Exercise 2 (Challenge)
;
; Intended behavior: transmit "MSP430 READY\r\n" once at boot, then echo
; every received byte back out, forever — byte for byte, no matter how fast
; the input arrives.
;
; Build it, flash it, and test it per exercises/README.md.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.Lgreeting:
    .ascii  "MSP430 READY\r\n"
.Lgreeting_end:
.equ    GREETING_LEN, (.Lgreeting_end - .Lgreeting)

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(UART_RX|UART_TX), &P1SEL
    bis.b   #(UART_RX|UART_TX), &P1SEL2
    bis.b   #UCSWRST, &UCA0CTL1
    mov.b   #UCSSEL_2, &UCA0CTL1
    mov.b   #104, &UCA0BR0
    mov.b   #0, &UCA0BR1
    mov.b   #0x02, &UCA0MCTL
    bic.b   #UCSWRST, &UCA0CTL1

    mov.w   #.Lgreeting, R14
    mov.w   #GREETING_LEN, R15
.Lsend_greeting:
    mov.b   @R14+, R12
    call    #uart_tx_byte
    dec.w   R15
    jnz     .Lsend_greeting

;==============================================================================
; main_loop — wait for a received byte, then send it straight back out.
;==============================================================================
main_loop:
    bit.b   #UCA0RXIFG, &IFG2
    jz      main_loop
    mov.b   &UCA0RXBUF, R12
    mov.b   R12, &UCA0TXBUF
    jmp     main_loop

;==============================================================================
; uart_tx_byte — used only for the boot-time greeting.
;   Input:    R12 = byte to send
;==============================================================================
uart_tx_byte:
.Lwait_tx:
    bit.b   #UCA0TXIFG, &IFG2
    jz      .Lwait_tx
    mov.b   R12, &UCA0TXBUF
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
