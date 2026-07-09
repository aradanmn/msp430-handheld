#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #(LED1|LED2), &P1DIR       ; both LEDs as outputs
    bic.b   #(LED1|LED2), &P1OUT       ; both LEDs off

;==============================================================================
; Self-test
;
; Compute a small known sum with ADD, then CMP it against the value we
; expect. The conditional branch (jeq) that acts on that comparison happens
; IMMEDIATELY afterward — no call, no other flag-setting instruction, sits
; between the cmp and the jeq. That ordering is not a style preference: see
; tutorial-02 for what happens when a `call` gets inserted there instead.
;
; Only AFTER the branch has already committed to .Lpass or .Lfail do we
; call a subroutine (hold_forever / .Lfail_blink's delay_ms) whose own
; dec.w/jnz loop clobbers C, Z, and N. That's safe here — by the time those
; calls happen, the branch decision this self-test cares about has already
; been made and acted on.
;==============================================================================
.equ    EXPECTED_SUM, 10

    mov.w   #2, R12
    add.w   #3, R12                     ; R12 = 5   (ADD sets flags — ignored, not our branch)
    add.w   #5, R12                     ; R12 = 10
    cmp.w   #EXPECTED_SUM, R12          ; Z=1 iff R12 == EXPECTED_SUM
    jeq     .Lpass                      ; branch decided NOW, right after cmp
    jmp     .Lfail

;------------------------------------------------------------------------------
; Pass path: light LED1 solid, then hold that state forever. hold_forever
; calls delay_ms repeatedly — delay_ms's internal dec.w/jnz loop stomps the
; flags every single call, which is fine, because .Lpass was already chosen
; above before any of those calls happened.
;------------------------------------------------------------------------------
.Lpass:
    bis.b   #LED1, &P1OUT               ; LED1 solid ON = self-test passed
    call    #hold_forever

;------------------------------------------------------------------------------
; Fail path: unreachable in this demo (EXPECTED_SUM is deliberately correct),
; kept here to show the distinct fail pattern the same structure would give
; you if the comparison had come out the other way — LED2 flashing instead
; of LED1 solid.
;------------------------------------------------------------------------------
.Lfail:
.Lfail_blink:
    bis.b   #LED2, &P1OUT
    mov.w   #150, R12
    call    #delay_ms
    bic.b   #LED2, &P1OUT
    mov.w   #150, R12
    call    #delay_ms
    jmp     .Lfail_blink

;==============================================================================
; hold_forever
; Keeps whatever LED state the caller already set by repeatedly calling
; delay_ms. Never touches P1OUT itself — its only job is to burn time.
;==============================================================================
hold_forever:
.Lhold_loop:
    mov.w   #1000, R12
    call    #delay_ms
    jmp     .Lhold_loop

;==============================================================================
; delay_ms
; Busy-wait for R12 milliseconds. At 1 MHz, 1 ms ~= 1000 cycles.
;   Inner loop: dec (1 cycle) + jnz (2 cycles) = 3 cycles/iteration
;   MS_CYCLES iterations x 3 cycles ~= 1 ms
;
; WARNING: dec.w and jnz below overwrite C/Z/N on every pass. Never call
; delay_ms (or anything like it) between a flag-setting instruction and the
; conditional branch that depends on it — see tutorial-02.
;==============================================================================
.equ    MS_CYCLES, 333

delay_ms:
.Ldelay_ms_outer:
    mov.w   #MS_CYCLES, R13
.Ldelay_ms_inner:
    dec.w   R13                         ; 1 cycle
    jnz     .Ldelay_ms_inner            ; 2 cycles (taken)
    dec.w   R12
    jnz     .Ldelay_ms_outer
    ret

    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
