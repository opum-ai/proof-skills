---
# yaml-language-server: $schema=../../.lore/schemas/reference.schema.json
type: Reference
title: Findings schema
summary: "Field reference for formal/findings.json — the machine-readable result of every workflow and the source of the Artifact report."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.913Z
---

# Findings schema

The authoritative JSON Schema is `plugins/proof-skills/skills/formal-verify/assets/findings.schema.json`.

## Details

| Field | Type | Meaning |
|---|---|---|
| `concern` | string | kebab-case id; matches `formal/<concern>/` |
| `workflow` | W1…W8 | which workflow produced the file |
| `generated_at`, `repo_commit` | string | provenance |
| `summary` | string | one-sentence verdict, **including bounds** |
| `scope` | object | `modeled`, `abstracted`, `out_of_scope`, `assumptions` |
| `properties[]` | array | `name`, `kind` (invariant, action-property, liveness, refinement, theorem, bounded-check), `statement`, `meaning`, `source`, `frozen`, `result` (holds, violated, proven, sorry, timeout, not-run), `tool`, `bounds` |
| `findings[]` | array | `id`, `title`, `severity`, `status` (confirmed, suspected, refuted, fixed), `property`, `story`, `trace[]`, `reproduction`, `fix` |
| `findings[].trace[]` | array | `step`, `actor`, `action`, `code` (file:line), `changed` (var → value), `violation` |
| `findings[].fix` | object | `summary`, `diff`, `pr`, `model_recheck`, `mutation_check` (fails-as-expected, unexpectedly-passes, not-run) |
| `simplifications[]` | array | `id`, `change`, `code`, `justification`, `relies_on_assumptions`, `reverified`, `loc_delta`, `status` |
| `trust_base.tla` | object | `tool_version`, `states_generated`, `distinct_states`, `depth`, `sanity_checks` |
| `trust_base.lean` | object | `toolchain`, `axioms` (theorem → axioms, from `check_trust.sh --json`), `sorry_count`, `native_decide_used` |
| `rerun[]`, `next_steps[]` | string arrays | exact commands; suggested follow-up workflows |

`tlaplus-model/scripts/parse_tlc_trace.py --format json` emits a `trace[]` array directly.
Report contract: [Artifact verification reports](../stories/artifact-verification-reports.md).
