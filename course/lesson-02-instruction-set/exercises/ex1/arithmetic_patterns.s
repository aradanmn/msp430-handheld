#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR        ; LED1, LED2 as outputs
    bic.b   #(LED1|LED2), &P1OUT        ; both off initially

; -----------------------------------------------------------------------------
; TASK — Arithmetic patterns
;
; Use ADD and a bitmask (AND) to make LED1 and LED2 together display a 2-bit
; binary counter:
;
;   count 0 -> both LEDs off
;   count 1 -> LED1 on,  LED2 off
;   count 2 -> LED1 off, LED2 on
;   count 3 -> LED1 on,  LED2 on
;
; The counter increments once every ~300 ms and wraps from 3 back to 0
; (count = (count + 1) mod 4), running forever.
;
; LED1 is P1.0 and LED2 is P1.6 — these bit positions do not line up with a
; plain 0-3 counter value sitting in a register, so you will need to derive
; how to turn a 0-3 count into the correct P1OUT bit pattern. Look up ADD
; and AND in the MSP430 Instruction Set Summary (the CPU/instruction
; chapters of SLAU144) if their semantics aren't already clear from
; tutorial-01.
; -----------------------------------------------------------------------------


    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0            ; 0xFFE0-0xFFEF  unused
    .word   0,0,0,0, 0,0,0              ; 0xFFF0-0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
