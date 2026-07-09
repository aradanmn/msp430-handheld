#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; reusable_routines.s
;
; Blinks LED1 at ~2 Hz using only two reusable subroutines:
;   led_set(R12=mask, R13=on/off)  — drive an LED mask on or off
;   delay_ms(R12=ms)               — busy-wait for approximately ms milliseconds
;
; Neither routine knows anything about "blinking" — the main loop composes
; that behavior purely by calling them in sequence.
;==============================================================================

.equ    BLINK_MS,   250     ; on/off half-period → 250+250 = 500 ms period ≈ 2 Hz

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; LED1 as output
    bic.b   #LED1, &P1OUT               ; start OFF

main_loop:
    mov.b   #LED1, R12
    mov.w   #1, R13
    call    #led_set                    ; LED1 on
    mov.w   #BLINK_MS, R12
    call    #delay_ms

    mov.b   #LED1, R12
    mov.w   #0, R13
    call    #led_set                    ; LED1 off
    mov.w   #BLINK_MS, R12
    call    #delay_ms

    jmp     main_loop

;==============================================================================
; led_set
; Args:
;   R12 = LED bitmask (bits to affect in P1OUT)
;   R13 = on/off flag — nonzero = turn masked bits ON, zero = turn them OFF
; Uses only R12–R15 as scratch — no R4–R11 borrowed, so nothing to save.
;==============================================================================
led_set:
    cmp.w   #0, R13
    jz      .Lled_off
    bis.b   R12, &P1OUT     ; turn masked bit(s) ON
    ret
.Lled_off:
    bic.b   R12, &P1OUT     ; turn masked bit(s) OFF
    ret

;==============================================================================
; delay_ms
; Arg: R12 = milliseconds to wait
; How it works: at 1 MHz, 1 ms = 1000 cycles.
;   Inner loop: dec (1 cycle) + jnz (2 cycles) = 3 cycles per iteration
;   333 iterations × 3 cycles = 999 cycles ≈ 1 ms
;==============================================================================
delay_ms:
    mov.w   #333, R13      ; 333 iterations ≈ 1 ms (R13 is scratch here, not
.Ldelay_inner:              ;  the same "argument" role it plays in led_set)
    dec.w   R13
    jnz     .Ldelay_inner
    dec.w   R12
    jnz     delay_ms
    ret

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
