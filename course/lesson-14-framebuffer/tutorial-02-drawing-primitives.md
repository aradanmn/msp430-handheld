# Tutorial 02 — Drawing Primitives on Top of `display_set_pixel`

## The Shape of the Problem

Every primitive this lesson builds — filled rectangle, horizontal line,
vertical line — reduces to "call `display_set_pixel(x, y)` for every pixel
this shape covers." The interesting part isn't the geometry (that's simple
nested counting); it's that these subroutines need **more live values at
once than the register convention gives you scratch space for.**

## The Register Budget

`handheld/registers.md` reserves R12–R15 as caller-saved scratch — exactly
four registers, which is also exactly how many arguments a filled rectangle
needs (`x0, y0, x1, y1`). The moment you're inside the subroutine and need
to *also* track a current row, a current column, and loop counters, you've
run out of scratch registers before you've drawn a single pixel.

The fix is the same one you already used for `timer_isr` back in Lesson 05:
**borrow persistent registers, and push/pop them.** R4–R11 are callee-saved
by convention — any subroutine may use them as long as it restores them
before returning. `framebuf_fill_rect` needs five live values across its
loop (a column counter, the row's starting x, the row width, the current y,
and a row counter) — more than R12–R15 alone can hold, but comfortably
within R7–R11 borrowed for the duration of the call:

```asm
framebuf_fill_rect:
    ; R12=x0, R13=y0, R14=x1, R15=y1  (inclusive corners)
    push    R7
    push    R8
    push    R9
    push    R10
    push    R11

    mov.w   R12, R8          ; R8 = x0 (reload value for each row)
    mov.w   R14, R9          ; R9 = width = x1 - x0 + 1
    sub.w   R8, R9
    inc.w   R9

    mov.w   R13, R10         ; R10 = y, starts at y0
    mov.w   R15, R11         ; R11 = height = y1 - y0 + 1
    sub.w   R13, R11
    inc.w   R11

.Lrow_loop:
    cmp.w   #0, R11
    jz      .Lrow_done
    mov.w   R9, R7           ; R7 = column counter, reset each row
    mov.w   R8, R12          ; R12 = x, starts at x0 for this row
.Lcol_loop:
    cmp.w   #0, R7
    jz      .Lcol_done
    mov.w   R10, R13         ; R13 = y (this row)
    call    #display_set_pixel
    inc.w   R12
    dec.w   R7
    jmp     .Lcol_loop
.Lcol_done:
    inc.w   R10              ; next row
    dec.w   R11
    jmp     .Lrow_loop
.Lrow_done:

    pop     R11
    pop     R10
    pop     R9
    pop     R8
    pop     R7
    ret
```

Notice that `display_set_pixel` itself (Lesson 13) already saves and
restores R9–R11 internally — so it's safe for `framebuf_fill_rect` to keep
live state in those same registers across repeated calls into it. This is
exactly the callee-saved contract paying off: neither routine needs to know
the other's internals, only that the convention is honored.

## Lines Are Degenerate Rectangles

A horizontal line from `(x0, y)` to `(x1, y)` is a filled rectangle one
pixel tall. A vertical line from `(x, y0)` to `(x, y1)` is a filled
rectangle one pixel wide. Rather than duplicating the double loop, both
`framebuf_hline` and `framebuf_vline` can simply rearrange their arguments
into the shape `framebuf_fill_rect` expects and call it:

```asm
; framebuf_hline: R12=x0, R13=x1, R14=y  ->  fill_rect(x0, y, x1, y)
framebuf_hline:
    mov.w   R14, R15         ; R15 = y1 = y
    mov.w   R13, R14         ; R14 = x1
    mov.w   R15, R13         ; R13 = y0 = y
    call    #framebuf_fill_rect
    ret

; framebuf_vline: R12=x, R13=y0, R14=y1  ->  fill_rect(x, y0, x, y1)
framebuf_vline:
    mov.w   R14, R15         ; R15 = y1
    mov.w   R12, R14         ; R14 = x1 = x
    call    #framebuf_fill_rect
    ret
```

The order of those `mov.w` instructions matters — each one reads a register
before anything later overwrites it. Trace through both by hand with actual
numbers (say `x0=2, x1=9, y=5` for the hline) before you trust it; this is
exactly the kind of register-shuffling code where a swapped pair of lines
produces something that assembles fine and draws a rectangle in the wrong
place.

## Argument Convention Recap

| Function | Arguments | 
|----------|-----------|
| `framebuf_fill_rect` | R12=x0, R13=y0, R14=x1, R15=y1 (inclusive corners) |
| `framebuf_hline` | R12=x0, R13=x1, R14=y |
| `framebuf_vline` | R12=x, R13=y0, R14=y1 |

All three are built entirely on `display_set_pixel` — no new hardware
knowledge, no local buffer, just controlled iteration and careful register
bookkeeping.

## What's Next

This "one `display_set_pixel` call per pixel" approach is completely
correct and is what `examples/framebuf_demo.s` uses to draw a board border
and a single block. Exercise 2 asks you to notice what it costs once shapes
get bigger, and to explore buffering a page at a time as the fix.
