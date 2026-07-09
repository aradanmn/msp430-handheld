#include "../../common/msp430g2553-defs.s"

    .text
    .global _start

;==============================================================================
; piece_demo.s
;
; Encodes the T-tetromino's four rotation states as a Flash table (one
; 16-bit .word per rotation), and implements piece_cell(rotation, row, col)
; -> bit, extracting a single cell from the appropriate word via bit math.
;
; Encoding convention (matches Lesson 19's board: row-major, MSB-first):
;   Each rotation is a 4x4 grid, 16 cells, packed into one 16-bit word.
;   bit_index_in_word = row*4 + col          (row-major, 0-15)
;   bit_pos            = 15 - bit_index_in_word  (MSB-first: bit 15 = cell 0)
;
; Flash table layout: piece_table + rotation*2 (2 bytes per rotation, since
; each rotation is exactly one .word).
;
; Self-test: checks piece_cell against a hardcoded, independently-written
; set of expected values for all 16 cells across all 4 rotations (64 checks
; total). LED1 lights SOLID if every check passes, BLINKS if any fails.
;==============================================================================

.equ    NUM_ROTATIONS,  4
.equ    GRID_SIZE,      4          ; 4x4 grid -> 16 cells per rotation

_start:
    mov.w   #0x0400, SP                 ; init stack pointer (top of RAM)
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; disable watchdog — always second
    clr.b   &DCOCTL
    mov.b   &CALBC1_1MHZ, &BCSCTL1     ; calibrate DCO to 1 MHz
    mov.b   &CALDCO_1MHZ, &DCOCTL

    bis.b   #LED1, &P1DIR               ; LED1 = output
    bic.b   #LED1, &P1OUT               ; start OFF

    mov.w   #0, R4                      ; R4 = rotation index, 0-3

test_rotation:
    mov.w   R4, R9
    rla.w   R9                          ; R9 = rotation*2 (byte offset)
    mov.w   expected_table(R9), R7      ; R7 = expected 16-bit word

    mov.w   #0, R5                      ; R5 = row, 0-3
test_row:
    mov.w   #0, R6                      ; R6 = col, 0-3
test_col:
    ; expected bit for (row=R5, col=R6), from the known-correct word in R7
    mov.w   R5, R10
    rla.w   R10
    rla.w   R10                         ; R10 = row*4
    add.w   R6, R10                     ; R10 = bit_index_in_word
    mov.w   #15, R11
    sub.w   R10, R11                    ; R11 = bit_pos (MSB-first)

    mov.w   #1, R8
.Lexpshift:
    tst.w   R11
    jz      .Lexpshift_done
    rla.w   R8
    dec.w   R11
    jmp     .Lexpshift
.Lexpshift_done:
    bit.w   R8, R7
    jz      .Lexp_zero
    mov.w   #1, R8                      ; R8 = expected bit
    jmp     .Lexp_have
.Lexp_zero:
    mov.w   #0, R8
.Lexp_have:

    ; actual = piece_cell(rotation=R4, row=R5, col=R6)
    mov.w   R4, R12
    mov.w   R5, R13
    mov.w   R6, R14
    call    #piece_cell

    cmp.w   R8, R12
    jnz     fail

    inc.w   R6
    cmp.w   #GRID_SIZE, R6
    jnz     test_col

    inc.w   R5
    cmp.w   #GRID_SIZE, R5
    jnz     test_row

    inc.w   R4
    cmp.w   #NUM_ROTATIONS, R4
    jnz     test_rotation

pass:
    bis.b   #LED1, &P1OUT               ; all 64 checks passed: LED1 solid ON
.Lpass_hold:
    jmp     .Lpass_hold

fail:
.Lfail_loop:
    xor.b   #LED1, &P1OUT               ; a check failed: LED1 blinks
    mov.w   #20000, R12
    call    #delay_loop
    jmp     .Lfail_loop

;==============================================================================
; delay_loop — busy-waits ~R12 iterations. Only used by the failure blink.
;==============================================================================
delay_loop:
.Ldelay:
    dec.w   R12
    jnz     .Ldelay
    ret

;==============================================================================
; piece_cell(rotation, row, col) -> bit
;   R12 = rotation (0-3), R13 = row (0-3), R14 = col (0-3)     (in)
;   R12 = 1 if that cell is part of the piece, 0 otherwise     (out)
;==============================================================================
piece_cell:
    rla.w   R12                         ; R12 = rotation*2 (byte offset)
    mov.w   piece_table(R12), R15       ; R15 = 16-bit rotation word from Flash

    mov.w   R13, R12                    ; R12 = row
    rla.w   R12
    rla.w   R12                         ; R12 = row*4
    add.w   R14, R12                    ; R12 = bit_index_in_word = row*4+col

    mov.w   #15, R14
    sub.w   R12, R14                    ; R14 = bit_pos (MSB-first)

    mov.w   #1, R12                     ; R12 = mask, starts at bit 0
.Lpc_shift:
    tst.w   R14
    jz      .Lpc_shift_done
    rla.w   R12
    dec.w   R14
    jmp     .Lpc_shift
.Lpc_shift_done:

    bit.w   R12, R15
    jz      .Lpc_zero
    mov.w   #1, R12
    ret
.Lpc_zero:
    mov.w   #0, R12
    ret

;==============================================================================
; T-piece rotation table — one .word per rotation state (4 states, worked
; out by hand in tutorial-01/02 from the T piece's 4x4 grids):
;   rotation 0: . . . .      rotation 1: . X . .      rotation 2: . . . .
;               . X . .                  . X X .                  . X X X
;               X X X .                  . X . .                  . . X .
;               . . . .                  . . . .                  . . . .
;   rotation 3: . . . .
;               . . X .
;               . X X .
;               . . X .
;==============================================================================
piece_table:
    .word   0x04E0     ; rotation 0
    .word   0x4640     ; rotation 1
    .word   0x0720     ; rotation 2
    .word   0x0262     ; rotation 3

; Independently-listed expected values used only by the self-test above --
; deliberately the same known-correct words as piece_table, since this test
; is checking whether piece_cell's addressing/extraction math decodes a
; known word correctly, not re-deriving the shape.
expected_table:
    .word   0x04E0, 0x4640, 0x0720, 0x0262

;==============================================================================
; Interrupt Vector Table
;==============================================================================
    .section ".vectors","ax",@progbits
    .word   0,0,0,0, 0,0,0,0           ; 0xFFE0–0xFFEF  unused
    .word   0,0,0,0, 0,0,0             ; 0xFFF0–0xFFFC  unused
    .word   _start                      ; 0xFFFE  Reset
    .end
