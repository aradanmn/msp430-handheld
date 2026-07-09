# Tutorial 01 — Tile Bitmaps in Flash

## Why Flash, Not RAM

A tetromino block, a cursor icon, a small font glyph — all of these are
small, fixed images that never change once drawn: this course calls them
**tiles** or **sprites** interchangeably. Because their content is fixed at
compile time, there's no reason to burn any of the MSP430's 512 bytes of
RAM holding them. They belong in Flash (16 KB, far more headroom), right
alongside your code, exactly the way `init_cmds` in Lesson 13 stored the
OLED's command sequence as `.byte` data mixed into `.text`.

## The Bitmap Format

This course uses a fixed **8×8 pixel, 1-bit-per-pixel** tile format: 8
bytes per sprite, one byte per row, top row first. Within a byte, **bit 7
is the leftmost column, bit 0 is the rightmost** — the same MSB-first
convention you've already been using since Lesson 12's SPI work, applied
here to horizontal pixel order instead of serial bit order.

```
byte 0  = row 0 (top)       bit 7 = column 0 (left) ... bit 0 = column 7 (right)
byte 1  = row 1
...
byte 7  = row 7 (bottom)
```

A solid filled diamond, for example, looks like this as an 8x8 grid (`#` =
pixel on, `.` = pixel off) and the `.byte` literal it corresponds to:

```
. . . # # . . .    0b00011000  =  0x18
. . # # # # . .    0b00111100  =  0x3C
. # # # # # # .    0b01111110  =  0x7E
# # # # # # # #    0b11111111 =  0xFF
# # # # # # # #    0b11111111 =  0xFF
. # # # # # # .    0b01111110  =  0x7E
. . # # # # . .    0b00111100  =  0x3C
. . . # # . . .    0b00011000  =  0x18
```

```asm
tile_diamond:
    .byte   0x18, 0x3C, 0x7E, 0xFF, 0xFF, 0x7E, 0x3C, 0x18
```

## Reading a Bit Out of a Row Byte

To find out whether column `c` (0–7) of a given row byte is set, build a
mask with a single bit at position `(7 - c)` and `bit.b` it against the row
byte. This is exactly the same masking idiom from
`msp430g2553-defs.s`'s opening tutorial — nothing new conceptually, just
applied column-by-column instead of to a fixed peripheral bit.

A lookup table of the eight possible single-bit masks (`0x80, 0x40, 0x20,
0x10, 0x08, 0x04, 0x02, 0x01`, one per column 0–7) turns "give me the mask
for column c" into a single indexed load — the same technique
`display_set_pixel` already used in Lesson 13 for turning a bit-within-page
index into a mask.

## `sprite_draw`

`sprite_draw` walks all 8 rows of a sprite bitmap, and within each row, all
8 columns, calling `display_set_pixel(x + column, y + row)` for every
column whose bit is set — skipping columns whose bit is 0 (those pixels are
"transparent": the sprite doesn't touch them at all, it neither lights nor
clears them).

```asm
; sprite_draw: R12 = pointer to 8-byte tile bitmap, R13 = x, R14 = y
sprite_draw:
    push    R7
    push    R8
    push    R9
    push    R10
    push    R11

    mov.w   R12, R11          ; R11 = tile pointer
    mov.w   R13, R8           ; R8 = base x
    mov.w   R14, R9           ; R9 = base y
    mov.w   #8, R10           ; R10 = row counter

.Lrow_loop:
    cmp.w   #0, R10
    jz      .Ldone
    mov.b   @R11, R7          ; R7 = this row's byte
    ; ... for each of 8 columns, test a bit in R7 and call display_set_pixel ...
    inc.w   R11               ; next row byte
    inc.w   R9                ; y++
    dec.w   R10
    jmp     .Lrow_loop
.Ldone:
    pop     R11
    pop     R10
    pop     R9
    pop     R8
    pop     R7
    ret
```

The column loop (testing each of the 8 bits in `R7` against the mask table
and calling `display_set_pixel(x + column, y)` for set bits) is left as a
sketch here deliberately — you'll write the full version yourself in this
lesson's milestone. The shape of the outer loop, and where the tile pointer
and coordinates live, is the part worth internalizing first.

## What's Next

Tutorial 02 covers the part of sprite handling that has nothing to do with
drawing a single sprite correctly, and everything to do with what happens
the *second* time you draw one — moving a sprite from one position to
another without leaving visible artifacts behind.
