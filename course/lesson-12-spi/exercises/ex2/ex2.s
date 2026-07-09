;******************************************************************************
; Lesson 12 — Exercise 2: USCI_B0 Loopback Bug
;
; Same setup as the lesson example: USCI_B0 configured as an SPI master,
; a test byte sent out MOSI (P1.7), looped back on MISO (P1.6) via a jumper
; wire, and LED1 lit if the received byte matches what was sent.
;
; Hardware: remove the LED2 jumper, add a P1.7 -> P1.6 jumper (same as the
; lesson example).
;
; LED1 ON  = received byte matched the transmitted byte
; LED1 OFF = mismatch
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

    call    #spi_init

    mov.b   #TEST_BYTE, R12
    call    #spi_tx_byte

    cmp.b   #TEST_BYTE, R12
    jnz     .Lfail
    bis.b   #LED1, &P1OUT
    jmp     .Lhalt
.Lfail:
    bic.b   #LED1, &P1OUT
.Lhalt:
    jmp     .Lhalt

;==============================================================================
; spi_init — configure USCI_B0 as an SPI master: Mode 0, MSB-first, SMCLK
;==============================================================================
spi_init:
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL   ; P1.5/P1.6/P1.7 -> peripheral function

    bis.b   #UCSWRST, &UCB0CTL1
    mov.b   #(UCCKPH|UCMSB|UCMST|UCSYNC), &UCB0CTL0
    mov.b   #UCSSEL_2, &UCB0CTL1
    mov.b   #0x02, &UCB0BR0
    mov.b   #0x00, &UCB0BR1
    bic.b   #UCSWRST, &UCB0CTL1
    ret

;==============================================================================
; spi_tx_byte — send byte in R12, return received byte in R12
;==============================================================================
spi_tx_byte:
.Lwait_tx:
    bit.b   #UCB0TXIFG, &IFG2
    jz      .Lwait_tx
    mov.b   R12, &UCB0TXBUF

.Lwait_rx:
    bit.b   #UCB0RXIFG, &IFG2
    jz      .Lwait_rx
    mov.b   &UCB0RXBUF, R12
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
