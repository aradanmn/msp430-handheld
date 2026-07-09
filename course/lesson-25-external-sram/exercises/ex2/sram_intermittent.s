;******************************************************************************
; sram_intermittent.s — Lesson 25 Exercise 2 (Challenge)
;
; Writes four different test bytes to four different SRAM addresses, reads
; each one back, and blinks LED1 a number of times equal to how many of the
; four round-tripped correctly, then pauses and repeats forever.
;
; Hardware: same as the lesson example — 23LC1024 on the existing SPI bus,
; SRAM_CS = P2.5.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

.equ    SRAM_CS,            BIT5

.equ    SRAM_OPCODE_READ,   0x03
.equ    SRAM_OPCODE_WRITE,  0x02

; Four test addresses spread across the 128 KB part, each split into its
; 3 address bytes (MSB first).
.equ    ADDR0,          0x000010
.equ    ADDR0_HI,       (ADDR0 >> 16) & 0xFF
.equ    ADDR0_MID,      (ADDR0 >> 8)  & 0xFF
.equ    ADDR0_LO,       ADDR0 & 0xFF

.equ    ADDR1,          0x004000
.equ    ADDR1_HI,       (ADDR1 >> 16) & 0xFF
.equ    ADDR1_MID,      (ADDR1 >> 8)  & 0xFF
.equ    ADDR1_LO,       ADDR1 & 0xFF

.equ    ADDR2,          0x00C000
.equ    ADDR2_HI,       (ADDR2 >> 16) & 0xFF
.equ    ADDR2_MID,      (ADDR2 >> 8)  & 0xFF
.equ    ADDR2_LO,       ADDR2 & 0xFF

.equ    ADDR3,          0x01F000
.equ    ADDR3_HI,       (ADDR3 >> 16) & 0xFF
.equ    ADDR3_MID,      (ADDR3 >> 8)  & 0xFF
.equ    ADDR3_LO,       ADDR3 & 0xFF

.equ    DATA0,          0x11
.equ    DATA1,          0x22
.equ    DATA2,          0x33
.equ    DATA3,          0x44

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    bis.b   #SRAM_CS, &P2DIR
    bis.b   #SRAM_CS, &P2OUT            ; idle HIGH

    call    #spi_init

.Lrun:
    clr.w   R7                          ; R7 = match count this round

    mov.b   #DATA0, R12
    mov.b   #ADDR0_HI, R13
    mov.b   #ADDR0_MID, R14
    mov.b   #ADDR0_LO, R15
    call    #sram_write_byte
    mov.b   #ADDR0_HI, R13
    mov.b   #ADDR0_MID, R14
    mov.b   #ADDR0_LO, R15
    call    #sram_read_byte
    cmp.b   #DATA0, R12
    jnz     .Lskip0
    inc.w   R7
.Lskip0:

    mov.b   #DATA1, R12
    mov.b   #ADDR1_HI, R13
    mov.b   #ADDR1_MID, R14
    mov.b   #ADDR1_LO, R15
    call    #sram_write_byte
    mov.b   #ADDR1_HI, R13
    mov.b   #ADDR1_MID, R14
    mov.b   #ADDR1_LO, R15
    call    #sram_read_byte
    cmp.b   #DATA1, R12
    jnz     .Lskip1
    inc.w   R7
.Lskip1:

    mov.b   #DATA2, R12
    mov.b   #ADDR2_HI, R13
    mov.b   #ADDR2_MID, R14
    mov.b   #ADDR2_LO, R15
    call    #sram_write_byte
    mov.b   #ADDR2_HI, R13
    mov.b   #ADDR2_MID, R14
    mov.b   #ADDR2_LO, R15
    call    #sram_read_byte
    cmp.b   #DATA2, R12
    jnz     .Lskip2
    inc.w   R7
.Lskip2:

    mov.b   #DATA3, R12
    mov.b   #ADDR3_HI, R13
    mov.b   #ADDR3_MID, R14
    mov.b   #ADDR3_LO, R15
    call    #sram_write_byte
    mov.b   #ADDR3_HI, R13
    mov.b   #ADDR3_MID, R14
    mov.b   #ADDR3_LO, R15
    call    #sram_read_byte
    cmp.b   #DATA3, R12
    jnz     .Lskip3
    inc.w   R7
.Lskip3:

    ; Blink LED1 R7 times, then pause, then repeat the whole round.
.Lblink_loop:
    tst.w   R7
    jz      .Lpause
    bis.b   #LED1, &P1OUT
    call    #delay
    bic.b   #LED1, &P1OUT
    call    #delay
    dec.w   R7
    jmp     .Lblink_loop
.Lpause:
    call    #delay
    call    #delay
    call    #delay
    jmp     .Lrun

;==============================================================================
; spi_init / spi_tx_byte — established in Lesson 12, unchanged
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
; sram_write_byte — in: R12 = data byte, R13/R14/R15 = addr hi/mid/lo
;==============================================================================
sram_write_byte:
    push    R12
    push    R13
    push    R14
    push    R15

    bic.b   #SRAM_CS, &P2OUT

    mov.b   #SRAM_OPCODE_WRITE, R12
    call    #spi_tx_byte
    mov.b   14(SP), R12                 ; R13 saved value (addr hi)
    call    #spi_tx_byte
    bis.b   #SRAM_CS, &P2OUT
    bic.b   #SRAM_CS, &P2OUT
    mov.b   12(SP), R12                 ; R14 saved value (addr mid)
    call    #spi_tx_byte
    mov.b   10(SP), R12                 ; R15 saved value (addr lo)
    call    #spi_tx_byte
    mov.b   8(SP), R12                  ; original data byte
    call    #spi_tx_byte

    bis.b   #SRAM_CS, &P2OUT

    pop     R15
    pop     R14
    pop     R13
    pop     R12
    ret

;==============================================================================
; sram_read_byte — in: R13/R14/R15 = addr hi/mid/lo, out: R12 = data byte
;==============================================================================
sram_read_byte:
    bic.b   #SRAM_CS, &P2OUT

    mov.b   #SRAM_OPCODE_READ, R12
    call    #spi_tx_byte
    mov.b   R13, R12
    call    #spi_tx_byte
    mov.b   R14, R12
    call    #spi_tx_byte
    mov.b   R15, R12
    call    #spi_tx_byte

    mov.b   #0x00, R12
    call    #spi_tx_byte

    bis.b   #SRAM_CS, &P2OUT
    ret

;==============================================================================
; delay
;==============================================================================
delay:
    push    R8
    mov.w   #50000, R8
.Ldelay_loop:
    dec.w   R8
    jnz     .Ldelay_loop
    pop     R8
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
