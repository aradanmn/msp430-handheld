#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; stack_corruption_bug.s
;
; Intended behavior: flash_pattern(R12=count, R13=mask) flashes the given
; LED mask `count` times (150 ms on / 150 ms off each), then returns to its
; caller. main_loop calls flash_pattern with LED1 and a fixed flash count,
; forever, so LED1 should flash in repeating groups indefinitely.
;==============================================================================

.equ    FLASH_MS,       150     ; on/off duration per flash, in ms
.equ    FLASH_COUNT,    4       ; flashes per call to flash_pattern

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; LED1 as output
    bic.b   #LED1, &P1OUT               ; start OFF

main_loop:
    mov.w   #FLASH_COUNT, R12           ; arg: how many times to flash
    mov.b   #LED1, R13                  ; arg: which LED(s)
    call    #flash_pattern
    jmp     main_loop

;==============================================================================
; flash_pattern
; Args:
;   R12 = number of flashes to perform
;   R13 = LED bitmask to flash
; Flashes the given mask on/off FLASH_MS times, `count` times, then returns.
; Borrows R8 (flash counter) and R9 (LED mask) across the loop, since both
; must survive the nested calls to led_set/delay_ms.
;==============================================================================
flash_pattern:
    push    R8              ; preserve caller's R8 (flash counter is ours)
    push    R9              ; preserve caller's R9 (LED mask is ours)
    mov.w   R12, R8          ; R8 = number of flashes (from argument)
    mov.b   R13, R9          ; R9 = LED mask (from argument)

    push    R9              ; keep the mask safe while the loop runs
.Lflash_loop:
    mov.b   R9, R12
    mov.w   #1, R13
    call    #led_set         ; LED(s) on
    mov.w   #FLASH_MS, R12
    call    #delay_ms

    mov.b   R9, R12
    mov.w   #0, R13
    call    #led_set         ; LED(s) off
    mov.w   #FLASH_MS, R12
    call    #delay_ms

    dec.w   R8
    jnz     .Lflash_loop

    pop     R9               ; restore caller's R9
    pop     R8               ; restore caller's R8
    ret

;==============================================================================
; led_set
; Args: R12 = LED bitmask, R13 = on/off flag (nonzero = on, zero = off)
;==============================================================================
led_set:
    cmp.w   #0, R13
    jz      .Lled_off
    bis.b   R12, &P1OUT
    ret
.Lled_off:
    bic.b   R12, &P1OUT
    ret

;==============================================================================
; delay_ms
; Arg: R12 = milliseconds to wait
;   Inner loop: dec (1 cycle) + jnz (2 cycles) = 3 cycles per iteration
;   333 iterations × 3 cycles ≈ 1 ms at 1 MHz
;==============================================================================
delay_ms:
    mov.w   #333, R13
.Ldelay_inner:
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
