---
# yaml-language-server: $schema=../.lore/schemas/reference.schema.json
type: Reference
title: Documentation
summary: "Root index of the proof-skills documentation bundle — formal-verification skills for Claude Code using TLA+ and Lean 4."
generated:
  by: lore/0.8.0
  at: 2026-09-23T01:49:18.292Z
okf_version: "0.2"
---

# Documentation

Documentation for **proof-skills**: a Claude Code plugin with four skills that find, fix,
and simplify concurrency, data-flow, state-management, and graph bugs in any codebase with
TLA+ and Lean 4, and publish the results as Artifact reports. This file is the bundle's
entry point, and the only one that carries `okf_version`.

## Start here

- [Epic: Formal verification skills](epics/formal-verification-skills.md): goal, scope, stories, decisions.
- [Workflows W1–W8](reference/workflows-w1-w8.md): what the skills can do end to end.
- [Install toolchains](runbooks/install-toolchains.md): get TLC and Lean running without sudo.

## Stories

- [formal-verify orchestrator skill](stories/formal-verify-orchestrator-skill.md)
- [tlaplus-model skill](stories/tlaplus-model-skill.md)
- [lean-model skill](stories/lean-model-skill.md)
- [proof-simplify skill](stories/proof-simplify-skill.md)
- [Artifact verification reports](stories/artifact-verification-reports.md)
- [Skill evaluation suite](stories/skill-evaluation-suite.md)

## Decisions (ADRs)

- [0001 Split into four skills with an orchestrator](adr/0001-split-into-four-skills-with-an-orchestrator.md)
- [0002 Findings JSON drives Artifact reports](adr/0002-findings-json-drives-artifact-reports.md)
- [0003 Three-config sanity pattern for every model](adr/0003-three-config-sanity-pattern-for-every-model.md)
- [0004 Core Lean without Mathlib and user-cache toolchains](adr/0004-core-lean-without-mathlib-and-user-cache-toolchains.md)
- [0005 Distribute as a Claude Code plugin marketplace](adr/0005-distribute-as-a-claude-code-plugin-marketplace.md)

## Runbooks

- [Install toolchains](runbooks/install-toolchains.md)
- [Verify skill assets](runbooks/verify-skill-assets.md)
- [Run skill evals](runbooks/run-skill-evals.md)
- [Run plugin evals](runbooks/run-plugin-evals.md)
- [Release a new version](runbooks/release-a-new-version.md)

## Reference

- [State of the art in agent-driven formal verification](reference/state-of-the-art-in-agent-driven-formal-verification.md)
- [Workflows W1–W8](reference/workflows-w1-w8.md)
- [TLA+ pattern catalog](reference/tla-pattern-catalog.md)
- [Lean pattern catalog](reference/lean-pattern-catalog.md)
- [Findings schema](reference/findings-schema.md)
- [Glossary](reference/glossary.md)

<!-- lore:index:begin -->
- [adr](adr/index.md)
- [epics](epics/index.md)
- [reference](reference/index.md)
- [runbooks](runbooks/index.md)
- [stories](stories/index.md)
<!-- lore:index:end -->
