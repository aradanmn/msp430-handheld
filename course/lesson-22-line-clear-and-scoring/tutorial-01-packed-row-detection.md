# Tutorial 01 — Detecting a Full Row in a Tightly-Packed Board

## The Packing, Restated

Lesson 19's board holds 20 rows of 10 columns, one bit per cell, with **no
padding between rows** — row 0's ten bits are immediately followed by row
1's ten bits, and so on, for a total of 200 bits (25 bytes). This is denser
than padding each row out to a whole number of bytes (which would waste 6
bits — most of a byte — per row, 120 bits total across the board), but it
means a row essentially never lines up neatly with a byte boundary.

For a given row `r`, its bits occupy a global bit range:

```
base_bit = r * 10
```

and it occupies bits `base_bit` through `base_bit + 9`, using this
lesson's convention: bit index counted from the start of the packed
array, column 0 the lowest-numbered bit of the row. To find out which
*byte* that starts in, and which *bit within that byte*:

```
byte_idx = base_bit / 8        ; integer division  → shift right 3
bit_off  = base_bit mod 8      ; remainder          → AND with 7
```

## Why It Straddles a Byte Boundary

Ten bits are more than one byte (8 bits) can hold, so no matter what
`bit_off` turns out to be, a row's 10 bits always span **two** consecutive
bytes: `byte_idx` and `byte_idx + 1`. There's no special case where a row
"fits" in one byte — straddling isn't the exception here, it's the rule.

There's a second, more convenient fact hiding in the arithmetic: since 10
is *even*, `base_bit mod 8` only ever comes out to `0, 2, 4,` or `6` —
never an odd number, and (importantly) never high enough to need a *third*
byte. A 10-bit field starting at bit offset 6 within a 16-bit window
occupies bits 6 through 15 — exactly fits. If the offset could ever reach
7, the field would need bit 16, which doesn't exist in a two-byte window —
but because row length (10) and byte width (8) share a factor of 2, that
never happens. Two bytes are always exactly enough.

## Worked Example: Row 5

This lesson's example (`examples/lineclear_demo.s`) uses this packing, and
its deliberately-full test row is row 5:

```
base_bit = 5 * 10 = 50
byte_idx = 50 / 8   = 6   (with a remainder)
bit_off  = 50 mod 8 = 2
```

Row 5's ten bits start at bit 2 of byte 6, and run through bit 7 of byte 6
(6 bits) and bits 0-3 of byte 7 (4 bits) — straddling exactly at the
byte 6 / byte 7 boundary.

## Extracting the Row

Combine the two relevant bytes into one 16-bit value, with the
lower-indexed byte in the low half:

```
word16 = board[byte_idx] | (board[byte_idx + 1] << 8)
```

Then shift that 16-bit window right by `bit_off`, and mask off everything
above the 10 bits you want:

```
row_bits = (word16 >> bit_off) & 0x03FF
```

For row 5 (`byte_idx=6`, `bit_off=2`): read `board[6]` and `board[7]`,
combine them into `word16`, shift right by 2, mask with `0x03FF`. Whatever
comes out is exactly row 5's 10 column bits, right-aligned in the result —
bit 0 of `row_bits` is column 0, bit 9 is column 9, regardless of where
those bits actually lived in the original byte array.

On the MSP430, "shift right by a variable amount" isn't a single
instruction — there's no barrel shifter. The natural way to do it is a
small loop that executes `RRA` (arithmetic shift right) `bit_off` times.
Since `bit_off` here is always small (0, 2, 4, or 6), that loop never runs
more than three iterations.

## Deciding "Full"

Once you have `row_bits` — the row's 10 columns, right-aligned — "is this
row full" is a single comparison: does `row_bits` equal `0x03FF` (all ten
bits set)? Nothing subtler than that. The care all went into getting
`row_bits` extracted correctly in the first place; a row that's missing
even one column (nine bits set, not ten — `examples/lineclear_demo.s`
deliberately includes two such "nearly full" decoy rows) must compare
unequal, or every full-row check downstream becomes unreliable.

## Where the Detection Result Goes

A full-row scan produces, at minimum, *which* row (or rows — up to four
can be full simultaneously if a piece's placement completed several rows
at once, though this lesson's example scans one at a time) is full. That
row index is exactly what Tutorial 02's clearing step and this lesson's
milestone (`board_check_lines`) need next.
