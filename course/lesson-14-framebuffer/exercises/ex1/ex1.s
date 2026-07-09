;******************************************************************************
; Lesson 14 — Exercise 1: Pixel/Line to Byte Array
;
; page_buf represents one OLED page: 128 columns, each byte holding 8
; vertically-stacked pixels (bit 0 = top row of the page, per Lesson 13's
; addressing tutorial). Without touching the display or SPI at all, compute
; which byte and which bit within that byte corresponds to a given
; (x, y-within-page) coordinate, and use that math to draw a horizontal
; line into page_buf: every column from LINE_X0 to LINE_X1 inclusive, at
; row LINE_Y (0-7 within the page).
;
; This is the same addressing math display_set_pixel does before it ever
; touches SPI (Lesson 13) — here you're checking it against known values
; in RAM instead of against a screen.
;
; A self-check (provided below) compares your finished page_buf against
; expected_buf and lights LED1 if every byte matches.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

.equ LINE_X0, 40
.equ LINE_X1, 87
.equ LINE_Y,  3          ; row within the page, 0-7

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ; 1. Zero all 128 bytes of page_buf.
    ; 2. Compute the bit mask for row LINE_Y within a page byte.
    ; 3. For every column from LINE_X0 to LINE_X1 inclusive, OR that mask
    ;    into page_buf[column].

    ; --- self-check: do not modify below this line ---
    mov.w   #page_buf, R14
    mov.w   #expected_buf, R15
    mov.w   #128, R13
.Lcheck_loop:
    mov.b   @R14, R12
    cmp.b   @R15, R12
    jnz     .Lfail
    inc.w   R14
    inc.w   R15
    dec.w   R13
    jnz     .Lcheck_loop
    bis.b   #LED1, &P1OUT
    jmp     .Lhalt
.Lfail:
    bic.b   #LED1, &P1OUT
.Lhalt:
    jmp     .Lhalt

    .bss
page_buf:
    .skip   128

    .text
expected_buf:
    .fill   40, 1, 0x00      ; columns 0-39: no line here
    .fill   48, 1, 0x08      ; columns 40-87: bit 3 set (LINE_Y = 3 -> 1<<3 = 0x08)
    .fill   40, 1, 0x00      ; columns 88-127: no line here

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
