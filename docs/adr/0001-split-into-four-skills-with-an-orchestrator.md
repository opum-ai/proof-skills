---
# yaml-language-server: $schema=../../.lore/schemas/adr.schema.json
type: ADR
title: Split into four skills with an orchestrator
summary: "Ship one orchestrator skill (formal-verify) plus three tool/workflow skills (tlaplus-model, lean-model, proof-simplify) instead of one monolith or two tool-only skills."
tags:
  - architecture
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:23:36.635Z
---

# Split into four skills with an orchestrator

## Status

Accepted (2026-09-22)

## Context

The first request was for two skills, "Lean" and "TLA+". Two further requests followed:
simplify code using the proofs, and cover every workflow end to end. Several things follow
from those requests:
- Most of what makes formal verification succeed has nothing to do with the tool: scoping,
  property harvesting, the model-to-code correspondence, reproduction, and reporting. Two
  tool-only skills would each have to duplicate those parts, or skip them.
- Skills trigger from their descriptions. A single giant skill would carry a vague
  description and a SKILL.md far over the 500-line guidance.
- Users arrive with different intents: "find the race", "prove this for all N", "can we
  delete this lock", "explain this TLC trace", "add the spec to CI". Each needs a different entry point.

## Decision

Four skills in one plugin:
- `formal-verify` is the entry point and owns workflows W1–W8, the correspondence map,
  reproduction, CI and drift, and the report contract. Its `references/` hold the shared material.
- `tlaplus-model` covers TLA+, PlusCal, and Quint modeling and checking.
- `lean-model` covers Lean 4 modeling, refutation, proof, and trust audit.
- `proof-simplify` covers workflow W4, turning proofs into deletions.

The sibling skills reach shared files through `${CLAUDE_SKILL_DIR}/../formal-verify/…`. That
path resolves both in an installed plugin and through this repo's `.claude/skills` symlinks.

## Consequences

- Each skill has a sharp, "pushy" description that triggers on its own vocabulary, and
  formal-verify also triggers on plain-language symptoms ("double charge", "hangs").
- Tool skills can be used alone (for example, "fix my .tla file") without the full workflow.
- Cross-skill paths assume the skills are installed side by side. The plugin guarantees
  this; copying a single skill elsewhere loses the shared references.
- Four descriptions to optimize and four skills to evaluate.
