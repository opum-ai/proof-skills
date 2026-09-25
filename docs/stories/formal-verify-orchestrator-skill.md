---
type: Story
title: formal-verify orchestrator skill
tags:
  - skills
summary: "End-to-end workflow skill: scope, freeze properties, map model to code, check, reproduce counterexamples, fix, re-verify, publish an Artifact report."
tasks:
  - ps-1
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:23:36.553Z
lore_task_status: done
---

# formal-verify orchestrator skill

## Goal

Be the one entry point a user reaches for, even when they say only "can this race?" or
"why do we double-charge?". The skill owns the parts of formal verification that decide
whether it succeeds in practice:
- choosing what to model,
- keeping the model faithful to the code,
- refusing to call a counterexample a bug until it reproduces, and
- reporting what was and was not checked.

It routes the tool-specific work to [tlaplus-model](tlaplus-model-skill.md),
[lean-model](lean-model-skill.md), and [proof-simplify](proof-simplify-skill.md).

Location: `plugins/proof-skills/skills/formal-verify/`.

## Acceptance criteria

- [x] SKILL.md picks one of the eight workflows from the user's words ([Workflows W1–W8](../reference/workflows-w1-w8.md)).
- [x] The W1 core loop has eight steps, and each step's reason is stated:
  scope, harvest and freeze properties, choose the tool, the correspondence map, model and
  sanity-check, reproduce, fix and mutation-check, report.
- [x] Guidance for choosing tools covers TLA+, Lean, Quint/Apalache, and the cases where
  formal methods are the wrong tool (`references/choosing-tools.md`).
- [x] Correspondence-map format and template, with `src:` tags; `scripts/correspondence_check.py`
  detects missing files and line ranges past the end of a file. Tested: 3 of 3 broken
  pointers were caught in a fixture.
- [x] A per-runtime reproduction table (Python asyncio and threads, Node, Go, JVM, Rust,
  C/C++, distributed systems, databases) and the confirmed/suspected/refuted verdicts.
- [x] Report contract and `assets/findings.schema.json`; publishing via the Artifact tool,
  after loading `artifact-design` and `artifact-diagramming`.
- [x] CI templates for TLA+ and Lean, bug-mode configs that must fail, and drift detection
  (`references/ci-and-drift.md`).
- [x] `scripts/doctor.sh` reports which toolchains are available and writes nothing.
- [x] Honesty rules: state bounds, never claim a bug without reproduction, flag every model weakening.

## Tasks

<!-- lore:tasks:begin -->
| Task | Title | Status |
|---|---|---|
| [PS-1](../../.quest/completed/PS-1.json) | Build formal-verify orchestrator skill | Done |
<!-- lore:tasks:end -->

## Notes

Design rationale: [ADR 0001](../adr/0001-split-into-four-skills-with-an-orchestrator.md).
The eight-step loop follows the published evidence that runtime feedback and reproduction,
not TLA+ fluency, are what find real bugs (Specula 2026; see
[State of the art](../reference/state-of-the-art-in-agent-driven-formal-verification.md)).
