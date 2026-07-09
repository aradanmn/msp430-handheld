# Tutorial 02 — Persisting a High Score in Flash, and Sleeping Deeper with LPM3

This lesson's two remaining topics are independent of each other and of
Tutorial 01's state machine — they can be read (and built) in either order.

---

## Part A — Writing to Info Flash

### Why This Is New

Every constant this course has *read* from Info Flash — `CALBC1_1MHZ`,
`CALDCO_1MHZ`, and friends — was an ordinary memory read: `mov.b
&CALBC1_1MHZ, &BCSCTL1` needs no special sequence, because reading Flash
works exactly like reading RAM. **Writing** to Flash does not. Flash memory
is physically incapable of being rewritten with a simple `mov` — a location
has to be electrically erased before new data can be written into it, and
both operations are driven by a dedicated on-chip peripheral: the **Flash
Memory Controller** (SLAU144 Chapter 5), which this course hasn't needed
until now because nothing before this lesson needed to persist data across
a power cycle.

### The Registers

None of these are in `msp430g2553-defs.s` — add them yourself as local
`.equ`s, citing SLAU144 Chapter 5:

| Register | Address | Relevant bits |
|----------|---------|---------------|
| `FCTL1` | `0x0128` | bit 1 `ERASE` (segment erase), bit 2 `MERAS` (mass erase), bit 6 `WRT` (write) |
| `FCTL2` | `0x012A` | clock select/divider for the Flash timing generator |
| `FCTL3` | `0x012C` | bit 0 `BUSY` (1 while an erase/write is in progress), bit 3 `LOCK` (must be cleared before erase/write, set again after) |

Exactly like `WDTCTL`'s `WDTPW`, every write to any of these three
registers must carry a password in its upper byte or the write is silently
ignored: `FWKEY = 0xA500`. This is the same pattern you've used since
Lesson 01 — `#(WDTPW|WDTHOLD)` — applied to a different peripheral.

### The Sequence, Conceptually

Writing or erasing Flash always follows the same shape:

1. **Unlock:** clear `LOCK` in `FCTL3` (with `FWKEY` in the upper byte)
2. **Select the operation:** set `ERASE` in `FCTL1` for a segment erase, or
   `WRT` in `FCTL1` for a write (both writes carry `FWKEY`)
3. **Perform the operation:** for an erase, a dummy write to any address in
   the target segment triggers the erase; for a byte/word write, an
   ordinary-looking `mov` to the target Flash address actually programs
   that location while `WRT` is set
4. **Wait:** poll `FCTL3`'s `BUSY` bit until it clears — the operation
   takes measurably longer than a RAM write
5. **Clean up:** clear `WRT`/`ERASE` in `FCTL1`, then set `LOCK` again in
   `FCTL3`

This is the conceptual shape you'll implement in the milestone. It is
*not* worked out in full in this tutorial, and there is no working
erase/write code in this lesson's example — see the safety note below.

### Segment D Only — This Cannot Be Restated Too Many Times

Info Flash is 256 bytes total (`0x1000`–`0x10FF`), organized as four 64-byte
segments. The top segment (conventionally "Segment A,"
`0x10C0`–`0x10FF`) holds `CALBC1_1MHZ`, `CALDCO_1MHZ`, and the other DCO
calibration bytes every lesson's `_start` in this entire course relies on.
**Erasing a segment erases the whole 64-byte segment, not just the byte you
meant to change** — there's no such thing as erasing one byte in isolation.
If Segment A gets erased, the board's factory DCO calibration is gone,
permanently, and every program in this course that calibrates the DCO in
`_start` stops working correctly on that chip.

The milestone's high score lives in **Segment D** (`0x1000`–`0x103F`) — the
lowest segment, as far from the calibration data as this memory gets.
Never construct an address at or above `0x10C0` in any erase/write path.

### Why the Example Doesn't Write Flash

