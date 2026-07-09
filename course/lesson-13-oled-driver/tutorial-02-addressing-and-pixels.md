# Tutorial 02 — Page/Column Addressing and Drawing a Pixel

## GDDRAM Is Organized in Pages

An SSD1306-family controller doesn't store one bit per pixel in a flat,
row-major array the way you might picture a framebuffer. Instead, GDDRAM is
organized into **pages** — horizontal bands, each **8 pixels tall** — and
within a page, each byte holds one **column** of 8 vertical pixels, LSB at
the top of the byte's span (bit 0 = top row of the page, bit 7 = bottom row
of that page — check your specific controller's datasheet, as some parts
document this the other way).

For a 128-pixel-wide, 64-pixel-tall panel:

```
128 columns wide, 64 rows tall
64 rows / 8 pixels-per-page = 8 pages (page 0 at the top, page 7 at the bottom)
GDDRAM size = 128 columns * 8 pages = 1024 bytes total
```

A pixel at coordinate (x, y) lives at:

```
page = y / 8              ; which horizontal band
bit  = y mod 8             ; which bit within that page's byte
byte address = (page, x)   ; column x, within page "page"
```

## Setting Up an Address Window

Before sending data bytes, you tell the controller which column and page
range subsequent data bytes should land in. The two addressing-mode
commands you'll use most:

- **Set column address** — start and end column for this write
- **Set page address** — start and end page for this write

Depending on the addressing mode command you sent during init, the
controller will auto-increment through the window you set (column-first or
page-first) as you stream data bytes, wrapping back to the start of the
window when it reaches the end. This is what makes a full-screen clear
efficient: set the window to the whole display once, then stream 1024
zero-bytes without re-issuing an address command between every byte.

## Drawing One Pixel

To light a single pixel at (x, y) without disturbing anything else on the
screen, you would, in principle, need to:

1. Read the current byte at (page, x)
2. Set (or clear) just the one bit for this pixel
3. Write the modified byte back

Step 1 is the problem. This project's SPI wiring never connects the OLED's
data-out line back to the MSP430 (Tutorial 01) — there is no way to read
GDDRAM back. Every write this lesson makes is a **blind, full-byte write**:
whatever 8 bits you send become the entire contents of that page/column
byte, replacing whatever was there before.

For this lesson's purposes — turning on exactly one pixel on an otherwise
freshly-cleared screen — that's not a problem: if you clear the whole
display first (write 0x00 everywhere), then write a single byte with only
one bit set at your target pixel's (page, x), the result is correct, because
you already know what the rest of that byte's neighbors are (they're all
0, because you just cleared them).

```asm
; Conceptually, to set pixel (x, y):
;   page = y >> 3
;   bit  = y & 7
;   set column address window to [x, x]
;   set page address window to [page, page]
;   send one data byte with bit `bit` set, all other bits 0
```

**This stops being sufficient the moment two things need to coexist in the
same byte** — say, a sprite's edge and a UI border sharing a page/column.
Setting one pixel this way silently erases its 7 neighbors in that byte.
That's a real, current limitation of `display_set_pixel` as built in this
lesson, not a bug to fix here — Lesson 14 introduces a local framebuffer
specifically to solve it, by giving the MCU its own read-write copy of at
least the bytes it's actively drawing into.

## Putting It Together

`display_set_pixel(x, y)` in this lesson's example does exactly the four
steps above: compute page and bit from y, set a 1-column/1-page address
window, then send one data byte with only that bit set. Study
`examples/display_demo.s` for the concrete command bytes this course uses —
remembering, per Tutorial 01, that the exact addressing-mode command values
are still worth double-checking against your specific controller's
datasheet.
