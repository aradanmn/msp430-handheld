;******************************************************************************
; lpm0-heartbeat.s — Lesson 11 example
;
; The reference low-power pattern used for the rest of this course: a
; ~60 Hz Timer_A CC0 tick decrements a countdown register (R4, per
; handheld/registers.md's "frame/tick counter" role) and toggles LED1 once
; every 0.5 s (1 Hz blink). The CPU sleeps in LPM0 between ticks; the ISR
; exits via plain `reti`, so the saved SR (with CPUOFF still set) puts the
; CPU right back to sleep automatically — Pattern A from Tutorial 11.1.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; Timing constants
;==============================================================================
.equ    SMCLK_HZ,            1000000
.equ    HEARTBEAT_HZ_APPROX, 60                 ; 60 Hz doesn't divide 1 MHz evenly
.equ    TICK_PERIOD_CYCLES,  ((SMCLK_HZ + (HEARTBEAT_HZ_APPROX / 2)) / HEARTBEAT_HZ_APPROX)
                                                 ; rounded to nearest cycle = 16,667
                                                 ; → actual rate ≈ 59.988 Hz
.equ    TACCR0_HEARTBEAT,    (TICK_PERIOD_CYCLES - 1)      ; = 16,666

.equ    TICKS_PER_HALF_SEC,  (HEARTBEAT_HZ_APPROX / 2)     ; = 30

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; P1.0 = output
    bic.b   #LED1, &P1OUT               ; start with LED1 off

    mov.w   #TICKS_PER_HALF_SEC, R4     ; R4 = tick countdown (registers.md role)

    mov.w   #TACCR0_HEARTBEAT, &TACCR0
    mov.w   #(TASSEL_2|MC_1|TACLR), &TACTL   ; SMCLK, no divider, Up mode
    mov.w   #CCIE, &TACCTL0             ; enable the CC0 compare interrupt

    bis.w   #(GIE|CPUOFF), SR           ; enter LPM0 — CPU sleeps here between ticks

.Lunreachable:
    jmp     .Lunreachable               ; never reached — the ISR always reti's
                                         ; straight back into LPM0 (Pattern A)

;==============================================================================
; cc0_isr — fires ~60 times/second on Timer_A CC0 compare match
;==============================================================================
cc0_isr:
    dec.w   R4                          ; one tick elapsed
    jnz     .Lnot_yet
    mov.w   #TICKS_PER_HALF_SEC, R4     ; reload the countdown
    xor.b   #LED1, &P1OUT               ; the slow, visible action (1 Hz blink)
.Lnot_yet:
    reti                                 ; restores the sleeping SR — CPU goes
                                         ; right back into LPM0

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
