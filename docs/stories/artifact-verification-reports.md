---
type: Story
title: Artifact verification reports
tags:
  - skills
summary: Every workflow ends in a published Artifact page built from formal/findings.json via the artifact-design and artifact-diagramming skills.
tasks:
  - ps-5
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:12.883Z
lore_task_status: done
---

# Artifact verification reports

## Goal

Results reach the user as a page they can read, share, and come back to, not as terminal
scroll. The page leads with the verdict and its bounds. It then shows:
- each finding with its trace, code mapping, reproduction, and fix,
- what was verified,
- the scope and assumptions,
- the trust base, and
- the exact commands to re-run.

## Acceptance criteria

- [x] The report contract is in `formal-verify/references/report-artifact.md`: seven
  required sections in a fixed order, plus a W4 Simplifications section and a W8 trace-only variant.
- [x] The machine-readable source of truth is `formal/findings.json`, with a schema that
  covers properties, findings (including trace steps), simplifications, and the trust base
  (TLC state counts, Lean axioms, sorry count).
- [x] Publishing loads `artifact-design` first and `artifact-diagramming` for traces
  (Mermaid sequence diagrams render natively). It uses a stable file path per concern, so
  the URL survives re-runs.
- [x] Fallback: without an Artifact tool, the same HTML goes to `formal/reports/`.
- [x] Eval runs write `outputs/report.html` in place of publishing (eval mode).

## Tasks

<!-- lore:tasks:begin -->
| Task | Title | Status |
|---|---|---|
| [PS-5](../../.quest/completed/PS-5.json) | Build Artifact verification reports | Done |
<!-- lore:tasks:end -->

## Notes

Decision record: [ADR 0002](../adr/0002-findings-json-drives-artifact-reports.md). Field
reference: [Findings schema](../reference/findings-schema.md).
