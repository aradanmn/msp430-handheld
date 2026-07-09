# Tutorial 02 — Toolchain & Build

## The Toolchain

Every `.s` file in this course is assembled and linked by a single
command, `msp430-elf-gcc`, invoked through a `Makefile`. Even though your
source files are hand-written assembly, not C, we still go through GCC
rather than calling the assembler (`as`) and linker (`ld`) directly —
GCC's `-x assembler-with-cpp` flag tells it "treat this input as assembly,
but run the C preprocessor over it first." That's what makes `#include
"../../common/msp430g2553-defs.s"` work: it's a preprocessor directive, not
a GAS directive, and it's resolved before the assembler ever sees the file.

The other flags that matter, all defined once in
`course/common/Makefile.template` and inherited by every lesson's
Makefile:

- **`-mmcu=msp430g2553`** — tells GCC which chip variant it's targeting
  (register layout, available peripherals, memory size).
- **`-nostdlib`** — don't link any C standard library or runtime startup
  code. There is no `main()` here, no libc, nothing but your `_start` and
  the vector table. This is why every file in this course defines its own
  `_start` and initializes its own stack pointer by hand — there's no
  runtime doing it for you first.
- **`-Wl,-T,.../msp430g2553.ld`** — passes a **device-specific linker
  script** to the linker. This script is what actually assigns your `.text`
  section to the Flash address range and your uninitialized data to RAM —
  it encodes the memory map from Tutorial 01 so you don't have to specify
  addresses by hand for ordinary code.
- **`-Wl,--section-start=.vectors=0xFFE0`** — forces the `.vectors` section
  specifically to start at address `0xFFE0`, overriding wherever the linker
  script would otherwise have placed it. More on why below.

## Makefile Targets

Every `examples/` and `exercises/exN/` directory has its own `Makefile`,
copied from `course/common/Makefile.template` with only the `TARGET` line
changed to that directory's `.s` filename stem. Four targets:

```sh
make          # assemble + link → produces TARGET.elf
make flash    # build, then write TARGET.elf to the LaunchPad over USB
make disasm   # build, then disassemble TARGET.elf (see the actual machine code)
make clean    # remove TARGET.elf
```

`make flash` shells out to `mspdebug`, using the `tilib` driver (TI's
library for talking to the eZ-FET lite debugger built into the LaunchPad)
and pointing `DYLD_LIBRARY_PATH` at `~/.local/lib`, where `libmsp430.dylib`
was built during setup. The full command the Makefile runs is effectively:

```sh
DYLD_LIBRARY_PATH=~/.local/lib mspdebug tilib "prog blink.elf"
```

**First-ever flash on a fresh LaunchPad** needs one extra flag to update
the eZ-FET's onboard firmware before it can program anything:

```sh
DYLD_LIBRARY_PATH=~/.local/lib mspdebug --allow-fw-update tilib "prog blink.elf"
```

You only need `--allow-fw-update` once per LaunchPad (or after a firmware
regression) — the plain `make flash` target is what you'll use every time
after that.

## The `.vectors` Section and Why It's Pinned to `0xFFE0`

The MSP430 interrupt vector table is 16 entries of 2 bytes each — 32 bytes
total — occupying the very last 32 bytes of the address space,
`0xFFE0`–`0xFFFF`. This isn't a convention or a linker default; it's fixed
in hardware. When *any* interrupt (or reset) occurs, the CPU hardware reads
a fixed offset within that 32-byte range and loads whatever 16-bit value it
finds there directly into PC. For the reset vector specifically, that fixed
address is `0xFFFE` — the very last two bytes of address space.

Because this address is dictated by silicon, not by us, the linker can't be
allowed to place `.vectors` wherever it finds free space the way it would
an ordinary section — it must go exactly at `0xFFE0`. That's what
`--section-start=.vectors=0xFFE0` guarantees: no matter how the rest of
your code is laid out in Flash, the 16-word vector table lands at the one
address the hardware will actually look at.

## Power-Up, Traced End to End

Here's what happens between "you press the button on the LaunchPad power
strip" and "your code starts running":

1. **Reset.** Power-on (or a watchdog timeout, or the RST/NMI pin) puts the
   CPU into a defined reset state and clears PC.
2. **Hardware reads the reset vector.** The CPU reads the 16-bit value
   stored at address `0xFFFE` — the last entry of the `.vectors` table you
   linked in.
3. **That value is loaded into PC.** In every program in this course, the
   value stored at `0xFFFE` is the address of the `_start` label — the
   `.word _start` line in your vectors section is literally what tells the
   hardware where to begin.
4. **Execution begins at `_start`.** The CPU starts fetching and executing
   instructions from that address — which is why `_start` always begins
   with SP init, watchdog hold, and DCO calibration: nothing else has run
   yet, so nothing else can be assumed to be in a safe state.

## Worked Scenario: Edit → Build → Flash → Power Cycle

Walking through a concrete edit-test loop, using `examples/blink.s` as the
example:

1. **You edit `blink.s`** — say, changing a delay constant — and save.
2. **`make`** invokes `msp430-elf-gcc` with the flags above. GCC's
   preprocessor pulls in `msp430g2553-defs.s` via the `#include`, GAS
   assembles the result into machine code, and the linker places your
   `.text` code somewhere in the `0xC000`–`0xFFFF` Flash range (wherever the
   linker script's default `.text` placement puts it — typically starting
   at `0xC000` unless the code is large enough to need adjusting) and your
   `.vectors` section at exactly `0xFFE0`, producing `blink.elf`.
3. **`make flash`** rebuilds if needed, then invokes `mspdebug tilib "prog
   blink.elf"`. `mspdebug` talks to the eZ-FET lite debugger over USB, which
   erases the relevant Flash pages and writes your new `.elf`'s contents
   into them — including the vector table at `0xFFE0`–`0xFFFF`.
4. **Power cycle.** Unplug the USB cable (or press the on-board reset
   button) and reconnect. The sequence in the previous section runs: CPU
   resets, reads `0xFFFE`, jumps to `_start`, and your freshly-flashed
   program starts running — entirely independent of whether a debugger is
   still attached, because the program now lives permanently in Flash.

If you want to see exactly what got placed where, `make disasm` runs
`objdump -d` on the `.elf` and prints every instruction next to its actual
Flash address, including the vector table entries at the end.

See `course/common/glossary.md` for definitions of GAS, ELF, eZ-FET, and
other toolchain terms used above.
