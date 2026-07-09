;******************************************************************************
; auto-wake-design.s — Lesson 11 Exercise 2 (Challenge)
;
; Constraint: the CPU should spend nearly all of its time asleep in LPM0.
; Real work — toggling LED2 — only needs to happen once every 2 seconds.
; LED1 is a "CPU busy" indicator for grading purposes: it should remain OFF
; during normal operation.
;
; Build it, flash it, and watch both LEDs for at least 10 seconds. See
; exercises/README.md for what you should be checking against.
;******************************************************************************

#include "../../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants
;==============================================================================
.equ    SMCLK_HZ,             1000000
.equ    HEARTBEAT_HZ_APPROX,  60
.equ    TICK_PERIOD_CYCLES,   ((SMCLK_HZ + (HEARTBEAT_HZ_APPROX / 2)) / HEARTBEAT_HZ_APPROX)
.equ    TACCR0_HEARTBEAT,     (TICK_PERIOD_CYCLES - 1)

.equ    TICKS_PER_2SEC,       (HEARTBEAT_HZ_APPROX * 2)      ; = 120

    .text
    .global _start

_start:
    mov.w   #0x0400, SP
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR
    bic.b   #(LED1|LED2), &P1OUT

    mov.w   #TICKS_PER_2SEC, R4         ; tick countdown to next LED2 update

    mov.w   #TACCR0_HEARTBEAT, &TACCR0
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL
    mov.w   #CCIE, &TACCTL0

.Lmain:
    bis.w   #(GIE|CPUOFF), SR           ; sleep until the ISR wakes us
    xor.b   #LED1, &P1OUT               ; "busy" indicator — should only run
                                         ; when there's real work pending
    jmp     .Lmain

;==============================================================================
; cc0_isr — fires ~60 times/second on Timer_A CC0 compare match
;==============================================================================
cc0_isr:
    dec.w   R4
    jnz     .Lno_update
    mov.w   #TICKS_PER_2SEC, R4
    xor.b   #LED2, &P1OUT               ; the real work — every 2 seconds
.Lno_update:
    bic.w   #CPUOFF, 0(SP)              ; wake the main loop after every tick
    reti

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0           ; 0xFFE0  unused
    .word   0           ; 0xFFE2  unused
    .word   0           ; 0xFFE4  Port 1
    .word   0           ; 0xFFE6  Port 2
    .word   0           ; 0xFFE8  unused
    .word   0           ; 0xFFEA  ADC10
    .word   0           ; 0xFFEC  USCI_A0/B0 TX
    .word   0           ; 0xFFEE  USCI_A0/B0 RX
    .word   0           ; 0xFFF0  Timer_A overflow (TAIV)
    .word   cc0_isr     ; 0xFFF2  Timer_A CC0
    .word   0           ; 0xFFF4  WDT
    .word   0           ; 0xFFF6  Comparator_A+
    .word   0           ; 0xFFF8  Timer1_A1
    .word   0           ; 0xFFFA  unused
    .word   0           ; 0xFFFC  unused
    .word   _start      ; 0xFFFE  Reset
    .end
