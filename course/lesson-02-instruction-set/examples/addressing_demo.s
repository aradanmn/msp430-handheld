#include "../../common/msp430g2553-defs.s"

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

;==============================================================================
; main_loop
; How it works: walks pattern_table with R5 using indirect-autoincrement
;   addressing (@R5+), writing each entry straight to P1OUT. When R5 runs
;   off the end of the table, it is reset to the table's base address
;   (a single symbolic reference) and the sequence repeats forever.
;==============================================================================
main_loop:
    mov.w   #pattern_table, R5          ; R5 = pointer to table base (symbolic)

.Lwalk:
    mov.b   @R5+, R12                   ; R12 = *R5; R5 advances by 1 byte
    mov.b   R12, &P1OUT                 ; display this pattern
    mov.w   #300, R12                   ; ~300 ms between steps
    call    #.Ldelay_ms
    cmp.w   #pattern_table_end, R5      ; ran off the end of the table?
    jne     .Lwalk
    jmp     main_loop                   ; wrap: reload R5 from table base

;==============================================================================
; delay_ms
; How it works: at 1 MHz, 1 ms = 1000 cycles.
;   Inner loop: dec (1 cycle) + jnz (2 cycles) = 3 cycles per iteration
;   333 iterations x 3 cycles = 999 cycles ~= 1 ms
;==============================================================================
.Ldelay_ms:
    mov.w   #333, R13                   ; 333 iterations
.Ltms_loop:
    dec.w   R13                         ; one cycle
    jnz     .Ltms_loop                  ; two cycles
    dec.w   R12                         ; 1 ms elapsed
    jnz     .Ldelay_ms                  ; start another 1 ms pass
    ret                                 ; done, return to caller

;==============================================================================
; pattern_table
; 4 LED bit-patterns walked in order: off, LED1, LED2, both.
;==============================================================================
pattern_table:
    .byte   0x00                        ; both off
    .byte   LED1                        ; LED1 only
    .byte   LED2                        ; LED2 only
    .byte   (LED1|LED2)                 ; both on
pattern_table_end:

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0            ; 0xFFE0-0xFFEF  unused
    .word   0,0,0,0, 0,0,0              ; 0xFFF0-0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
