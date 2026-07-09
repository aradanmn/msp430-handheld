;******************************************************************************
; sram_test.s — Lesson 25 example
;
; Writes one test byte to a chosen address on a 23LC1024 SPI SRAM chip,
; reads it back, and compares. LED1 solid ON = match (round trip worked).
; LED1 blinking  = mismatch.
;
; Hardware: 23LC1024 SRAM sharing the SPI bus already wired for the OLED
; (SCLK = P1.5, MOSI = P1.7, SOMI = P1.6, per Lesson 12). This lesson adds
; the SRAM's own chip-select line, SRAM_CS = P2.5 — a new GPIO assignment,
; not used by any earlier lesson (P2.0-P2.4 are already the OLED's CS/DC/RST
; and the shift-register/audio pins per ROADMAP.md).
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; New this lesson: 23LC1024 chip select and instruction opcodes.
; Not in msp430g2553-defs.s — this chip is new to the course as of Lesson 25.
;==============================================================================
.equ    SRAM_CS,            BIT5        ; P2.5 — SRAM chip select (new pin)

.equ    SRAM_OPCODE_READ,   0x03        ; 23LC1024 READ instruction
.equ    SRAM_OPCODE_WRITE,  0x02        ; 23LC1024 WRITE instruction

; Test address: any 17-bit value (0x00000-0x1FFFF) is valid on a 128 KB part.
; Split into the 3 address bytes the chip expects, MSB first.
.equ    SRAM_TEST_ADDR,     0x01A2B
.equ    SRAM_ADDR_HI,       (SRAM_TEST_ADDR >> 16) & 0xFF   ; always 0 on this part
.equ    SRAM_ADDR_MID,      (SRAM_TEST_ADDR >> 8)  & 0xFF
.equ    SRAM_ADDR_LO,       SRAM_TEST_ADDR & 0xFF

.equ    TEST_BYTE,          0xA5        ; 1010 0101 — easy to eyeball on a scope

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

    bis.b   #SRAM_CS, &P2DIR            ; SRAM_CS as output
    bis.b   #SRAM_CS, &P2OUT            ; idle HIGH (deasserted) — active LOW

    call    #spi_init

    mov.b   #TEST_BYTE, R12
    call    #sram_write_byte            ; write TEST_BYTE to SRAM_TEST_ADDR

    call    #sram_read_byte             ; R12 = byte read back from SRAM_TEST_ADDR

    cmp.b   #TEST_BYTE, R12
    jnz     .Lfail
    bis.b   #LED1, &P1OUT               ; match — LED1 solid on
    jmp     .Lhalt
.Lfail:
.Lblink:
    xor.b   #LED1, &P1OUT               ; mismatch — blink forever
    call    #delay
    jmp     .Lblink
.Lhalt:
    jmp     .Lhalt

;==============================================================================
; spi_init — configure USCI_B0 as an SPI master: Mode 0, MSB-first, SMCLK
; (Same configuration established in Lesson 12 — reused verbatim; the SRAM
; and the OLED share this exact bus configuration.)
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
; (Same idiom established in Lesson 12.)
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
; sram_write_byte — write R12 to SRAM_TEST_ADDR on the 23LC1024
;
; CS stays asserted (LOW) for the entire opcode + address + data sequence —
; deasserting mid-transaction resets the chip's internal state machine
; (Tutorial 01).
;==============================================================================
sram_write_byte:
    push    R12                         ; save the data byte — spi_tx_byte clobbers R12

    bic.b   #SRAM_CS, &P2OUT            ; CS low — begin transaction

    mov.b   #SRAM_OPCODE_WRITE, R12
    call    #spi_tx_byte
    mov.b   #SRAM_ADDR_HI, R12
    call    #spi_tx_byte
    mov.b   #SRAM_ADDR_MID, R12
    call    #spi_tx_byte
    mov.b   #SRAM_ADDR_LO, R12
    call    #spi_tx_byte

    pop     R12                         ; restore the data byte
    call    #spi_tx_byte                ; clock the data byte out

    bis.b   #SRAM_CS, &P2OUT            ; CS high — end transaction
    ret

;==============================================================================
; sram_read_byte — read the byte at SRAM_TEST_ADDR, return it in R12
;
; Same CS-stays-low discipline as the write path. The final spi_tx_byte call
; sends a dummy byte (0x00) purely to drive the clock — its return value is
; the byte the SRAM shifted out.
;==============================================================================
sram_read_byte:
    bic.b   #SRAM_CS, &P2OUT            ; CS low — begin transaction

    mov.b   #SRAM_OPCODE_READ, R12
    call    #spi_tx_byte
    mov.b   #SRAM_ADDR_HI, R12
    call    #spi_tx_byte
    mov.b   #SRAM_ADDR_MID, R12
    call    #spi_tx_byte
    mov.b   #SRAM_ADDR_LO, R12
    call    #spi_tx_byte

    mov.b   #0x00, R12                  ; dummy byte — just drives the clock
    call    #spi_tx_byte                ; R12 now holds the byte read from SRAM

    bis.b   #SRAM_CS, &P2OUT            ; CS high — end transaction
    ret

;==============================================================================
; delay — plain cycle-counted software delay, used only for the blink
; indicator on mismatch (this is a self-test, not a timing-critical path;
; Timer_A is not needed here).
;==============================================================================
delay:
    push    R13
    mov.w   #50000, R13
.Ldelay_loop:
    dec.w   R13
    jnz     .Ldelay_loop
    pop     R13
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
