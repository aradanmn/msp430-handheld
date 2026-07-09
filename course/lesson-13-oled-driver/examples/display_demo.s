;******************************************************************************
; Lesson 13 — Example: OLED Init, Clear, and a Single Pixel
;
; Brings up an SSD1306-family SPI OLED (see tutorial-01: exact command bytes
; are the widely-published SSD1306 reference sequence — verify against your
; own controller's datasheet), clears the screen, then lights exactly one
; pixel at (10, 10).
;
; Hardware: OLED SCLK->P1.5, MOSI->P1.7, CS->P2.0, DC->P2.1, RST->P2.2, 3.3V.
; Remove any P1.7->P1.6 loopback jumper left over from Lesson 12.
;
; Success: the screen is entirely blank except for one single lit pixel,
; ten pixels down and ten pixels right from the top-left corner.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

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
    call    #display_init
    call    #display_clear

    mov.w   #10, R12            ; x = 10
    mov.w   #10, R13            ; y = 10
    call    #display_set_pixel

    mov.w   #10, R12            ; light a second pixel a couple rows down...
    mov.w   #12, R13
    call    #display_set_pixel
    mov.w   #10, R12            ; ...then clear it again, to exercise both halves
    mov.w   #12, R13            ; of the set/clear pair. Only (10,10) stays lit.
    call    #display_clear_pixel

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
; oled_cmd — send byte in R12 as a command (DC low, one CS-low transaction)
;==============================================================================
oled_cmd:
    bic.b   #OLED_CS, &P2OUT
    bic.b   #OLED_DC, &P2OUT
    call    #spi_tx_byte
    bis.b   #OLED_CS, &P2OUT
    ret

;==============================================================================
; oled_data — send byte in R12 as data (DC high, one CS-low transaction)
;==============================================================================
oled_data:
    bic.b   #OLED_CS, &P2OUT
    bis.b   #OLED_DC, &P2OUT
    call    #spi_tx_byte
    bis.b   #OLED_CS, &P2OUT
    ret

;==============================================================================
; short_delay — busy-wait long enough for the RST pulse (~a few ms at 1 MHz)
;==============================================================================
short_delay:
    push    R15
    mov.w   #2000, R15
.Ldelay_loop:
    dec.w   R15
    jnz     .Ldelay_loop
    pop     R15
    ret

;==============================================================================
; display_init — hardware reset, then the SSD1306-family init command list
;==============================================================================
display_init:
    bis.b   #(OLED_CS|OLED_DC|OLED_RST), &P2DIR
    bis.b   #OLED_CS, &P2OUT            ; CS idle high

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
    .byte   0xAE                ; display off
    .byte   0xD5, 0x80          ; clock divide ratio / oscillator frequency
    .byte   0xA8, 0x3F          ; multiplex ratio (64 rows - verify for your panel)
    .byte   0xD3, 0x00          ; display offset
    .byte   0x40                ; display start line = 0
    .byte   0x8D, 0x14          ; enable charge pump
    .byte   0x20, 0x00          ; memory addressing mode: horizontal
    .byte   0xA1                ; segment remap
    .byte   0xC8                ; COM output scan direction, remapped
    .byte   0xDA, 0x12          ; COM pins hardware configuration
    .byte   0x81, 0xCF          ; contrast control
    .byte   0xD9, 0xF1          ; pre-charge period
    .byte   0xDB, 0x40          ; VCOMH deselect level
    .byte   0xA4                ; resume display from GDDRAM contents
    .byte   0xA6                ; normal (not inverted) display
    .byte   0xAF                ; display on
init_cmds_end:

;==============================================================================
; display_clear — write 0x00 to every byte of GDDRAM (128 columns x 8 pages)
;==============================================================================
display_clear:
    push    R11

    mov.b   #0x21, R12          ; set column address window
    call    #oled_cmd
    mov.b   #0x00, R12
    call    #oled_cmd
    mov.b   #0x7F, R12
    call    #oled_cmd

    mov.b   #0x22, R12          ; set page address window
    call    #oled_cmd
    mov.b   #0x00, R12
    call    #oled_cmd
    mov.b   #0x07, R12
    call    #oled_cmd

    mov.w   #(128*8), R11       ; total GDDRAM bytes
.Lclear_loop:
    mov.b   #0x00, R12
    call    #oled_data
    dec.w   R11
    jnz     .Lclear_loop

    pop     R11
    ret

;==============================================================================
; display_set_pixel — light pixel (x, y); x in R12, y in R13
;
; Computes page = y >> 3, bit = y & 7, sets a 1-column/1-page address
; window at (page, x), then writes one data byte with only that bit set.
; This blindly overwrites the whole GDDRAM byte at that (page, x) — fine
; here because display_clear already zeroed everything else in it. See
; tutorial-02 for why that stops being safe once neighbors matter (Lesson 14).
;==============================================================================
display_set_pixel:
    push    R9
    push    R10
    push    R11

    mov.w   R12, R11             ; R11 = x, saved across oled_cmd calls
    mov.w   R13, R10             ; R10 = y, saved
    and.w   #0x07, R13           ; R13 = bit index (0-7)
    mov.w   R10, R9
    rra.w   R9
    rra.w   R9
    rra.w   R9                   ; R9 = page = y >> 3

    mov.b   #0x21, R12          ; set column address window = [x, x]
    call    #oled_cmd
    mov.b   R11, R12
    call    #oled_cmd
    mov.b   R11, R12
    call    #oled_cmd

    mov.b   #0x22, R12          ; set page address window = [page, page]
    call    #oled_cmd
    mov.b   R9, R12
    call    #oled_cmd
    mov.b   R9, R12
    call    #oled_cmd

    mov.w   R13, R9              ; R9 = bit index again
    mov.b   pixel_bit_table(R9), R12
    call    #oled_data

    pop     R11
    pop     R10
    pop     R9
    ret

;==============================================================================
; display_clear_pixel — turn off pixel (x, y); x in R12, y in R13
;
; Mirror image of display_set_pixel: identical addressing, but the data
; byte written is 0x00 instead of the one-bit mask. Same blind-write
; caveat applies — this clobbers the other 7 pixels in that GDDRAM byte.
;==============================================================================
display_clear_pixel:
    push    R9
    push    R10
    push    R11

    mov.w   R12, R11
    mov.w   R13, R10
    mov.w   R10, R9
    rra.w   R9
    rra.w   R9
    rra.w   R9                   ; R9 = page = y >> 3

    mov.b   #0x21, R12          ; set column address window = [x, x]
    call    #oled_cmd
    mov.b   R11, R12
    call    #oled_cmd
    mov.b   R11, R12
    call    #oled_cmd

    mov.b   #0x22, R12          ; set page address window = [page, page]
    call    #oled_cmd
    mov.b   R9, R12
    call    #oled_cmd
    mov.b   R9, R12
    call    #oled_cmd

    mov.b   #0x00, R12          ; data byte: every bit clear
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
