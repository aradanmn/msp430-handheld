# Tutorial 01 — Memory Map & Register File

## The Memory Map

The MSP430G2553 has a single, flat 16-bit address space (addresses
`0x0000`–`0xFFFF`). There is no separate "code memory" vs "data memory"
instruction set the way some architectures split it — every address means
the same thing to every instruction — but the chip's actual physical memory
is carved into fixed regions, and where your program's pieces land depends
on which region they're linked into.

```
0xFFFF  ┌─────────────────────────────┐
        │  Interrupt Vector Table     │  16 vectors × 2 bytes = 32 bytes
0xFFE0  ├─────────────────────────────┤
        │                             │
        │  Flash — your program       │  16 KB total, 0xC000–0xFFFF
        │  (.text, .vectors)          │
        │                             │
0xC000  ├─────────────────────────────┤
        │        (unused gap)         │
0x10FF  ├─────────────────────────────┤
        │  Info Flash                 │  256 bytes, calibration constants
0x1000  ├─────────────────────────────┤
        │        (unused gap)         │
0x0400  ├─────────────────────────────┤
        │  RAM                        │  512 bytes, 0x0200–0x03FF
0x0200  ├─────────────────────────────┤
        │  Peripherals (8-bit)        │  0x0000–0x01FF, byte-addressable
0x0000  └─────────────────────────────┘
```

- **Flash — 16 KB, `0xC000`–`0xFFFF`.** This is where your assembled
  program lives permanently — it survives power loss. `make flash` writes
  your `.elf`'s code and the `.vectors` section into this region. Flash is
  read-only from the CPU's normal execution point of view (writing to it
  requires special unlock sequences you won't need until Lesson 15).

- **RAM — 512 bytes, `0x0200`–`0x03FF`.** Volatile read/write memory: your
  stack, and (starting in later lessons) any variables you store in memory
  rather than registers. 512 bytes is *small* — this is why the register
  allocation convention in `handheld/registers.md` favors keeping hot state
  in registers rather than RAM once the project grows.

- **Peripherals — `0x0000`–`0x01FF`, byte-addressable.** Every register
  you've seen in `msp430g2553-defs.s` (`P1DIR`, `WDTCTL`, `TACTL`, etc.) is
  just a memory address in this range. Writing to `&P1OUT` *is* writing to
  memory — the peripheral hardware watches that address and reacts.

- **Info Flash — 256 bytes, `0x1000`–`0x10FF`.** A small Flash region
  programmed once at the factory. It holds per-chip calibration constants —
  `CALBC1_1MHZ` at `0x10FF`, `CALDCO_1MHZ` at `0x10FE`, and similar pairs for
  8 MHz and 16 MHz. You'll read from these addresses in the DCO calibration
  sequence below, but you never write to them.

## The Register File

The MSP430 CPU has sixteen 16-bit registers, R0–R15. Four of them are
special-purpose; the rest are general-purpose scratch.

| Register | Name | Role |
|----------|------|------|
| R0 | **PC** — Program Counter | Address of the next instruction to fetch. Every jump, call, and `ret` is really just a write to PC. |
| R1 | **SP** — Stack Pointer | Address of the top of the stack. Decrements on `push`/`call`, increments on `pop`/`ret`. |
| R2 | **SR** — Status Register | CPU flags (Carry, Zero, Negative, Overflow) plus the low-power-mode control bits (GIE, CPUOFF, etc.) |
| R3 | **CG** — Constant Generator | A hardware trick — reading R3 in certain addressing modes produces one of several common constants (0, 1, 2, 4, 8, −1) without needing an extra instruction word. You don't write assembly that references R3 directly; the assembler picks the encoding for you when you write a small immediate. The full encoding table is Lesson 04's job — for now, just know R3 is reserved and isn't a scratch register. |
| R4–R15 | General purpose | Yours to use. This course's convention (`handheld/registers.md`) reserves R4–R11 for persistent state and R12–R15 for scratch/arguments once the project grows an ISR — not required for this lesson's single-loop program, but good to see coming. |

## Why SP Must Be Set to `0x0400` First

RAM spans `0x0200`–`0x03FF`. The stack grows **downward** — each `push` or
`call` decrements SP before storing, so the very first thing pushed lands
just below wherever SP currently points. `0x0400` is one byte past the top
of RAM, so the first push lands at `0x03FE`, safely inside RAM.

