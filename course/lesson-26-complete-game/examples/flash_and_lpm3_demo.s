;******************************************************************************
; flash_and_lpm3_demo.s — Lesson 26 example
;
; Two independent demonstrations in one file:
;
;   1. Reads one byte from Info Flash Segment D (0x1000) at boot — an
;      ordinary memory read, no unlock sequence needed — and reflects it as
;      an LED1 blink count (masked to 1-8 blinks, since blank/erased Flash
;      reads as 0xFF and blinking 255 times would defeat the point of a
;      quick visual check).
;
;   2. Configures ACLK to run from the internal VLO (no crystal on this
;      board), configures Timer_A to run off ACLK (demonstrating that it
;      keeps ticking through LPM3 — its own interrupt is not enabled here,
;      it's just shown running), enters LPM3, and wakes on a press of the
;      onboard S2 button (P1.3), toggling LED1 once per wake.
;
; This example deliberately never erases or writes Flash — see Tutorial 02
; and the lesson README's safety note. Only the milestone implements the
; actual erase/write sequence.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; New this lesson — none of these are in msp430g2553-defs.s.
;==============================================================================
.equ    LFXT1S_3,       0x30        ; BCSCTL3 bits 5-4 = 11 -> ACLK from VLOCLK
                                     ; (SLAU144, Basic Clock System chapter)

.equ    HIGHSCORE_ADDR, 0x1000      ; Info Flash Segment D — read only in this file

.equ    ACLK_HZ,        12000       ; VLO is nominally ~12 kHz (uncalibrated)
.equ    TA_PERIOD_TICKS,(ACLK_HZ - 1)   ; ~1 second, just to give Timer_A something
                                         ; to count while the CPU sleeps in LPM3

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR
    bic.b   #LED1, &P1OUT

    ;--------------------------------------------------------------------
    ; Part 1 — read Info Flash Segment D, reflect it via an LED1 blink
    ; count. Ordinary memory read; no FCTL unlock sequence involved.
    ;--------------------------------------------------------------------
    mov.b   &HIGHSCORE_ADDR, R12
    and.b   #0x07, R12                  ; keep the demo to a quick 1-8 blinks
    inc.w   R12
    call    #blink_count

    ;--------------------------------------------------------------------
    ; Part 2 — ACLK from VLO, Timer_A off ACLK, S2 button as a Port 1
    ; wake source, then sleep in LPM3.
    ;--------------------------------------------------------------------
    bis.b   #LFXT1S_3, &BCSCTL3         ; ACLK <- VLOCLK (no crystal on this board)

    mov.w   #TA_PERIOD_TICKS, &TACCR0
    mov.w   #(TASSEL_1|MC_1|TACLR), &TACTL   ; ACLK, Up mode — just runs; no CCIE/TAIE

    bic.b   #BTN, &P1DIR                ; P1.3 = input
    bis.b   #BTN, &P1REN                ; enable pull resistor
    bis.b   #BTN, &P1OUT                ; pull-UP (button reads 1 when released)
    bis.b   #BTN, &P1IES                ; falling edge = press (active LOW)
    bic.b   #BTN, &P1IFG                ; clear any stale flag before enabling
    bis.b   #BTN, &P1IE                 ; enable Port 1 interrupt on this pin

.Lsleep:
    bis.w   #(LPM3_bits|GIE), SR        ; sleep — CPU+DCO+SMCLK off, ACLK still runs
    jmp     .Lsleep                     ; resumes here after each wake (ISR clears CPUOFF)

;==============================================================================
; port1_isr — wakes the CPU on an S2 button press, toggles LED1 to make the
; wake event observable, then returns to LPM3 via the main loop.
;==============================================================================
port1_isr:
    bic.b   #BTN, &P1IFG                ; acknowledge — clear before returning
    xor.b   #LED1, &P1OUT               ; visible proof this wake happened
    bic.w   #CPUOFF, 0(SP)              ; clear CPUOFF in the saved SR -> wake
    reti

;==============================================================================
; blink_count — blink LED1 the number of times in R12, then return.
; (LED1 assumed already off on entry; left off on return.)
;==============================================================================
blink_count:
.Lblink_loop:
    tst.w   R12
    jz      .Lblink_done
    bis.b   #LED1, &P1OUT
    call    #delay
    bic.b   #LED1, &P1OUT
    call    #delay
    dec.w   R12
    jmp     .Lblink_loop
.Lblink_done:
    ret

;==============================================================================
; delay — plain cycle-counted software delay (boot-time visual check only;
; not part of the tick/LPM3 timing this lesson is actually about).
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
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   port1_isr   ; 0xFFE4  Port 1
    .word   0           ; 0xFFE6  Port 2
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI_A0/B0 TX
    .word   0           ; 0xFFEE  USCI_A0/B0 RX
    .word   0           ; 0xFFF0  Timer_A overflow (TAIV)
    .word   0           ; 0xFFF2  Timer_A CC0
    .word   0           ; 0xFFF4  WDT
    .word   0           ; 0xFFF6  Comparator_A+
    .word   0           ; 0xFFF8  Timer1_A1
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
    .end
