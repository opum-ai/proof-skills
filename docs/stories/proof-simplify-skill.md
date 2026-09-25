---
type: Story
title: proof-simplify skill
tags:
  - skills
summary: Proof-guided simplification skill — harvest candidates, prove each deletion safe (re-check, guard implication, refinement, reachable-state equivalence), audit assumptions, apply one change at a time.
tasks:
  - ps-4
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:12.798Z
lore_task_status: done
---

# proof-simplify skill

## Goal

Turn verified models into smaller, clearer code, without trading away safety. Code written
without proofs defends against states that cannot happen. Once a model proves what is always
true, those defenses can go, provided the proof and its assumptions really cover them.

Location: `plugins/proof-skills/skills/proof-simplify/`.

## Acceptance criteria

- [x] Preconditions are stated: a passing model, frozen properties, completed sanity
  checks, and CORRESPONDENCE with its assumptions. Without them, hand off to formal-verify.
- [x] Catalog of eight candidate kinds, each with signal, justification, typical change, and "stop short when".
- [x] Equivalence techniques ranked by strength, with verified templates.
- [x] Assumption audit: each candidate is removed, downgraded to an assertion, or kept.
  Trust-boundary validation is never removed on the strength of internal invariants.
- [x] Verified TLA+ example, `CancelOrder`:
  - the lock alone fails (exit 13),
  - CAS alone passes,
  - the simplified spec refines the current one, and
  - a mutated simplified spec (no CAS) fails.
- [x] Verified Lean example, `RedundantGuard`: `guard_implied` and `reach_iff`.

## Tasks

<!-- lore:tasks:begin -->
| Task | Title | Status |
|---|---|---|
| [PS-4](../../.quest/completed/PS-4.json) | Build proof-simplify skill | Done |
<!-- lore:tasks:end -->

## Notes

This is workflow W4 in [Workflows W1–W8](../reference/workflows-w1-w8.md). A refinement
check preserves safety only, so the skill requires liveness to be re-checked separately.
