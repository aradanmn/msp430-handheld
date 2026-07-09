#include "../../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

;==============================================================================
; Tick / debounce timing constants
;==============================================================================
.equ    TICK_MS,            5      ; one tick = 5 ms of calibrated delay
.equ    DEBOUNCE_THRESHOLD, 40     ; consecutive disagreeing ticks to accept
                                    ; a new debounced state

;==============================================================================
; setup
;==============================================================================
    bis.b   #LED1, &P1DIR       ; LED1 output
    bic.b   #LED1, &P1OUT       ; LED1 off

    bic.b   #BTN, &P1DIR        ; BTN input
    bis.b   #BTN, &P1REN        ; enable pull resistor
    bis.b   #BTN, &P1OUT        ; pull-UP (reads 1 when released)

    ; R8  = accepted debounced state (raw, active-low): 0=pressed, BTN=released
    ; R9  = mismatch counter (consecutive ticks disagreeing with R8)
    ; R11 = previous tick's accepted state (for press-edge detection)
    mov.b   #BTN, R8            ; start "released" — matches the pull-up
    mov.b   #BTN, R11
    clr.w   R9

;==============================================================================
; main_loop
; How it works: once per tick, run the stable-count debounce state machine,
;   then check whether the accepted state just became a fresh press and
;   toggle LED1 if so.
;==============================================================================
main_loop:
    mov.b   R8, R11              ; remember this tick's accepted state as
                                  ; "previous" before it can change below

    mov.w   #TICK_MS, R12
    call    #.Ltick_delay         ; wait one tick period

    mov.b   &P1IN, R12
    and.b   #BTN, R12             ; isolate BTN bit: 0=pressed, BTN=released

    cmp.b   R12, R8
    jeq     .Lstable

    inc.w   R9                    ; raw sample disagrees with accepted state
    cmp.w   #DEBOUNCE_THRESHOLD, R9
    jlo     .Lcheck_edge          ; not enough consecutive disagreement yet

    mov.b   R12, R8               ; threshold reached — accept the new state
    clr.w   R9
    jmp     .Lcheck_edge

.Lstable:
    clr.w   R9                    ; sample agrees with accepted state —
                                   ; reset the run of disagreement to zero

.Lcheck_edge:
    cmp.b   #0, R8
    jne     .Lno_edge             ; accepted state isn't "pressed" — no
                                   ; press edge is possible this tick
    cmp.b   #0, R11
    jeq     .Lno_edge             ; was already pressed last tick — not new
    xor.b   #LED1, &P1OUT         ; fresh press edge — toggle LED1

.Lno_edge:
    jmp     main_loop

;==============================================================================
; tick_delay
; How it works: at 1 MHz, 1 ms = 1000 cycles (same idiom as hal/leds.s's
;   delay_ms). Inner loop: dec (1 cycle) + jnz (2 cycles) = 3 cycles/iter,
;   333 iterations ≈ 1 ms. Caller loads the tick length in ms into R12.
;==============================================================================
.Ltick_delay:
    mov.w   #333, R13
.Ltd_loop:
    dec.w   R13
    jnz     .Ltd_loop
    dec.w   R12
    jnz     .Ltick_delay
    ret

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
