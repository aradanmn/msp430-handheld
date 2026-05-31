;******************************************************************************
; Lesson 03 — Exercise 2: Design a Debounce
;
; Fix the unreliable toggle from Exercise 1.
; LED1 must toggle exactly once per physical press. Every time.
;
; The tutorial explains what button bounce is. Your job:
;   - Choose a debounce strategy (delay+re-read, two-sample, counter-based)
;   - Implement it
;   - Add LED2 flash (80 ms) after each confirmed press
;
; Define all timing as .equ constants — no magic numbers.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

; Your timing constants here
	.equ	DBNC,	20
	.equ	FLSH,	80

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    ; Your GPIO setup here (LEDs + button)
	; LED setup
	bis.b   #(LED1|LED2), &P1DIR
	bic.b   #(LED1|LED2), &P1OUT
	; setup BTN
	bic.b   #BTN, &P1DIR        ; input
	bis.b   #BTN, &P1REN        ; enable resistor
	bis.b   #BTN, &P1OUT        ; pull-up (HIGH when released, LOW when pressed)
    ; Your debounced toggle loop here
main:
	call 	#btn_press

	xor.b	#LED1, &P1OUT			; toggle LED once
	call 	#flash_grn
	call	#btn_release

	;xor.b	#LED1, &P1OUT
;==============================================================================
; flash_grn Flashes the GREEN LED
;==============================================================================
flash_grn:
	xor.b	#LED2, &P1OUT
	mov.w 	#FLSH, R12
	call	#delay_ms
	xor.b	#LED2, &P1OUT
	ret
;==============================================================================
; btn_press
;==============================================================================
btn_press:
.Lwait_press:
	bit.b	#BTN, &P1IN
	jnz		.Lwait_press				; released -> wait
	; --- button just pressed ---	
	mov.w	#DBNC, R12
	call 	#delay_ms
	; --- confirmed btn pressed ---
	bit.b	#BTN, &P1IN
	jnz		.Lwait_press				; released -> wait

	ret
;==============================================================================
; btn_release
;==============================================================================
btn_release:
.Lwait_release:
	bit.b	#BTN, &P1IN
	jz		.Lwait_release			; still pressed -> wait
	; --- btn released ---
	mov.w	#DBNC, R12
	call 	#delay_ms
	; --- confirmed button released -> ready for next press
	bit.b	#BTN, &P1IN
	jz		.Lwait_release			; still pressed -> wait
	ret
;==============================================================================
; delay_ms — from Lesson 01
;==============================================================================
delay_ms:
    mov.w   #333, R13
.Ldms_inner:
    dec.w   R13
    jnz     .Ldms_inner
    dec.w   R12
    jnz     delay_ms
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0
    .word   0,0,0,0, 0,0,0
    .word   _start
    .end
