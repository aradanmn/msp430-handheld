#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

; -----------------------------------------------------------------------------
; TASK — Addressing-mode puzzle
;
; Store a sequence of at least 5 distinct LED bit-patterns (using LED1 and
; LED2) as a table in Flash. Traverse the table and display each pattern on
; P1OUT in a loop that repeats forever, reaching each table entry using
; ONLY indexed or indirect addressing through a single pointer register.
;
; Constraints:
;   - No more than ONE instruction referencing &P1OUT may execute per
;     pattern-step.
;   - Your entire program may contain no more than ONE absolute/symbolic
;     reference to the table's base address — every other access to a table
;     entry must be computed from a register, not written as a fresh
;     absolute address.
;   - The sequence must cycle through all 5+ patterns, in a fixed order,
;     forever.
;
; Success criteria: watch the LEDs cycle through 5 or more distinct states
; indefinitely. Confirm by reading your own source that a single pointer
; register — not per-step hardcoded addresses — is what selects each table
; entry.
; -----------------------------------------------------------------------------


    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0            ; 0xFFE0-0xFFEF  unused
    .word   0,0,0,0, 0,0,0              ; 0xFFF0-0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
