---
# yaml-language-server: $schema=../../.lore/schemas/epic.schema.json
type: Epic
title: Formal verification skills
tags:
  - formal-methods
  - skills
summary: Reusable Claude Code skills that find, fix, and simplify concurrency, data-flow, state, and graph bugs in any codebase with TLA+ and Lean 4, and publish the results as Artifact reports.
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:23:36.472Z
---

# Formal verification skills

## Goal

Make formal methods a routine bug-finding tool for any codebase. An agent should be able to
take a module it has never seen, model the risky part in TLA+ or Lean 4, find the
interleaving or input that breaks it, prove the finding against the real code, fix it,
re-verify, and hand the user a report they can share. The same proofs should then pay for
themselves a second time, by showing which defensive code can be deleted.

Inspiration: Boris Cherny's September 2026 report of using Claude with Lean to formally
verify the Claude Agent SDK. A few short prompts produced 16 PRs fixing bugs and race
conditions, and he sometimes combines Lean with TLA+ for data-flow, concurrency, and
state-management issues. That was one example; these skills are general-purpose. See
[State of the art](../reference/state-of-the-art-in-agent-driven-formal-verification.md).

## Scope

In scope:
- Bug classes:
  - races and check-then-act,
  - async/await interleavings,
  - retries and idempotency,
  - leases and fencing,
  - message loss, duplication, and reordering,
  - deadlock and lost wakeups,
  - dataflow loss and stalls,
  - state-machine transitions,
  - graph and DAG properties.
- Any implementation language: the models are language-neutral, and reproduction guidance
  covers Python, TypeScript, Go, Rust, JVM, C/C++, and distributed services.
- Eight workflows, from bug hunt to CI guard ([Workflows W1–W8](../reference/workflows-w1-w8.md)).
- Proof-guided simplification of existing code.
- Artifact reports as the user-facing output.

Out of scope:
- Full functional verification of large codebases.
- Performance and resource bugs.
- Proofs of the compiler or runtime.

## Stories

| Story | Delivers |
|---|---|
| [formal-verify orchestrator skill](../stories/formal-verify-orchestrator-skill.md) | End-to-end workflow, correspondence, reproduction, reporting |
| [tlaplus-model skill](../stories/tlaplus-model-skill.md) | TLA+/PlusCal/Quint modeling and checking with seven verified patterns |
| [lean-model skill](../stories/lean-model-skill.md) | Lean 4 models, bounded refutation, inductive proofs, trust audit |
| [proof-simplify skill](../stories/proof-simplify-skill.md) | Turning proven facts into safe deletions |
| [Artifact verification reports](../stories/artifact-verification-reports.md) | findings.json and the Artifact report contract |
| [Skill evaluation suite](../stories/skill-evaluation-suite.md) | Fixtures, eval prompts, with/without-skill benchmark |

## Status

All six stories are done: Quest tasks PS-1 to PS-8, rolled up by `lore sync`. The plugin
is at v0.1.0. It is owned by Opum AI and MIT-licensed; its source is the public repo
[opum-ai/proof-skills](https://github.com/opum-ai/proof-skills), and it is distributed
through Opum AI's public [opum marketplace](https://github.com/opum-ai/opum-marketplace)
(see ADR 0006).

Open follow-ups, all found by the evals:

| Task | Follow-up |
|---|---|
| PS-9 | Improve recall on the four missed trigger queries |
| PS-10 | Grade bug-hunt evidence from files, not only the final message |
| PS-11 | Make git usable inside `claude plugin eval` runs on macOS |
| PS-12 | Close the depth gap between plugin-eval and skill-creator runs |

## Decisions

- [ADR 0001: four skills with an orchestrator](../adr/0001-split-into-four-skills-with-an-orchestrator.md)
- [ADR 0002: findings.json drives Artifact reports](../adr/0002-findings-json-drives-artifact-reports.md)
- [ADR 0003: three-config sanity pattern](../adr/0003-three-config-sanity-pattern-for-every-model.md)
- [ADR 0004: core Lean, no Mathlib; user-cache toolchains](../adr/0004-core-lean-without-mathlib-and-user-cache-toolchains.md)
- [ADR 0005: plugin marketplace distribution](../adr/0005-distribute-as-a-claude-code-plugin-marketplace.md) (superseded by 0006)
- [ADR 0006: distribute through the opum marketplace](../adr/0006-distribute-through-the-opum-marketplace.md)
