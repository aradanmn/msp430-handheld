# Lesson 02 Exercises

Two exercises this lesson — no milestone yet (the first `handheld/` milestone
starts at Lesson 07).

## Exercise 1 — Explore: Arithmetic patterns

**File:** `ex1/arithmetic_patterns.s`

Derive an LED display pattern using `ADD` and a bitmask (`AND`), rather than
walking a table. The starter has boilerplate plus `P1DIR` already configured
for LED1/LED2 — the task itself is stated as a comment in the file.

**Success criteria:**

- [ ] LED1 and LED2 together visibly display a 2-bit binary count: `00 → 01
      → 10 → 11 → 00 → ...`
- [ ] The count advances once every ~300 ms, indefinitely
- [ ] The increment/wrap logic is built with `ADD` and a mask — not four
      hardcoded `bis.b`/`bic.b` blocks, one per count value
- [ ] No leftover `TODO` comments in the file you submit

## Exercise 2 — Challenge: Addressing-mode puzzle

**File:** `ex2/addressing_puzzle.s`

This is a design constraint, not a bug hunt — the starter file compiles and
runs (it just sits at reset with LEDs off). The constraint is stated as a
comment in the file.

**Success criteria:**

- [ ] The LEDs visibly cycle through 5 or more distinct, fixed states, in a
      repeating order, forever
- [ ] No more than one instruction referencing `&P1OUT` executes per
      pattern-step
- [ ] No more than one absolute/symbolic table-base reference appears
      anywhere in the program — every other table access is computed from a
      register via indexed or indirect addressing
- [ ] You can point to the single pointer register that selects each table
      entry when asked to explain your own source
- [ ] No leftover `TODO` comments in the file you submit
