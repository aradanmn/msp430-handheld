;******************************************************************************
; Lesson 15 — Exercise 1: Render Bitmap
;
; tile_plus is an 8x8 sprite bitmap (one byte per row, bit 7 = leftmost
; column, per tutorial-01). Implement sprite_draw(ptr, x, y): walk all 8
; rows, and within each row all 8 columns, calling display_set_pixel for
; every column whose bit is set. Columns whose bit is 0 are left
; untouched.
;
; display_init/display_clear/display_set_pixel and the SPI plumbing under
; them are provided below (Lessons 12-13) -- sprite_draw itself is yours
; to build.
;
; Success: the plus-shaped sprite is visible at (SPRITE_X, SPRITE_Y) on an
; otherwise blank screen.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    OLED_CS,   BIT0
.equ    OLED_DC,   BIT1
.equ    OLED_RST,  BIT2

.equ    SPRITE_X,  50
.equ    SPRITE_Y,  20

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #spi_init
    call    #display_init
    call    #display_clear

    mov.w   #tile_plus, R12
    mov.w   #SPRITE_X, R13
    mov.w   #SPRITE_Y, R14
    call    #sprite_draw

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; sprite_draw — R12 = tile pointer (8-byte bitmap), R13 = x, R14 = y
;==============================================================================
; Your implementation here.

;==============================================================================
; tile_plus — 8x8 sprite bitmap, one byte per row, bit 7 = leftmost column
;==============================================================================
tile_plus:
    .byte   0x18            ; . . . # # . . .
    .byte   0x18            ; . . . # # . . .
    .byte   0x18            ; . . . # # . . .
    .byte   0xFF            ; # # # # # # # #
    .byte   0xFF            ; # # # # # # # #
    .byte   0x18            ; . . . # # . . .
    .byte   0x18            ; . . . # # . . .
    .byte   0x18            ; . . . # # . . .

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
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
