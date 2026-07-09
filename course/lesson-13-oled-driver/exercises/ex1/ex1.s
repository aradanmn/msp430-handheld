;******************************************************************************
; Lesson 13 — Exercise 1: Raw Bytes to OLED
;
; Bring the OLED controller out of display-off using only command bytes,
; then send the "Entire Display ON" override command so every pixel lights
; up regardless of GDDRAM contents. No addressing, no data bytes, no
; framebuffer needed for this exercise.
;
; spi_init / spi_tx_byte are provided below (Lesson 12). Everything specific
; to the OLED controller — the reset pulse, the init command sequence, the
; entire-display-on command, and the CS/DC protocol around each byte — is
; yours to build from tutorial-01 and your controller's datasheet.
;
; Success: every pixel on the panel lights up.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    OLED_CS,   BIT0     ; P2.0 — active LOW chip select
.equ    OLED_DC,   BIT1     ; P2.1 — LOW = command, HIGH = data
.equ    OLED_RST,  BIT2     ; P2.2 — active LOW hardware reset

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #spi_init

    ; Configure CS/DC/RST as outputs, CS idle high.

    ; Reset pulse: RST low, delay, RST high.

    ; Send whatever minimum command sequence your controller needs before
    ; it will accept further commands meaningfully, then the entire-display-on
    ; override command.

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; spi_init / spi_tx_byte — USCI_B0 SPI master, Mode 0, MSB-first (Lesson 12)
;==============================================================================
spi_init:
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL2

    bis.b   #UCSWRST, &UCB0CTL1
    mov.b   #(UCCKPH|UCMSB|UCMST|UCSYNC), &UCB0CTL0
    mov.b   #UCSSEL_2, &UCB0CTL1
    mov.b   #0x02, &UCB0BR0
    mov.b   #0x00, &UCB0BR1
    bic.b   #UCSWRST, &UCB0CTL1
    ret

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
