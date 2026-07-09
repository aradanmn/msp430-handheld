# Tutorial 02 — Why the Framebuffer Moves Off-Chip, and the Dirty-Region Strategy

## The Budget Problem

The MSP430G2553 has 512 bytes of RAM, total. Not "512 bytes for graphics" —
512 bytes for *everything*: the stack, every local variable, every piece of
persistent ISR state (`handheld/registers.md`'s R4–R11 convention exists
precisely because RAM is scarce enough that keeping hot state in registers
instead of memory is a real win), the board array, input debounce state,
audio sequencer position, and whatever the framebuffer needs.

A monochrome OLED framebuffer needs one bit per pixel. Even a modest
128×64 display is 128 × 64 / 8 = 1024 bytes — already twice the *entire*
chip's RAM, before a single byte goes to anything else. This was
manageable back in Lesson 14 because the drawing primitives there only had
to prove out rectangles and lines conceptually; it stops being manageable
the moment the framebuffer has to hold a real, complete screen's worth of
pixels alongside everything else the running game needs. There is no
on-chip layout that fits both. The framebuffer has to live somewhere with
more room — the 23LC1024's 128 KB — and get shuttled to the display through
SPI instead of sitting in RAM the CPU can address directly.

## The Naive Approach, and Why It's Wasteful

The simplest possible sync strategy is: every frame, push the *entire*
framebuffer from SRAM to the display (or, if you're staging pixel edits in
SRAM before a display flush, from SRAM back out). That's correct, but it
pays a fixed cost per frame that has nothing to do with how much actually
changed. If Tetris drops one row of one piece this frame, and everything
else on screen is identical to last frame, a whole-buffer sync still moves
every single byte — most of which are unchanged from the last flush.

## SPI's Real Overhead: Per-Transaction, Not Per-Byte

Recall Tutorial 01: reading or writing the 23LC1024 costs one opcode byte
plus three address bytes *before* the first data byte ever moves. That
four-byte setup cost is paid once **per contiguous transaction** — once you
send the address and start reading or writing, subsequent bytes in the same
CS-low window are automatically the next bytes in memory order, with no
extra address bytes needed for each one. So:

- One transaction moving 200 contiguous bytes: 4 bytes of overhead, 200 of
  payload — overhead is 2% of the traffic.
- 200 separate one-byte transactions: 4 bytes of overhead *per byte*, 800
  overhead bytes for 200 payload bytes — overhead is 4× the payload.

This is the key fact that makes region-based syncing worth doing at all:
overhead is amortized well when you sync *contiguous runs*, and amortized
terribly when you sync scattered individual bytes. A dirty-region strategy
is really just an application of this one fact: group the pixels that
changed into the fewest, most contiguous transactions you reasonably can,
instead of either (a) one byte at a time, or (b) the whole buffer
regardless of how little changed.

## Tracking "What Changed"

The general shape of a dirty-region scheme: divide the framebuffer into
regions small enough that a typical frame only touches a handful of them
(a row, a tile, an 8×8 block — the granularity is a design choice), and
keep a compact record of which regions were written to since the last
flush. When it's time to sync, walk that record; for each region marked
dirty, sync just that region's bytes in one contiguous SPI transaction,
then clear its dirty marker.

Compare the two extremes concretely for a Tetris frame where one piece
moved down one row: a whole-buffer sync moves every byte of the display,
every frame, forever. A per-row dirty scheme (say) only re-syncs the one or
two rows the piece's old and new positions actually touch — the rest of
the board, which didn't change, costs nothing that frame. The savings scale
with how *idle* a typical frame is relative to the whole screen, which for
a game like Tetris — mostly static board, one small moving piece — is
usually most of the screen, most of the time.

## What This Means for `framebuf.s`

Before this lesson, every draw call could reasonably touch the framebuffer
directly and a display flush could reasonably push the whole thing — RAM is
fast, and the "SPI transaction" wasn't in the picture yet for pixel data.
Once the pixel store moves to SRAM, every read or write is now an SPI
transaction with the overhead structure described above, and pushing the
whole display's worth of bytes every frame is a real, measurable cost. This
is exactly why the milestone (Exercise 3) doesn't ask you to reimplement
`framebuf.s`'s pixel-level interface from scratch — it asks you to keep that
interface's *observable behavior* the same while changing where the bytes
live and adding a new entry point that flushes only what's changed. The
per-pixel calls a game update makes shouldn't need to know or care that the
backing store moved; only the flush step needs to get smarter.

## Check Your Understanding

1. If a single SPI transaction to the 23LC1024 costs 4 bytes of overhead
   before any data moves, why does that overhead matter more for many small
   transactions than for one large one?
2. Concretely, for one Tetris frame where a single piece moved one cell,
   what's the difference between a whole-buffer sync and a dirty-region
   sync, in terms of what actually travels over SPI?
3. Why doesn't the pixel-level API (`framebuf_set_pixel`,
   `framebuf_get_pixel`, or whatever you named yours in Lesson 14) need to
   change its observable behavior just because the backing store moved from
   on-chip RAM to external SRAM?
