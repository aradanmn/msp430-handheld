# Exercise 3 (Milestone) — Extend `handheld/hal/input.s` for Shift-Register Input

## Where you're starting from

Your `handheld/hal/input.s` (Lesson 07) already debounces and edge-detects
one button read from `P1IN`. This milestone does **not** throw that away —
it replaces the raw-sampling step underneath it with an 8-bit read from the
SN74HC165N, so the same debounce/edge logic now runs independently across
all 8 buttons instead of just one.

## Behavior Required

**Raw sampling (new):**

A single-transaction read of the shift register, following exactly the
protocol from the lesson: pulse PL (P2.3) low then high to latch, then
clock 8 bits through USCI_B0 SPI, then invert so `1 = pressed`. This
replaces whatever code previously sampled `P1IN` bit 3 for S2.

**Debounce/edge detection (carried over):**

Whatever debounce and press/release/held-edge behavior you built in
Lesson 07 must now apply independently to each of the 8 button bits, not
just one. A bounce or press on one button must not affect the debounced
state of any other button.

**Initialization:**

Everything needed to make the shift register readable (P2.3 direction and
idle level, USCI_B0 SPI master configuration) must be set up once, at
startup — not repeated on every read.

## Public Interface

```
input_init          ; no args. Configures P2.3 (PL) and USCI_B0 for the
                     ; shift register, plus whatever debounce state your
                     ; L07 input_init already initialized. Call once at
                     ; startup, before the first input_update.

input_read_raw       ; no args. Returns: R12 = instantaneous (non-debounced)
                     ; 8-bit button bitmap, 1 = pressed. Bit mapping:
                     ;   bit7 Up   bit6 Down  bit5 Left  bit4 Right
                     ;   bit3 Select  bit2 Start  bit1 B  bit0 A
                     ; This is the new raw-sample layer. Whatever debounce
                     ; entry point you built in L07 (call it by whatever
                     ; name you already gave it) should call this instead
                     ; of reading P1IN directly.
```

Keep whatever debounced/edge-detected public function names and argument
conventions you settled on in Lesson 07 — this milestone only changes
where the raw sample comes from, not the debounced API surface built on
top of it.

## Reference Material

- `docs/hardware/phase-3-buttons-shift-register.md` — wiring + bit mapping
- SLAU144 Ch 16 — USCI SPI master configuration
- Lesson 16 tutorials — the PL-pulse-then-shift protocol and the
  active-low inversion

## Success Criteria

- [ ] `input_init` configures the shift register once at startup
- [ ] `input_read_raw` returns a correct 8-bit bitmap matching the wiring's
      bit order — verify each of the 8 buttons independently lights only
      its own expected bit
- [ ] Your existing L07 debounce/edge-detection behavior still works,
      applied independently across all 8 bits (holding one button doesn't
      cause phantom presses on another)
- [ ] `handheld/main.s` still builds cleanly with this module included
