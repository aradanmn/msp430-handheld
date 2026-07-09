;******************************************************************************
; Lesson 15 — Exercise 2: Move Without Artifacts
;
; Steps a sprite rightward across the screen, pausing briefly between each
; step so the motion is visible. Build it, flash it, and watch the OLED.
;
; See exercises/README.md for the problem statement.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ    OLED_CS,   BIT0
.equ    OLED_DC,   BIT1
.equ    OLED_RST,  BIT2

.equ    SPRITE_Y,  28
.equ    START_X,   10
.equ    MAX_X,     100
.equ    STEP,      3

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    call    #spi_init
    call    #display_init
    call    #display_clear

    mov.w   #START_X, R8         ; R8 = current on-screen x position

    mov.w   #tile_plus, R12
    mov.w   R8, R13
    mov.w   #SPRITE_Y, R14
    call    #sprite_draw          ; draw the sprite at its starting position

.Lmove_loop:
    call    #move_delay

    mov.w   R8, R9                ; R9 = old position (before this step)
    add.w   #STEP, R8             ; R8 = new position

    mov.w   #tile_plus, R12       ; draw at the new position...
    mov.w   R8, R13
    mov.w   #SPRITE_Y, R14
    call    #sprite_draw

    mov.w   R9, R12               ; ...then erase the old position
    mov.w   #SPRITE_Y, R13
    call    #sprite_erase

    cmp.w   #MAX_X, R8
    jl      .Lmove_loop

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; move_delay — a visible pause between steps (~100 ms at 1 MHz)
;==============================================================================
move_delay:
    push    R14
    push    R15
    mov.w   #50, R14
.Lmd_outer:
    mov.w   #2000, R15
.Lmd_inner:
    dec.w   R15
    jnz     .Lmd_inner
    dec.w   R14
    jnz     .Lmd_outer
    pop     R15
    pop     R14
    ret

;==============================================================================
; tile_plus — 8x8 sprite bitmap
;==============================================================================
tile_plus:
    .byte   0x18, 0x18, 0x18, 0xFF, 0xFF, 0x18, 0x18, 0x18

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
.Lsd_loop:
    dec.w   R15
    jnz     .Lsd_loop
    pop     R15
    ret

;==============================================================================
; display_init / display_clear / display_set_pixel / display_clear_pixel
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

display_clear_pixel:
    push    R9
    push    R10
    push    R11

    mov.w   R12, R11
    mov.w   R13, R10
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

    mov.b   #0x00, R12
    call    #oled_data

    pop     R11
    pop     R10
    pop     R9
    ret

pixel_bit_table:
    .byte   0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80

;==============================================================================
; sprite_draw — R12 = tile pointer, R13 = x, R14 = y
;==============================================================================
sprite_draw:
    push    R5
    push    R6
    push    R7
    push    R8
    push    R9
    push    R10
    push    R11

    mov.w   R12, R11
    mov.w   R13, R8
    mov.w   R14, R9
    mov.w   #8, R10

.Lrow_loop:
    cmp.w   #0, R10
    jz      .Lrow_done
    mov.b   @R11, R7
    mov.w   #8, R6
    mov.w   R8, R5
.Lcol_loop:
    cmp.w   #0, R6
    jz      .Lcol_done
    rla.b   R7
    jnc     .Lskip_pixel
    mov.w   R5, R12
    mov.w   R9, R13
    call    #display_set_pixel
.Lskip_pixel:
    inc.w   R5
    dec.w   R6
    jmp     .Lcol_loop
.Lcol_done:
    inc.w   R11
    inc.w   R9
    dec.w   R10
    jmp     .Lrow_loop
.Lrow_done:

    pop     R11
    pop     R10
    pop     R9
    pop     R8
    pop     R7
    pop     R6
    pop     R5
    ret

;==============================================================================
; sprite_erase — R12 = x, R13 = y — clears the full 8x8 tile footprint at
; (x, y), regardless of any bitmap's content.
;==============================================================================
sprite_erase:
    push    R8
    push    R9
    push    R10
    push    R11

    mov.w   R12, R8            ; R8 = base x
    mov.w   R13, R9            ; R9 = y, current row
    mov.w   #8, R10            ; R10 = row counter

.Ler_row_loop:
    cmp.w   #0, R10
    jz      .Ler_row_done
    mov.w   #8, R11            ; R11 = column counter
    mov.w   R8, R12            ; R12 = x, reset to base_x for this row
.Ler_col_loop:
    cmp.w   #0, R11
    jz      .Ler_col_done
    push    R12
    mov.w   R9, R13
    call    #display_clear_pixel
    pop     R12
    inc.w   R12
    dec.w   R11
    jmp     .Ler_col_loop
.Ler_col_done:
    inc.w   R9
    dec.w   R10
    jmp     .Ler_row_loop
.Ler_row_done:

    pop     R11
    pop     R10
    pop     R9
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
