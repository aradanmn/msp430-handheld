;******************************************************************************
; Lesson 12 — Example: USCI_B0 SPI Loopback Self-Test
;
; Configures USCI_B0 as an SPI master (Mode 0: CPOL=0, CPHA=0, MSB-first) and
; transmits a test byte out MOSI (P1.7). With a jumper wire from P1.7 to P1.6
; (MOSI -> MISO) on the LaunchPad header, the same byte loops straight back
; in on MISO and lands in UCB0RXBUF.
;
; Hardware:
;   - Remove the LED2 jumper first (LED2 = P1.6 = MISO — they conflict)
;   - Add a temporary jumper: P1.7 -> P1.6
;
; LED1 ON  = received byte matched the transmitted byte (SPI is working)
; LED1 OFF = mismatch (check the jumper, check UCB0CTL0/UCB0CTL1, check P1SEL/P1SEL2)
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ TEST_BYTE, 0xA5            ; 1010 0101 — alternating bits, easy to eyeball on a scope

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT               ; LED1 off until the test passes

    call    #spi_init

    mov.b   #TEST_BYTE, R12
    call    #spi_tx_byte                ; R12 = received byte on return

    cmp.b   #TEST_BYTE, R12
    jnz     .Lfail
    bis.b   #LED1, &P1OUT               ; match — light LED1
    jmp     .Lhalt
.Lfail:
    bic.b   #LED1, &P1OUT               ; mismatch — stay off
.Lhalt:
    jmp     .Lhalt

;==============================================================================
; spi_init — configure USCI_B0 as an SPI master: Mode 0, MSB-first, SMCLK
;==============================================================================
spi_init:
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL   ; P1.5/P1.6/P1.7 -> USCI_B0 peripheral function
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL2

    bis.b   #UCSWRST, &UCB0CTL1                       ; hold USCI_B0 in reset while configuring
    mov.b   #(UCCKPH|UCMSB|UCMST|UCSYNC), &UCB0CTL0   ; Mode 0, MSB first, master, synchronous
    mov.b   #UCSSEL_2, &UCB0CTL1                      ; SMCLK (UCSWRST still held — see tutorial-02)
    mov.b   #0x02, &UCB0BR0                           ; SMCLK / 2 = 500 kHz bit clock
    mov.b   #0x00, &UCB0BR1
    bic.b   #UCSWRST, &UCB0CTL1                       ; release reset — SPI is live
    ret

;==============================================================================
; spi_tx_byte — send byte in R12, return byte simultaneously received in R12
;==============================================================================
spi_tx_byte:
.Lwait_tx:
    bit.b   #UCB0TXIFG, &IFG2
    jz      .Lwait_tx                   ; wait for TX buffer to be free
    mov.b   R12, &UCB0TXBUF              ; load byte — shifting starts automatically

.Lwait_rx:
    bit.b   #UCB0RXIFG, &IFG2
    jz      .Lwait_rx                   ; wait for the byte to finish shifting in
    mov.b   &UCB0RXBUF, R12              ; return received byte in R12
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0            ; 0xFFE0-0xFFEF  unused
    .word   0,0,0,0, 0,0,0              ; 0xFFF0-0xFFFC  unused
    .word   _start                       ; 0xFFFE  Reset vector
    .end