`examples/flash_and_lpm3_demo.s` only **reads** a byte from `0x1000` — an
ordinary memory access, no unlock sequence, no risk. The actual
erase/write sequence is real, working code you write yourself in the
milestone, with the safety constraint above foremost in mind. This isn't a
simplification for its own sake — it's the same judgment call this course
has made before (Lesson 06's exercises don't hand you working debounce
code either): the working demonstration stays safe, and the first time you
write genuinely risky code, it's code you understand because you wrote it
against a spec, not code you copied.

---

## Part B — LPM3 and the VLO

### LPM0 vs. LPM3

Recall the low-power mode bits from `msp430g2553-defs.s` (Lesson 11):

```
LPM0_bits = CPUOFF                     ; CPU off, all clocks keep running
LPM3_bits = SCG1|SCG0|CPUOFF            ; CPU + DCO + SMCLK off, ACLK still runs
```

Every game tick since Lesson 11 has used LPM0 between ticks: the CPU stops
fetching instructions, but the DCO stays running and SMCLK keeps clocking
Timer_A, so the tick timer's CC0 interrupt fires on schedule and wakes the
CPU right on time. That's correct, but it isn't the deepest sleep
available for a workload that only needs a slow, periodic wake — the DCO
running continuously is real, avoidable current draw.

LPM3 turns off the DCO and SMCLK entirely (`SCG0` and `SCG1` both set) and
leaves only `ACLK` running. If the tick timer can be moved onto `ACLK`
instead of `SMCLK`, the CPU can sleep in LPM3 between ticks instead of
LPM0 — same wake-up guarantee, deeper sleep, lower average current. A
Tetris tick doesn't need SMCLK's speed or precision; it needs *a* periodic
wake, which `ACLK` provides perfectly well.

### The Problem: This Board Has No Crystal

`ACLK` is documented (Lesson 08, `msp430g2553-defs.s`) as normally coming
from a 32 kHz crystal on the `LFXT1` pins. The MSP-EXP430G2 LaunchPad this
course targets **does not have that crystal populated** — there's nowhere
for `ACLK` to get a real signal from unless you tell it to use something
else.

The "something else" is the **VLO** (Very-Low-power Oscillator): an
internal, uncalibrated ~12 kHz clock source built into the chip
specifically for cases like this. `BCSCTL3`'s `LFXT1S` field (bits 5-4) —
already declared in `msp430g2553-defs.s` as the register, but *not* with
this field broken out — selects `ACLK`'s low-frequency source:

```asm
.equ    LFXT1S_3,   0x30      ; BCSCTL3 bits 5-4 = 11 -> ACLK sourced from VLOCLK
                               ; (new this lesson — SLAU144's Basic Clock
                               ;  System chapter; not in msp430g2553-defs.s)

bis.b   #LFXT1S_3, &BCSCTL3   ; ACLK now runs from the internal ~12 kHz VLO
```

Without this, `BCSCTL3`'s default `LFXT1S` selection assumes a crystal that
isn't there, and `ACLK` will not behave the way SLAU144's LPM3 description
assumes — which is exactly the kind of thing that makes LPM3 "mostly work"
in a way that's hard to debug rather than fail outright. Set it explicitly.

### The Precision Trade-off

The VLO is **not calibrated** the way the DCO is (there's no
`CALBC1`-style Info Flash constant for it) — its actual frequency varies
chip to chip and with temperature, typically somewhere around 4–20 kHz
depending on the specific part and conditions, nominally ~12 kHz. That's
fine for "wake roughly once per game tick" — a few percent of drift on a
100 ms tick is imperceptible in a Tetris game — but it's not the kind of
precision this course has relied on for UART baud rates or PWM tone
frequencies. Use `ACLK`/VLO for the tick that drives LPM3 sleep; don't
assume it gives you the same precision `SMCLK`/DCO did for those other
peripherals.

## Check Your Understanding

1. Why does erasing one byte's segment risk more than that one byte?
2. What specific consequence would erasing Segment A have on every
   previous lesson in this course, and why?
3. Which SR bits differ between `LPM0_bits` and `LPM3_bits`, and which
   clocks does each of those bits actually gate?
4. Why doesn't this course's earlier reliance on `ACLK` (if any) reveal the
   missing-crystal problem the way LPM3 does?
