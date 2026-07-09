;******************************************************************************
; ghost_press.s — Lesson 16, Exercise 2 (Challenge)
;
; Wire up the shift register exactly as in the lesson example and flash
; this program. See exercises/README.md for what you should observe and
; what you need to fix.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    SR_PL,      BIT3        ; P2.3 — SH/LD (parallel load) pin
.equ    BTN_UP,     BIT7        ; bit 7 of the inverted read byte

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #leds_init
    call    #shiftreg_init

main_loop:
    call    #shiftreg_read          ; R12 = 8 button bits, 1 = pressed
    bit.b   #BTN_UP, R12
    jz      .Lbtn_released
    bis.b   #LED1, &P1OUT
    jmp     .Lpoll_delay
.Lbtn_released:
    bic.b   #LED1, &P1OUT
.Lpoll_delay:
    mov.w   #15000, R13
    call    #delay_loop
    jmp     main_loop

;==============================================================================
leds_init:
    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT
    ret

;==============================================================================
shiftreg_init:
    bis.b   #SR_PL, &P2DIR
    bis.b   #SR_PL, &P2OUT

    bis.b   #(BIT5|BIT6|BIT7), &P1SEL
    bis.b   #(BIT5|BIT6|BIT7), &P1SEL2

    bis.b   #UCSWRST, &UCB0CTL1
    mov.b   #(UCCKPH|UCMSB|UCMST|UCSYNC), &UCB0CTL0
    mov.b   #(UCSSEL_2|UCSWRST), &UCB0CTL1
    mov.b   #2, &UCB0BR0
    mov.b   #0, &UCB0BR1
    bic.b   #UCSWRST, &UCB0CTL1
    ret

;==============================================================================
shiftreg_read:
    bic.b   #SR_PL, &P2OUT
    nop
    nop
    bis.b   #SR_PL, &P2OUT

    mov.b   #0xFF, &UCB0TXBUF
    mov.b   &UCB0RXBUF, R12
    xor.b   #0xFF, R12
    ret

;==============================================================================
delay_loop:
    dec.w   R13
    jnz     delay_loop
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
