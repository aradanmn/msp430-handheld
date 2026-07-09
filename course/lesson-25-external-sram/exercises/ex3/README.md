# Exercise 3 — Milestone: `handheld/gfx/framebuf.s` → SRAM-Backed

This is a **conversion**, not a rewrite. `handheld/gfx/framebuf.s` already
exists from the Lesson 14 milestone, with a working pixel-level interface
backed by on-chip RAM. Your job this lesson is to move the pixel storage
onto the 23LC1024 SRAM chip (Tutorial 01's protocol) while keeping that
existing interface's **observable behavior** unchanged, and add one new
entry point that syncs only what's changed instead of the whole buffer
(Tutorial 02's dirty-region strategy).

Follow the project's established conventions:

- Public labels stay prefixed `framebuf_`; local labels use the `.L` prefix
  (CLAUDE.md's "Assembly File Conventions")
- Register usage follows `handheld/registers.md`
- `SRAM_CS` is P2.5 — define it locally in `framebuf.s` as you did in this
  lesson's exercises; it isn't in `msp430g2553-defs.s`

## Behavioral Spec

**Keep unchanged:** every pixel-level public function your Lesson 14
`framebuf.s` already exposes (a pixel-set function, a pixel-get function,
and whatever else you built) must continue to behave identically from a
caller's point of view — same function names, same argument registers, same
observable results. Nothing about calling those functions should look or
behave differently to code elsewhere in the handheld project just because
the bytes they touch now live in external SRAM instead of on-chip RAM.

**Add:** a new public entry point, **`framebuf_flush_dirty`**, that
transfers to the display only the region(s) of the framebuffer that have
actually changed since the last flush — not the entire buffer. You decide:
- The granularity of a "region" (a row, a fixed-size block, a set of tiles
  — your choice, and document what you chose and why in a comment)
- Whether `framebuf_flush_dirty` takes an argument (e.g., to flush one
  specific region) or takes none (flushes whatever is currently marked
  dirty) — either is acceptable; document which you chose
- How dirty state is tracked internally — this is exactly the kind of
  internal data structure decision left to you at this tier

**Requirement on the pixel-set path:** whatever function marks a pixel as
changed must also mark the region containing that pixel as dirty, so that
`framebuf_flush_dirty` has something correct to act on. How you represent
"dirty" is up to you.

**Requirement on `framebuf_flush_dirty`'s behavior:** after it returns, the
display must reflect every pixel change made since the previous flush.
Whether it also touches unchanged regions is not the point — the point is
that it must not need to re-transfer the *entire* buffer just because a
small part of it changed, once more than a trivial amount of the buffer is
already in sync.

## Integrating into `main.s`

`handheld/main.s` should call `framebuf_flush_dirty` wherever it currently
flushes the framebuffer to the display (if your Lesson 14/15 work already
established a per-frame flush call in the game loop, replace it with a call
to `framebuf_flush_dirty` — don't add a second, separate flush path).

## Success Criteria

- [ ] `handheld/gfx/framebuf.s` compiles cleanly as part of `handheld/`
- [ ] `cd handheld && make flash` builds and flashes
- [ ] Every pixel-level function that existed before this lesson still
      behaves the same way from a caller's perspective — no caller
      elsewhere in the project needs to change to accommodate this
      conversion
- [ ] `framebuf_flush_dirty` exists, is called from `main.s`'s game loop in
      place of any prior whole-buffer flush, and demonstrably updates the
      display correctly after a small, localized change (e.g., moving a
      single sprite one cell) without re-transferring the entire buffer
- [ ] `SRAM_CS` (P2.5) is defined locally as a `.equ`, with a comment noting
      it's a new pin assignment introduced by this lesson
- [ ] No leftover TODO comments in the submitted module