On reset, SP does not initialize itself to anything useful — it's
undefined until you set it. If you called a subroutine (or an interrupt
fired) before SP were initialized, the `call` instruction would push the
return address to whatever garbage address SP happened to hold, most likely
corrupting a peripheral register or Flash-adjacent memory instead of RAM.
That's why

```asm
mov.w   #0x0400, SP
```

is the *first* instruction in every `_start` in this course, before even
the watchdog is touched.

## Worked Scenario: What Happens If You Forget `WDTHOLD`?

The Watchdog Timer (WDT) is running the moment the chip powers up, in
watchdog mode, counting down on its default clock. If nothing ever holds it,
it reaches zero and forces a full chip reset — SLAU144 Ch. 3 covers the
WDT+ module's reset behavior in detail. The default interval is short
(well under a second at the default settings), so an unheld watchdog doesn't
crash your program with an obvious error message — it just resets the chip
partway through, over and over. The *observable symptom* is a program that
appears to restart on its own: LEDs that never get past their init sequence,
a blink pattern that "resets" partway through, or — worst case — a program
that looks like it works for the first fraction of a second and then goes
back to the beginning. If you ever see behavior like that later in the
course, the watchdog is one of the first things worth checking.

The fix is the second instruction in every `_start`:

```asm
mov.w   #(WDTPW|WDTHOLD), &WDTCTL
```

## The WDTPW Password Mechanism

`WDTCTL` is a 16-bit register, but it's split in half: the **upper byte is a
write password**, and the **lower byte holds the actual control bits**
(including `WDTHOLD`, bit 7 of the lower byte). Any write to `WDTCTL` that
doesn't have `0x5A` in the upper byte is rejected by hardware, and — because
this is a safety mechanism — a bad password doesn't just get ignored, it
triggers an **immediate reset**. This exists so that a runaway program
(corrupted PC jumping into random memory) can't accidentally disable the
watchdog by writing the wrong bit pattern to `WDTCTL` and getting lucky.

`WDTPW` is defined in `msp430g2553-defs.s` as `0x5A00` — the password already
shifted into the upper byte. `WDTHOLD` is `0x0080` — bit 7 of the lower
byte. OR them together and you get `0x5A80`, which both authenticates the
write *and* sets the hold bit in the same instruction:

```
  0x5A00  =  0101 1010  0000 0000    (password, upper byte)
| 0x0080  =  0000 0000  1000 0000    (WDTHOLD, bit 7 of lower byte)
-----------------------------------
  0x5A80  =  0101 1010  1000 0000
```

Every future write to `WDTCTL` in this course (e.g. reconfiguring the
watchdog as an interval timer in Lesson 11) must **also** include `WDTPW`,
every single time — the password isn't a one-time unlock, it's required on
every write.

## DCO Calibration: Why Order Matters

The DCO (Digitally Controlled Oscillator) is the chip's default clock
source, and it is *not* precise out of reset — its frequency depends on
manufacturing variance and would drift from chip to chip if left
uncalibrated. TI measures each chip at the factory and burns two correction
values into Info Flash: a coarse "range" byte (loaded into `BCSCTL1`) and a
fine "tuning" byte (loaded into `DCOCTL`). The pair at `0x10FF`/`0x10FE`
calibrates to exactly 1 MHz; other pairs (`CALBC1_8MHZ`/`CALDCO_8MHZ`, etc.)
calibrate to other speeds.

The calibration sequence is always three instructions, in this order:

```asm
clr.b   &DCOCTL                     ; 1. clear fine-tune FIRST
mov.b   &CALBC1_1MHZ, &BCSCTL1      ; 2. load coarse range
mov.b   &CALDCO_1MHZ, &DCOCTL       ; 3. load fine-tune
```

Step 1 exists to avoid a transient glitch: `BCSCTL1`'s coarse range bits and
`DCOCTL`'s fine-tune bits jointly determine the DCO's output frequency. If
you loaded the new coarse range while the *old* (possibly very different)
fine-tune value was still sitting in `DCOCTL`, the DCO would briefly run at
whatever frequency that mismatched combination produces — for one or more
clock cycles, however brief, before the fine-tune load in step 3 corrects
it. Clearing `DCOCTL` first means the coarse-range load in step 2 always
combines with a known, quiet value (0), so there's no intermediate
mismatched state. Once all three instructions have run, the CPU is running
at a precisely calibrated 1 MHz — the number every delay-loop cycle count
in this course assumes.

See `course/common/glossary.md` for quick definitions of DCO, MCLK, SMCLK,
ACLK, and other clock-related terms used above.
