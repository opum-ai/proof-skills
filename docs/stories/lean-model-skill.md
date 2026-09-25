---
type: Story
title: lean-model skill
tags:
  - skills
summary: Lean 4 modeling skill — step-relation models with executable twins, BFS counterexamples turned into theorems, inductive invariant proofs, trust audit, differential testing; nine verified patterns.
tasks:
  - ps-3
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:12.713Z
lore_task_status: done
---

# lean-model skill

## Goal

Give an agent a dependency-light Lean 4 kit to do three things:
- **refute fast:** bounded search, and a counterexample that is itself a theorem;
- **prove for all sizes:** an inductive invariant, lifted over reachability;
- **stay honest:** a trust audit, a non-vacuity witness, and differential testing against production.

Location: `plugins/proof-skills/skills/lean-model/`.

## Acceptance criteria

- [x] `scripts/setup_lean.sh` (elan, no sudo) and `scripts/new_project.sh`. The scaffolded
  template builds and passes the trust audit.
- [x] `scripts/check_trust.sh` does four things:
  - scans the source for sorry, admit, axiom, and native_decide;
  - builds the project;
  - audits the axioms of every theorem over the compiled environment;
  - emits JSON for findings.

  It exits 1 on `sorry`; this was tested.
- [x] `Explore.lean` provides `Reach`, `Reach.inv`, `bfs` with labeled traces, and
  `validPath_reach`, which turns a trace into a theorem.
- [x] Nine patterns: Counter, Idempotency, Queue, Pipeline, Graph, StateMachine,
  DagScheduler, RedundantGuard, and a Replay executable. They build on Lean 4.34.0:
  24 theorems, 0 sorry, standard axioms only ([Lean pattern catalog](../reference/lean-pattern-catalog.md)).
- [x] The references cover patterns, proving (including the invariant-strengthening loop),
  pitfalls, differential testing, and setup.

## Tasks

<!-- lore:tasks:begin -->
| Task | Title | Status |
|---|---|---|
| [PS-3](../../.quest/completed/PS-3.json) | Build lean-model skill | Done |
<!-- lore:tasks:end -->

## Notes

Toolchain choice: [ADR 0004](../adr/0004-core-lean-without-mathlib-and-user-cache-toolchains.md).
The research agent confirmed that a Mathlib project needs about 7.9 GB of `.lake` cache,
while the template needs only core Lean plus plausible.
