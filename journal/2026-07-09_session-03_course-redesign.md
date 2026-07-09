# Session 03 — Course Redesign: 16-Lesson Map → 26-Lesson Map
_Date: 2026-07-09_

## What Prompted This

A review of the course against five criteria (real topic per lesson, working
example code, thinking-focused exercises, reinforcing challenges, handheld
scaffolding) found that only Lessons 01–06 had ever been authored, despite
`CLAUDE.md` promising 16 lessons and `ROADMAP.md` promising 20 — and the two
documents disagreed with each other on lesson numbering. The six lessons that
did exist were solid (convention-correct working code, question-driven
exercises, real handheld milestones), but the repo as a whole had:

- Three different lesson maps that didn't agree (ROADMAP vs CLAUDE.md vs disk)
- Forbidden `solution/` directories in `review-01-02/` (policy says these
  must not exist)
- A stray committed objdump dump (`lesson-02/.../ex1.asm`) leaking a local
  path from a previous student's machine
- `; BUG 1/2/3` inline answer-leaks inside the "find the bug" Ex2 challenges
- Drifting forward-reference tables between lesson READMEs

## What Was Done

Full course rewrite, this time as a single consistent 26-lesson plan across
five parts (Assembly Foundations → Timing & Interrupts → Display Pipeline →
Input & Audio → The Game). Removed all six old lesson directories,
`review-01-02/`, and the four old `grades/*.md` files. Rewrote `CLAUDE.md`
(Course Structure, Course Map, Exercise Format Policy references, Student
Progress), `ROADMAP.md`, and `README.md` to agree on the same 26 lessons.

Kept as reusable infrastructure: `course/common/` (defs, glossary, Makefile
template), `docs/` (BOM + hardware phase guides — still hardware-accurate),
and the `handheld/` skeleton. `handheld/hal/leds.s` predates the milestone
scheme and is kept as a working reference module (GPIO output no longer has
a formal Ex3 milestone in the new map — the first milestone is L07's
`hal/input.s`).

## Current State

Student progress reset to a clean slate. Starting over at Lesson 01 under
the new map. See `CLAUDE.md`'s Course Map for the full 26-lesson plan.
