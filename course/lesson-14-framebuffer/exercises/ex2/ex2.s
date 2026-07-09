;******************************************************************************
; Lesson 14 — Exercise 2: Dirty-Page Optimisation
;
; Fills the entire 128x64 screen using framebuf_fill_rect, exactly the
; approach from this lesson's tutorial and example. Build it, flash it,
; and watch the screen while it runs.
;
; See exercises/README.md for the problem statement.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    OLED_CS,   BIT0
.equ    OLED_DC,   BIT1
.equ    OLED_RST,  BIT2

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #spi_init
    call    #display_init
    call    #display_clear

    mov.w   #0, R12
    mov.w   #0, R13
    mov.w   #127, R14
    mov.w   #63, R15
    call    #framebuf_fill_rect          ; fill the entire screen

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; spi_init / spi_tx_byte
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
; oled_cmd / oled_data / short_delay
;==============================================================================
oled_cmd:
    bic.b   #OLED_CS, &P2OUT
    bic.b   #OLED_DC, &P2OUT
    call    #spi_tx_byte
    bis.b   #OLED_CS, &P2OUT
    ret

oled_data:
    bic.b   #OLED_CS, &P2OUT
    bis.b   #OLED_DC, &P2OUT
    call    #spi_tx_byte
    bis.b   #OLED_CS, &P2OUT
    ret

short_delay:
    push    R15
    mov.w   #2000, R15
.Ldelay_loop:
    dec.w   R15
    jnz     .Ldelay_loop
    pop     R15
    ret

;==============================================================================
; display_init / display_clear / display_set_pixel
;==============================================================================
display_init:
    bis.b   #(OLED_CS|OLED_DC|OLED_RST), &P2DIR
    bis.b   #OLED_CS, &P2OUT

    bic.b   #OLED_RST, &P2OUT
    call    #short_delay
    bis.b   #OLED_RST, &P2OUT
    call    #short_delay

    mov.w   #init_cmds, R11
.Linit_loop:
    cmp.w   #init_cmds_end, R11
    jz      .Linit_done
    mov.b   @R11, R12
    call    #oled_cmd
    inc.w   R11
    jmp     .Linit_loop
.Linit_done:
    ret

init_cmds:
    .byte   0xAE
    .byte   0xD5, 0x80
    .byte   0xA8, 0x3F
    .byte   0xD3, 0x00
    .byte   0x40
    .byte   0x8D, 0x14
    .byte   0x20, 0x00
    .byte   0xA1
    .byte   0xC8
    .byte   0xDA, 0x12
    .byte   0x81, 0xCF
    .byte   0xD9, 0xF1
    .byte   0xDB, 0x40
    .byte   0xA4
    .byte   0xA6
    .byte   0xAF
init_cmds_end:

display_clear:
    push    R11

    mov.b   #0x21, R12
    call    #oled_cmd
    mov.b   #0x00, R12
    call    #oled_cmd
    mov.b   #0x7F, R12
    call    #oled_cmd

    mov.b   #0x22, R12
    call    #oled_cmd
    mov.b   #0x00, R12
    call    #oled_cmd
    mov.b   #0x07, R12
    call    #oled_cmd

    mov.w   #(128*8), R11
.Lclear_loop:
    mov.b   #0x00, R12
    call    #oled_data
    dec.w   R11
    jnz     .Lclear_loop

    pop     R11
    ret

display_set_pixel:
    push    R9
    push    R10
    push    R11

    mov.w   R12, R11
    mov.w   R13, R10
    and.w   #0x07, R13
    mov.w   R10, R9
    rra.w   R9
    rra.w   R9
    rra.w   R9

    mov.b   #0x21, R12
    call    #oled_cmd
    mov.b   R11, R12
    call    #oled_cmd
    mov.b   R11, R12
    call    #oled_cmd

    mov.b   #0x22, R12
    call    #oled_cmd
    mov.b   R9, R12
    call    #oled_cmd
    mov.b   R9, R12
    call    #oled_cmd

    mov.w   R13, R9
    mov.b   pixel_bit_table(R9), R12
    call    #oled_data

    pop     R11
    pop     R10
    pop     R9
    ret

pixel_bit_table:
    .byte   0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80

;==============================================================================
; framebuf_fill_rect — R12=x0, R13=y0, R14=x1, R15=y1
;==============================================================================
framebuf_fill_rect:
    push    R7
    push    R8
    push    R9
    push    R10
    push    R11

    mov.w   R12, R8
    mov.w   R14, R9
    sub.w   R8, R9
    inc.w   R9

    mov.w   R13, R10
    mov.w   R15, R11
    sub.w   R13, R11
    inc.w   R11

.Lrow_loop:
    cmp.w   #0, R11
    jz      .Lrow_done
    mov.w   R9, R7
    mov.w   R8, R12
.Lcol_loop:
    cmp.w   #0, R7
    jz      .Lcol_done
    mov.w   R10, R13
    call    #display_set_pixel
    inc.w   R12
    dec.w   R7
    jmp     .Lcol_loop
.Lcol_done:
    inc.w   R10
    dec.w   R11
    jmp     .Lrow_loop
.Lrow_done:

    pop     R11
    pop     R10
    pop     R9
    pop     R8
    pop     R7
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
