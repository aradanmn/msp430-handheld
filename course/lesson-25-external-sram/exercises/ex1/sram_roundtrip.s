;******************************************************************************
; sram_roundtrip.s — Lesson 25 Exercise 1 (Explore)
;
; Target behavior: write a byte pattern of your choosing to an address of
; your choosing on the 23LC1024 SRAM chip, read it back, and light LED1
; solid if they match (off otherwise).
;
; SRAM_CS = P2.5 (new this lesson — not used by any earlier lesson).
;
; spi_init and spi_tx_byte below are exactly the Lesson 12 USCI_B0 SPI
; transport, unchanged — reuse them as-is. What's new in this exercise is
; the 23LC1024's instruction protocol (Tutorial 01): the opcode byte, the
; 3-byte address field, and the CS-low discipline around the whole
; transaction. That part is left to you.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

.equ    SRAM_CS,    BIT5      ; P2.5 — SRAM chip select

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT               ; LED1 off until the test passes

    ; --- TODO: configure SRAM_CS (P2.5) as an output, idling HIGH ---

    call    #spi_init

    ; --- TODO: pick an address and a test byte ---
    ; --- TODO: write the byte to SRAM, read it back, compare ---
    ; --- TODO: drive LED1 based on the comparison ---

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; spi_init — configure USCI_B0 as an SPI master: Mode 0, MSB-first, SMCLK
; (Established in Lesson 12 — unchanged.)
;==============================================================================
spi_init:
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL   ; P1.5/P1.6/P1.7 -> USCI_B0 peripheral function
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL2

    bis.b   #UCSWRST, &UCB0CTL1                       ; hold USCI_B0 in reset while configuring
    mov.b   #(UCCKPH|UCMSB|UCMST|UCSYNC), &UCB0CTL0   ; Mode 0, MSB first, master, synchronous
    mov.b   #UCSSEL_2, &UCB0CTL1                      ; SMCLK
    mov.b   #0x02, &UCB0BR0                           ; SMCLK / 2 = 500 kHz bit clock
    mov.b   #0x00, &UCB0BR1
    bic.b   #UCSWRST, &UCB0CTL1                       ; release reset — SPI is live
    ret

;==============================================================================
; spi_tx_byte — send byte in R12, return byte simultaneously received in R12
; (Established in Lesson 12 — unchanged.)
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

; --- TODO: sram_write_byte, sram_read_byte (or however you split the work) ---

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
