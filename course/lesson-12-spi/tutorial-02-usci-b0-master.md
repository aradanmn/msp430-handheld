# Tutorial 02 — USCI_B0 as an SPI Master

## The Registers

USCI_B0 is the same hardware block used for I2C in later lessons — SPI mode
and I2C mode share the same control registers but interpret some bits
differently. For SPI, the registers that matter are:

| Register | Role |
|----------|------|
| `UCB0CTL0` | Mode configuration: clock phase/polarity, bit order, master/slave |
| `UCB0CTL1` | Clock source select + the `UCSWRST` reset-hold bit |
| `UCB0BR0` / `UCB0BR1` | Bit-rate divisor (16-bit, low/high byte) |
| `UCB0TXBUF` | Write a byte here to transmit it |
| `UCB0RXBUF` | Read the byte that was shifted in during the last transaction |
| `IFG2` | Holds `UCB0TXIFG` (TX buffer ready) and `UCB0RXIFG` (RX buffer full) |

`UCB0CTL0`'s bits map directly onto the SPI concepts from Tutorial 01:

```
Bit 7: UCCKPH  — clock phase
Bit 6: UCCKPL  — clock polarity (0 = idle LOW)
Bit 5: UCMSB   — 1 = MSB first
Bit 3: UCMST   — 1 = master mode
Bit 0: UCSYNC  — 1 = synchronous (required for SPI, as opposed to UART)
```

Watch the `UCCKPH` naming carefully — TI's bit is literally named for clock
*phase*, but its sense (0 vs. 1 → which edge) doesn't read the same as the
CPOL/CPHA table in Tutorial 01 at a glance. Don't derive the bit value from
first principles under time pressure; use the proven combination below and
move on. Every device this course uses is Mode 0, so you'll set the same
bits every time.

## The Configure-in-Reset Pattern

USCI peripherals refuse to let you change most control bits while the module
is actively running — you have to hold it in software reset (`UCSWRST` in
`UCB0CTL1`), make every configuration change, then release the reset. This is
the exact same pattern you used for UART in earlier UCA0 configuration and
will reuse for I2C:

```asm
bis.b   #UCSWRST, &UCB0CTL1              ; 1. hold module in reset
mov.b   #(UCCKPH|UCMSB|UCMST|UCSYNC), &UCB0CTL0   ; 2. mode: SPI Mode 0, MSB-first, master
mov.b   #UCSSEL_2, &UCB0CTL1             ; 3. clock source: SMCLK (UCSWRST bit untouched here)
mov.b   #0x02, &UCB0BR0                  ; 4. bit-rate divisor low byte
mov.b   #0x00, &UCB0BR1                  ; 5. bit-rate divisor high byte
bic.b   #UCSWRST, &UCB0CTL1              ; 6. release reset — SPI is now live
```

Step 3 writes `UCSSEL_2` into `UCB0CTL1` — the same register that holds
`UCSWRST`. Because `UCSSEL_2` (`0x80`) and `UCSWRST` (`0x01`) occupy different
bits, and because we haven't cleared `UCSWRST` yet, this `mov.b` briefly looks
like it clobbers the reset bit — but a plain `mov.b` writing `0x80` sets bit 7
and clears every other bit **including bit 0**, so if you did this before step
6 you'd release reset early. That's exactly why the sequence above defers
`bic.b #UCSWRST` to the very last step: everything else uses `mov.b`/`bis.b`
freely while the module sits safely in reset, and only the final instruction
lets it start running.

**Bit-rate divisor:** with SMCLK at 1 MHz and `UCB0BR0 = 0x02`, `UCB0BR1 =
0x00`, the SPI clock runs at 1 MHz ÷ 2 = 500 kHz — comfortably inside every
part this course uses.

## Pin Muxing: P1SEL *and* P1SEL2

P1.5/P1.6/P1.7 default to plain GPIO. To hand them to USCI_B0 you set the
matching bit in **both** `P1SEL` and `P1SEL2` — the G2553 uses the pair of
registers together to select among GPIO and two different peripheral
functions per pin, and USCI is one of the "both bits set" combinations. Look
at the pin function table in SLAS735 (or the `P1SEL`/`P1SEL2` doc comments in
`msp430g2553-defs.s`) to confirm this for yourself — it is easy to set one and
forget the other, and the failure mode is subtle: the pins keep behaving like
GPIO, so nothing on the bus moves, but nothing in your SPI configuration
looks wrong either.

```asm
bis.b   #(BIT5|BIT6|BIT7), &P1SEL
bis.b   #(BIT5|BIT6|BIT7), &P1SEL2
```

## `spi_tx_byte`

A full SPI transaction is: wait until the TX buffer is free, write the byte,
then wait until a full byte has shifted into the RX buffer before you trust
it (or before you let anything else touch the bus). Both waits matter —
`UCB0TXIFG` only tells you the *previous* byte has moved out of the buffer
and into the shift register, not that shifting has finished; `UCB0RXIFG`
is what confirms the full 8-bit transaction actually completed.

```asm
spi_tx_byte:
.Lwait_tx:
    bit.b   #UCB0TXIFG, &IFG2
    jz      .Lwait_tx                   ; wait for TX buffer to be free
    mov.b   R12, &UCB0TXBUF              ; load byte — shifting starts automatically

.Lwait_rx:
    bit.b   #UCB0RXIFG, &IFG2
    jz      .Lwait_rx                   ; wait for the byte to finish shifting in
    mov.b   &UCB0RXBUF, R12              ; return received byte
    ret
```

Following this course's register convention (`handheld/registers.md`), the
byte to send arrives in **R12** and the byte received comes back in **R12**
— a caller-saved scratch register, exactly what you'd expect from a
subroutine argument/return pair.

## Chip Select — Who Owns It?

Nothing in `spi_tx_byte` above touches a CS pin. That's deliberate: CS is
specific to whichever device you're talking to (OLED CS is P2.0; the SRAM's
CS in Lesson 25 is a different pin entirely), so the transport layer
(`hal/spi.s`) has no business knowing about it. The device-specific module —
`hal/display.s` starting next lesson — pulls its own CS line low before a
transaction and high after, then calls `spi_tx_byte` for each byte in
between. This mirrors real driver layering: one shared bus driver, many
independent device drivers built on top of it.

## Proving It Works: Loopback

Before trusting `spi_tx_byte` to talk to a real display, you can verify the
USCI_B0 configuration in isolation, with no display attached at all: jumper
P1.7 (MOSI) directly to P1.6 (MISO). Whatever byte you transmit loops
straight back into your own receiver. If the byte you read back doesn't match
the byte you sent, the bug is in your configuration — not in a $50 OLED you
haven't even wired up yet. This is the basis of `examples/spi_loopback.s` and
Exercise 2.
