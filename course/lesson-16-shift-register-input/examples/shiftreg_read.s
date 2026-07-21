;******************************************************************************
; shiftreg_read.s — Lesson 16 example
;
; Reads all 8 buttons from the SN74HC165N parallel-in shift register over
; USCI_B0 SPI and lights LED1 whenever the "A" button (bit 0) is held.
; Holding any other button must NOT light LED1 — that's the self-test that
; confirms both the wiring and the bit order are correct.
;
; Wiring (see Handheld-MSP430 repo -> wiring/phase-3-buttons-shift-register.md):
;   SN74HC165 SH/LD (PL) -> P2.3   (GPIO, pulse LOW then HIGH to latch)
;   SN74HC165 CLK        -> P1.5   (shared USCI_B0 SPI clock)
;   SN74HC165 QH         -> P1.6   (USCI_B0 MISO — remove the LED2 jumper!)
;   SN74HC165 SER        -> GND    (no daisy-chained second register)
;   SN74HC165 CLK INH    -> GND    (always shifting when PL is high)
;
; Bit mapping after the read + invert below (1 = pressed):
;   bit7 Up   bit6 Down  bit5 Left  bit4 Right
;   bit3 Select  bit2 Start  bit1 B  bit0 A
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

; --- pin/bit aliases local to this file ---
.equ    SR_PL,      BIT3        ; P2.3 — SH/LD (parallel load) pin
.equ    BTN_A,      BIT0        ; bit 0 of the inverted read byte

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL   ; disable watchdog
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1      ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #leds_init
    call    #shiftreg_init

main_loop:
    call    #shiftreg_read          ; R12 = 8 button bits, 1 = pressed
    bit.b   #BTN_A, R12
    jz      .Lbtn_a_released
    bis.b   #LED1, &P1OUT
    jmp     .Lpoll_delay
.Lbtn_a_released:
    bic.b   #LED1, &P1OUT
.Lpoll_delay:
    mov.w   #5000, R13
    call    #delay_loop
    jmp     main_loop

;==============================================================================
; leds_init — LED1 as output, off
;==============================================================================
leds_init:
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT
    ret

;==============================================================================
; shiftreg_init — configure P2.3 (PL) and USCI_B0 as an SPI master for
; reading the SN74HC165N
;==============================================================================
shiftreg_init:
    bis.b   #SR_PL, &P2DIR
    bis.b   #SR_PL, &P2OUT              ; idle HIGH = shift mode

    bis.b   #(BIT5|BIT6|BIT7), &P1SEL   ; P1.5/6/7 -> USCI_B0 CLK/MISO/MOSI
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL2

    bis.b   #UCSWRST, &UCB0CTL1                     ; hold USCI_B0 in reset
    mov.b   #(UCCKPH|UCMSB|UCMST|UCSYNC), &UCB0CTL0 ; SPI master, mode 0,0
    mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1          ; SMCLK, still in reset
    mov.b   #2, &UCB0BR0                            ; SMCLK/2 = 500 kHz
    mov.b   #0, &UCB0BR1
    bic.b   #UCSWRST, &UCB0CTL1                     ; release reset
    ret

;==============================================================================
; shiftreg_read — latch + read the 8 button states
;   Returns: R12 = button bitmap, 1 = pressed (mapping in header comment)
;==============================================================================
shiftreg_read:
    bic.b   #SR_PL, &P2OUT      ; PL low  — parallel load (snapshot pins)
    nop
    nop
    bis.b   #SR_PL, &P2OUT      ; PL high — shift mode

    mov.b   #0xFF, &UCB0TXBUF   ; dummy byte — its only job is to toggle
                                  ; CLK 8 times so QH's 8 bits shift out
.Lwait_rx:
    bit.b   #UCB0RXIFG, &IFG2
    jz      .Lwait_rx
    mov.b   &UCB0RXBUF, R12
    xor.b   #0xFF, R12          ; active-low -> active-high (1 = pressed)
    ret

;==============================================================================
; delay_loop — R13 = iteration count (~3 cycles/iteration at 1 MHz)
;==============================================================================
delay_loop:
    dec.w   R13
    jnz     delay_loop
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
