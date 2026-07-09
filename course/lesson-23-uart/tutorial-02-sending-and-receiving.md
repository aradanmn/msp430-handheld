# Tutorial 23.2 — Sending the Score, Receiving a Command

## Sending: turning a 16-bit number into readable text

`UCA0TXBUF` only ever holds one byte at a time, and a byte is not a
number a human can read on a terminal — it's a raw 8-bit pattern.
`ui_send_score`'s job (this lesson's milestone) is to take a 16-bit binary
score sitting in a register and turn it into a sequence of bytes that
*look like* the score when printed.

There are two reasonable ways to do this, and it's worth understanding both
even though you only need to implement one for the milestone.

**Fixed-width binary dump.** Send the score as exactly two bytes — high byte
first, then low byte — with no conversion at all:

```asm
; R12 = 16-bit score
mov.b   R12, R13            ; low byte
swpb    R12                  ; swap bytes so the high byte is now in the low position
call    #uart_tx_byte        ; send high byte (R12 low byte after swap)
mov.b   R13, R12
call    #uart_tx_byte        ; send low byte
```

This is trivial to implement and completely unambiguous to a program
reading the serial port back — but it's not human-readable in a plain
terminal. A score of 300 arrives as the two raw bytes `0x01` `0x2C`, which
`picocom` will render as unprintable control characters, not the text
"300".

**ASCII decimal conversion.** Convert the binary value into the sequence of
ASCII digit characters a human would write for that number, most
significant digit first, so "300" arrives as the three printable bytes
`'3'` `'0'` `'0'` (0x33, 0x30, 0x30). The standard technique: repeatedly
divide the value by 10, and each remainder is one decimal digit — but the
digits come out **least-significant first** (dividing 300 by 10 gives you
the "0" ones digit before the "3" hundreds digit), so they need to be
collected somewhere (a small buffer, or the stack) and then emitted in
reverse order to print correctly. This is more work than the fixed-width
dump, but the payoff is that the score is legible in `picocom` with no
special receiving program needed on the other end — exactly the debugging
convenience this lesson exists to provide.

Either approach is a valid milestone implementation; `ui_send_score`'s spec
(Exercise 3) leaves the choice, and the exact format, to you — the only
requirement is that whatever you choose is documented and genuinely
readable on a terminal.

## Receiving: polling vs. interrupt-driven RX

Reading a received byte by polling looks exactly like the transmit side,
mirrored:

```asm
.Lwait_rx:
    bit.b   #UCA0RXIFG, &IFG2   ; has a byte arrived?
    jz      .Lwait_rx           ; no — keep spinning
    mov.b   &UCA0RXBUF, R12     ; read it (this also clears UCA0RXIFG)
```

This is exactly what `examples/uart_echo.s` does, and it's fine for a
program whose *only* job is to sit and wait for serial input. But the
handheld's game loop already has a job: service the Timer_A tick that
drives gravity, read buttons, update the board, redraw the display — all
while sitting in LPM0 between ticks (Lesson 11). A polling wait on
`UCA0RXIFG` is a *blocking* wait: the CPU sits in that loop doing nothing
else until a byte arrives, which could be never, if nobody's typing.
Blocking on RX inside the game loop would freeze gravity, freeze input,
freeze the display — the whole game — for as long as no serial byte shows
up. That's unacceptable for something that's supposed to run continuously
whether or not anyone has a terminal open.

The fix is the same one Lesson 10 introduced for the timer tick: let
hardware raise an interrupt instead of spinning on a flag.

```asm
bis.b   #UCA0RXIE, &IE2        ; enable USCI_A0 RX interrupt
```

With `UCA0RXIE` set (and `GIE` set, as always), the CPU can enter LPM0 and
do nothing at all until *either* the timer tick or an incoming UART byte
wakes it — whichever comes first. The RX ISR (vector `0xFFEE`, this
course's USCI_A0/B0 RX slot) reads `UCA0RXBUF` and stores the byte
somewhere the main loop can pick it up later, then returns. The main loop
never blocks waiting for serial data; it just checks, once per game tick,
"did a command byte show up since I last checked?" — which is exactly the
shape of `ui_poll_speed_override`'s spec in Exercise 3.

```asm
    .section ".vectors","ax",@progbits
    ; ... other vectors ...
    .word   ui_rx_isr      ; 0xFFEE  USCI_A0/B0 RX
    ; ...
```

Note the trade: polling RX is simpler to write and perfectly fine for a
standalone program (like this lesson's example and Exercise 1) that has
nothing else to do. Interrupt-driven RX is the right choice the moment RX
has to coexist with another periodic obligation the CPU can't afford to
starve — which is precisely the handheld's situation from here on.

## Check your understanding

1. Why does reading `UCA0RXBUF` clear `UCA0RXIFG` automatically, while
   `UCA0TXIFG` has to be cleared implicitly by writing `UCA0TXBUF` rather
   than by reading anything?
2. If the game loop polled `UCA0RXIFG` directly inside its per-tick logic
   (instead of using an RX interrupt) but never blocked — i.e., checked the
   flag once and moved on regardless of whether it was set — would that
   avoid the freezing problem? What would it cost you compared to a true
   interrupt-driven approach?
3. Converting a score to ASCII decimal produces digits least-significant
   digit first. Why, and what has to happen before they're transmitted in
   the right reading order?
