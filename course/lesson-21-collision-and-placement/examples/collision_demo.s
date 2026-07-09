;******************************************************************************
; collision_demo.s — Lesson 21 example
;
; Self-contained demo of a piece_can_move-style legality check. This file
; does NOT call into handheld/game/tetris.s — it builds its own small,
; local test board and a single hardcoded 4x4 piece mask, purely to
; demonstrate the collision-checking technique in isolation.
;
; Board representation used ONLY in this demo file: 20 rows, each row a
; 16-bit word with bit c = column c (c in 0..9). This is simpler than the
; tightly-packed 10-bit-per-row scheme Lesson 22 covers — that packing
; question is orthogonal to this lesson's topic (collision logic), and the
; real handheld/game/tetris.s board_get/board_set already hide whatever
; packing L19 settled on behind a function call.
;
; The piece mask is a single 16-bit value: bit (row*4 + col) set means the
; 4x4 mask's cell (row, col) is occupied, row/col each in 0..3.
;
; Test plan: a table of (row, col, dx, dy, expected) entries. For each one,
; run the local can-move check and compare its result against the
; hand-worked expected value from tutorial-01. LED1 lands solid if every
; case matches; otherwise it blinks forever.
;******************************************************************************

#include "../../common/msp430g2553-defs.s"

;==============================================================================
; Constants
;==============================================================================
.equ    BOARD_ROWS,         20
.equ    BOARD_COLS,         10
.equ    TEST_PIECE_MASK,    0x0036      ; relative cells (0,1) (0,2) (1,0) (1,1)
.equ    TEST_COUNT,         7

    .text
    .global _start

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; LED1 as output
    bic.b   #LED1, &P1OUT               ; start off

