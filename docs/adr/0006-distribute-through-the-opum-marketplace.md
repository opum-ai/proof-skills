---
# yaml-language-server: $schema=../../.lore/schemas/adr.schema.json
type: ADR
title: Distribute through the opum marketplace
tags:
  - architecture
summary: List proof-skills in Opum AI's public opum marketplace (opum-ai/opum-marketplace) as a federated entry pinned to a release tag of opum-ai/proof-skills, instead of a standalone same-repo marketplace.
generated:
  by: lore/0.8.0
  at: 2026-09-24T19:44:43.965Z
---

# Distribute through the opum marketplace

## Status

Accepted (2026-09-25). Supersedes the same-repo marketplace in
[ADR 0005](0005-distribute-as-a-claude-code-plugin-marketplace.md). Its plugin layout,
symlinks and namespacing still stand.

## Context

proof-skills is owned by Opum AI. Its source repository is the public
[opum-ai/proof-skills](https://github.com/opum-ai/proof-skills), under the MIT license.

Opum AI already publishes a public Claude Code marketplace,
[opum-ai/opum-marketplace](https://github.com/opum-ai/opum-marketplace), named `opum` in its
`marketplace.json`. It federates rather than hosting plugin code: each entry is a `github`
source that pins `opum-ai/<repo>` at a ref, with homepage `https://github.com/opum-ai/<repo>`.
A second, one-plugin marketplace in this repo would give users two install paths, and would
put proof-skills outside the catalog Opum AI already publishes.

## Decision

- This repo carries no `.claude-plugin/marketplace.json`. It is a plugin repo:
  `plugins/proof-skills/.claude-plugin/plugin.json` is the only manifest. It names Opum AI as
  the author, MIT as the license, and this repo as the homepage and repository.
- `opum-marketplace` lists `proof-skills` as a federated entry that pins
  `opum-ai/proof-skills` at a release tag such as `v0.1.0`, never a moving branch, with
  homepage `https://github.com/opum-ai/proof-skills`.
- `opum-marketplace` owns that entry and the CI checks on its pin. A release is two steps:
  tag the release here, then have the entry's pin moved to that tag in `opum-marketplace`.

## Consequences

- Users install with `/plugin marketplace add opum-ai/opum-marketplace`, then
  `/plugin install proof-skills@opum`. If they already have the marketplace, they run
  `/plugin marketplace update opum` first.
- Both repositories are public, so installing needs no GitHub credentials or organization
  access.
- The version lives in two places: `plugin.json` here, and the pinned ref in
  `opum-marketplace`. The release runbook covers both.
- The plugin manifest sits in `plugins/proof-skills/`, not at the repository root. The
  existing `opum-marketplace` entries all point at repositories whose manifest is at the
  root, so the proof-skills entry either has to name that subdirectory (a `git-subdir`
  source) or the plugin has to move to the root. That choice is made when the entry is
  added, not here.
- Local development is unchanged. The `.claude/skills` symlinks, `claude plugin validate
  ./plugins/proof-skills`, and `claude plugin eval plugins/proof-skills` do not need a
  marketplace.
