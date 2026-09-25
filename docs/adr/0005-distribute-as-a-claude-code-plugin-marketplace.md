---
# yaml-language-server: $schema=../../.lore/schemas/adr.schema.json
type: ADR
title: Distribute as a Claude Code plugin marketplace
tags:
  - architecture
summary: Publish the four skills as one Claude Code plugin in a same-repo marketplace; symlink them into .claude/skills for local development and evals.
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.313Z
---

# Distribute as a Claude Code plugin marketplace

## Status

Superseded by [ADR 0006](0006-distribute-through-the-opum-marketplace.md) (2026-09-25): the
plugin now ships through Opum AI's public opum marketplace. The same-repo `marketplace.json` has
been removed.

The plugin layout below is superseded too. v0.1.0 shipped it, with the plugin in
`plugins/proof-skills/`. From v0.1.1 the plugin lives at the repository root
(`.claude-plugin/plugin.json`, `skills/`, `evals/`); ADR 0006 records why. The Decision section
below is the layout as accepted on 2026-09-22 and is left as written. What still stands from it:
one plugin named `proof-skills`, skills namespaced as `/proof-skills:<name>`, and
`.claude/skills/<name>` symlinks to the shipped skills, which now point at `skills/<name>`.

Originally accepted 2026-09-22.

## Context

The skills are meant for any project, and the repo is public. The options were:
- copying skill folders into each project's `.claude/skills/`,
- `.skill` packages, and
- a plugin marketplace.

Copying rots, and packages lose the sibling layout that the cross-skill references rely on.

## Decision

- `.claude-plugin/marketplace.json` at the repo root lists one plugin, `proof-skills`,
  with source `./plugins/proof-skills`.
- `plugins/proof-skills/.claude-plugin/plugin.json` sets the name, version, license (MIT),
  and keywords.
- The skills live in `plugins/proof-skills/skills/<name>/`. Once installed they are
  namespaced as `/proof-skills:<name>`.
- `.claude/skills/<name>` symlinks point at the plugin skills, so this repo uses and tests
  the exact files it ships.
- `claude plugin validate` passes for both manifests.

## Consequences

- Users installed with `/plugin marketplace add <owner>/proof-skills`, then
  `/plugin install proof-skills@proof-skills`. See ADR 0006 for the current install path.
- The version lives in two places (plugin.json and the marketplace entry). The release
  runbook bumps both.
