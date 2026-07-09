#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; led_patterns.s
;
; Cycles LED1/LED2 through three named game-state patterns, forever:
;
;   attract    - both LEDs off, blinking together slowly   (idle screen)
;   ready      - LED1 solid on, LED2 off                   (player, go)
;   game_over  - both LEDs flashing together fast          (round over)
;
; Demonstrates the safe bit idioms from tutorial-01 (BIS/BIC/XOR with a
; precise mask - never a bare mov.b to P1OUT) and the "each pattern is one
; small subroutine with its own hold time" structure from tutorial-02.
;==============================================================================

.equ    ATTRACT_BLINKS,     3      ; on/off blink pairs in attract mode
.equ    ATTRACT_MS,         400    ; ms per on or off phase in attract mode
.equ    READY_MS,           1500   ; ms LED1 stays solid in ready mode
.equ    GAMEOVER_FLASHES,   6      ; on/off flash pairs in game-over mode
.equ    GAMEOVER_MS,        100    ; ms per on or off phase in game-over mode

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR       ; both LEDs = output
    bic.b   #(LED1|LED2), &P1OUT       ; both LEDs start OFF

main_loop:
    call    #pattern_attract
    call    #pattern_ready
    call    #pattern_gameover
    jmp     main_loop

;==============================================================================
; pattern_attract
; How it works: both LEDs toggle on/off together, ATTRACT_BLINKS times,
;   at a slow rate. Ends with both LEDs OFF.
;==============================================================================
pattern_attract:
    mov.w   #ATTRACT_BLINKS, R10
.Lattract_loop:
    bis.b   #(LED1|LED2), &P1OUT       ; both ON
    mov.w   #ATTRACT_MS, R12
    call    #delay_ms
    bic.b   #(LED1|LED2), &P1OUT       ; both OFF
    mov.w   #ATTRACT_MS, R12
    call    #delay_ms
    dec.w   R10
    jnz     .Lattract_loop
    ret

;==============================================================================
; pattern_ready
; How it works: LED1 forced solid ON, LED2 forced OFF (both forced with
;   BIS/BIC rather than XOR, since "ready" means a known state regardless
;   of what came before), held for READY_MS.
;==============================================================================
pattern_ready:
    bis.b   #LED1, &P1OUT              ; LED1 ON
    bic.b   #LED2, &P1OUT              ; LED2 OFF
    mov.w   #READY_MS, R12
    call    #delay_ms
    ret

;==============================================================================
; pattern_gameover
; How it works: both LEDs flash together fast, GAMEOVER_FLASHES times.
;   Starts by forcing both OFF (so the first XOR toggle is guaranteed to
;   turn them ON, not off), then XOR-toggles each phase rather than a
;   BIS/BIC pair, since the pattern only cares about flipping, not about
;   forcing a specific level each time. Ends with both LEDs OFF.
;==============================================================================
pattern_gameover:
    bic.b   #(LED1|LED2), &P1OUT       ; guarantee OFF before toggling starts
    mov.w   #GAMEOVER_FLASHES, R10
.Lgameover_loop:
    xor.b   #(LED1|LED2), &P1OUT       ; toggle both together
    mov.w   #GAMEOVER_MS, R12
    call    #delay_ms
    dec.w   R10
    jnz     .Lgameover_loop
    bic.b   #(LED1|LED2), &P1OUT       ; ensure OFF when pattern ends
    ret

;==============================================================================
; delay_ms
; How it works: at 1 MHz, 1 ms = 1000 cycles.
;   Inner loop: dec (1 cycle) + jnz (2 cycles) = 3 cycles per iteration.
;   333 iterations x 3 cycles = 999 cycles ~= 1 ms.
;   Caller loads the ms count into R12 before calling.
;==============================================================================
delay_ms:
    mov.w   #333, R13          ; 333 iterations
.Ldelay_inner:
    dec.w   R13                ; one cycle
    jnz     .Ldelay_inner      ; two cycles
    dec.w   R12                ; one ms elapsed
    jnz     delay_ms           ; start another ms
    ret                        ; done, return to caller

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