;==============================================================================
; main_loop
; How it works: walks .Ltest_vectors, calling .Lcan_move for every case and
; comparing its result against the hand-worked expected value. R5 is the
; table pointer, R6 the remaining-case counter, R7 the fail flag — all
; top-level scratch (this file never enables interrupts, so R4-R7 carry no
; special meaning here the way they would inside main.s's ISR).
;==============================================================================
main_loop:
    mov.w   #.Ltest_vectors, R5
    mov.w   #TEST_COUNT, R6
    clr.w   R7                          ; 0 = every case has matched so far

.Ltest_loop:
    mov.w   @R5+, R12                   ; row
    mov.w   @R5+, R13                   ; col
    mov.w   @R5+, R14                   ; dx
    mov.w   @R5+, R15                   ; dy
    call    #.Lcan_move                 ; R12 = actual result (1/0)
    mov.w   @R5+, R14                   ; R14 = expected result (safe: call
                                         ;   never touches R5)
    cmp.w   R14, R12
    jeq     .Ltest_pass
    mov.w   #1, R7                      ; mismatch — latch the fail flag
.Ltest_pass:
    dec.w   R6
    jnz     .Ltest_loop

    cmp.w   #0, R7
    jz      .Lall_pass
    jmp     .Lblink_forever

.Lall_pass:
    bis.b   #LED1, &P1OUT
    jmp     .Lhalt

.Lblink_forever:
    xor.b   #LED1, &P1OUT
    mov.w   #200, R12
    call    #.Ldelay_ms
    jmp     .Lblink_forever

.Lhalt:
    jmp     .Lhalt

;==============================================================================
; .Lcan_move
; In:  R12=row, R13=col  — piece's current top-left position
;      R14=dx,  R15=dy   — candidate move
; Out: R12 = 1 if every occupied mask cell lands in-bounds and unoccupied
;            after the move, 0 otherwise
; Clobbers: R12-R15. Internally borrows R8-R11 as loop state (saved/
;   restored) so the position/loop-index survive the calls to .Lboard_get.
;==============================================================================
.Lcan_move:
    push    R8
    push    R9
    push    R10
    push    R11

    mov.w   R12, R8
    add.w   R15, R8                     ; R8 = new_row_base = row + dy
    mov.w   R13, R9
    add.w   R14, R9                     ; R9 = new_col_base = col + dx
    mov.w   #TEST_PIECE_MASK, R10       ; R10 = working copy of the mask
    clr.w   R11                         ; R11 = i, the mask bit index (0-15)

.Lcm_loop:
    bit.w   #1, R10                     ; is mask cell i occupied?
    jz      .Lcm_next                   ; empty cell — nothing to check

    mov.w   R11, R12
    rra.w   R12
    rra.w   R12                         ; R12 = i >> 2 = relative row (0-3)
    mov.w   R11, R13
    and.w   #3, R13                     ; R13 = i & 3  = relative col (0-3)
    add.w   R8, R12                     ; R12 = absolute board row
    add.w   R9, R13                     ; R13 = absolute board col

    cmp.w   #0, R12                     ; signed: a nudged-left/up piece can
    jl      .Lcm_illegal                ;   produce a negative coordinate
    cmp.w   #BOARD_ROWS, R12
    jge     .Lcm_illegal
    cmp.w   #0, R13
    jl      .Lcm_illegal
    cmp.w   #BOARD_COLS, R13
    jge     .Lcm_illegal

    call    #.Lboard_get                ; R12=row,R13=col -> R12=0/1
    cmp.w   #0, R12
    jnz     .Lcm_illegal                ; already occupied — illegal

.Lcm_next:
    rra.w   R10                         ; next mask bit
    inc.w   R11
    cmp.w   #16, R11
    jl      .Lcm_loop

    mov.w   #1, R12                     ; every occupied cell checked out
    jmp     .Lcm_done
.Lcm_illegal:
    clr.w   R12
.Lcm_done:
    pop     R11
    pop     R10
    pop     R9
    pop     R8
    ret

;==============================================================================
; .Lboard_get
; In:  R12=row (0-19), R13=col (0-9)
; Out: R12 = 1 if that cell is occupied, 0 if empty
; Clobbers: R12-R14
;==============================================================================
.Lboard_get:
    rla.w   R12                         ; row -> word offset into .Ldemo_board
    add.w   #.Ldemo_board, R12
    mov.w   @R12, R12                   ; R12 = this row's 16 packed columns
    rla.w   R13                         ; col -> word offset into .Lcol_mask
    add.w   #.Lcol_mask, R13
    mov.w   @R13, R13                   ; R13 = (1 << col)
    and.w   R13, R12                    ; R12 = row_bits & (1<<col), Z set if 0
    jz      .Lbg_empty
    mov.w   #1, R12
    ret
.Lbg_empty:
    clr.w   R12
    ret

;==============================================================================
; .Ldelay_ms — busy-wait ~R12 milliseconds at 1 MHz. Arg: R12. Clobbers R13.
;==============================================================================
.Ldelay_ms:
    mov.w   #333, R13
.Ltms_loop:
    dec.w   R13
    jnz     .Ltms_loop
    dec.w   R12
    jnz     .Ldelay_ms
    ret

;==============================================================================
; .Lcol_mask — (1 << col) for col 0..9
;==============================================================================
.Lcol_mask:
    .word   0x0001, 0x0002, 0x0004, 0x0008, 0x0010
    .word   0x0020, 0x0040, 0x0080, 0x0100, 0x0200

;==============================================================================
; .Ldemo_board — 20 rows, one word each, bit c = column c.
; Every row is empty except row 19, which has columns 0-3 already filled in
; from previously-placed pieces (a small stack against the left wall).
;==============================================================================
.Ldemo_board:
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0        ; rows 0-9
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0           ; rows 10-18
    .word   0x000F                              ; row 19 — cols 0-3 filled

;==============================================================================
; .Ltest_vectors — (row, col, dx, dy, expected) — see tutorial-01's worked
; examples for cases 1-4 (near the wall) and 5-7 (near the stack).
;==============================================================================
.Ltest_vectors:
    .word   5,  7,  0,  0,  1     ; baseline, open area              -> legal
    .word   5,  7,  1,  0,  0     ; nudge right into the wall        -> illegal
    .word   5,  7, -1,  0,  1     ; nudge left, still in bounds      -> legal
    .word   5,  7,  0,  1,  1     ; one row down, still open         -> legal
    .word  17,  1,  0,  0,  1     ; baseline, above the stack        -> legal
    .word  17,  1,  0,  1,  0     ; one row down, onto the stack     -> illegal
    .word  17,  1,  0,  2,  0     ; two rows down, off the board     -> illegal

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
