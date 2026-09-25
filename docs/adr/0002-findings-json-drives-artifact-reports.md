---
# yaml-language-server: $schema=../../.lore/schemas/adr.schema.json
type: ADR
title: Findings JSON drives Artifact reports
summary: "Workflows write machine-readable formal/findings.json first; the Artifact report is built from it following the artifact-design skill, rather than from a fixed HTML template."
tags:
  - architecture
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.055Z
---

# Findings JSON drives Artifact reports

## Status

Accepted (2026-09-22)

## Context

The user asked for results to be produced with the Artifact skills. Two options were
considered: bundle a fixed HTML report template, or have the agent build each page with
`artifact-design`. A fixed template gives uniform output, but it conflicts with
`artifact-design`, which owns the page contract (theming, CDN allowlist, phone width) and
changes over time. A purely freeform page gives no stable structure for later tooling
(CI, proof-simplify, re-runs) to read.

## Decision

- The workflow's source of truth is `formal/findings.json`, validated against
  `formal-verify/assets/findings.schema.json`.
- `formal-verify/references/report-artifact.md` fixes the report's content: required
  sections, their order, and what each finding must show.
- The page's design comes from `artifact-design` (plus `artifact-diagramming` for traces),
  loaded at publish time.
- Each concern publishes from a stable file path, so the Artifact URL survives re-runs.
- The fallback is a local HTML file when no Artifact tool exists.

## Consequences

- Reports are consistent in content and current in design.
- `proof-simplify`, CI, and later sessions can read prior results mechanically.
- Content is reviewed against the contract, not a template, so evals check for the required
  sections rather than exact HTML.
