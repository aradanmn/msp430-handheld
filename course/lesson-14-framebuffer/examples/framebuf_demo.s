;******************************************************************************
; Lesson 14 — Example: Board Border + One Block
;
; Draws a rectangular board border (four lines) and one filled 8x8 block
; inside it — the first real game-shaped graphics this course produces.
; Every shape is drawn directly against the OLED via display_set_pixel
; (Lesson 13); see tutorial-01 for why this lesson doesn't buffer the
; screen locally yet.
;
; Hardware: same OLED wiring as Lessons 12-13.
;
; Success: a rectangular outline visible on screen, with one filled square
; sitting inside it, not touching the border.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    OLED_CS,   BIT0
.equ    OLED_DC,   BIT1
.equ    OLED_RST,  BIT2

.equ    BOARD_X0,  20
.equ    BOARD_Y0,  4
.equ    BOARD_X1,  107
.equ    BOARD_Y1,  59

.equ    BLOCK_X0,  30
.equ    BLOCK_Y0,  14
.equ    BLOCK_X1,  37
.equ    BLOCK_Y1,  21

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #spi_init
    call    #display_init
    call    #display_clear

    ; --- board border: four lines ---
    mov.w   #BOARD_X0, R12
    mov.w   #BOARD_X1, R13
    mov.w   #BOARD_Y0, R14
    call    #framebuf_hline              ; top edge

    mov.w   #BOARD_X0, R12
    mov.w   #BOARD_X1, R13
    mov.w   #BOARD_Y1, R14
    call    #framebuf_hline              ; bottom edge

    mov.w   #BOARD_X0, R12
    mov.w   #BOARD_Y0, R13
    mov.w   #BOARD_Y1, R14
    call    #framebuf_vline              ; left edge

    mov.w   #BOARD_X1, R12
    mov.w   #BOARD_Y0, R13
    mov.w   #BOARD_Y1, R14
    call    #framebuf_vline              ; right edge

    ; --- one filled block, inside the border ---
    mov.w   #BLOCK_X0, R12
    mov.w   #BLOCK_Y0, R13
    mov.w   #BLOCK_X1, R14
    mov.w   #BLOCK_Y1, R15
    call    #framebuf_fill_rect

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; spi_init / spi_tx_byte  (Lesson 12)
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
; display_init / display_clear / display_set_pixel  (Lesson 13)
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
; framebuf_fill_rect — filled rectangle; R12=x0, R13=y0, R14=x1, R15=y1
; (inclusive corners, x0<=x1, y0<=y1)
;==============================================================================
framebuf_fill_rect:
    push    R7
    push    R8
    push    R9
    push    R10
    push    R11

    mov.w   R12, R8          ; R8 = x0 (reload value for each row)
    mov.w   R14, R9          ; R9 = width = x1 - x0 + 1
    sub.w   R8, R9
    inc.w   R9

    mov.w   R13, R10         ; R10 = y, starts at y0
    mov.w   R15, R11         ; R11 = height = y1 - y0 + 1
    sub.w   R13, R11
    inc.w   R11

.Lrow_loop:
    cmp.w   #0, R11
    jz      .Lrow_done
    mov.w   R9, R7           ; R7 = column counter, reset each row
    mov.w   R8, R12          ; R12 = x, starts at x0 for this row
.Lcol_loop:
    cmp.w   #0, R7
    jz      .Lcol_done
    mov.w   R10, R13         ; R13 = y (this row)
    call    #display_set_pixel
    inc.w   R12
    dec.w   R7
    jmp     .Lcol_loop
.Lcol_done:
    inc.w   R10              ; next row
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
; framebuf_hline — R12=x0, R13=x1, R14=y
;==============================================================================
framebuf_hline:
    mov.w   R14, R15         ; R15 = y1 = y
    mov.w   R13, R14         ; R14 = x1
    mov.w   R15, R13         ; R13 = y0 = y
    call    #framebuf_fill_rect
    ret

;==============================================================================
; framebuf_vline — R12=x, R13=y0, R14=y1
;==============================================================================
framebuf_vline:
    mov.w   R14, R15         ; R15 = y1
    mov.w   R12, R14         ; R14 = x1 = x
    call    #framebuf_fill_rect
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
