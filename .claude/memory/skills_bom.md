---
name: skills_bom
description: bom skill exists for maintaining flat/structured BOM files on this project
type: project
---

A `/bom` skill is installed at the skills-plugin path. It maintains three files:
- bom-flat.md — single-level, aggregate quantities, procurement-focused
- bom-structured.md — L0/L1/L2 hierarchy, per-parent quantities, engineering-focused
- bom-order.csv — ordering sheet matching flat BOM item numbers

**Note (repo split 2026-07-21):** these BOM files now live in the separate hardware repo github.com/aradanmn/MSP430handheld-hardware (at its root), not in this software repo. Run the bom skill against that repo.

**How to apply:** When the user asks to add/remove/change parts or says "/bom", use the bom skill. It reads existing files first, understands the change, and updates all three files consistently in one pass.
