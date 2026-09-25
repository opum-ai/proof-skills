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
[ADR 0005](0005-distribute-as-a-claude-code-plugin-marketplace.md). Its symlinks and
namespacing still stand. Its `plugins/proof-skills/` layout does not: the plugin moves to the
repository root, as decided below.

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
  `.claude-plugin/plugin.json` at the repository root is the only manifest. It names Opum AI as
  the author, MIT as the license, and this repo as the homepage and repository.
- The plugin lives at the repository root: `.claude-plugin/plugin.json`, `skills/` and
  `evals/` sit at the top level, and the repository root is the plugin root. The reason is
  `opum-marketplace`'s tooling, as measured by that repository (2026-09-25): its pin and
  content checks and its Codex marketplace generator support only a plain `github` source
  whose `.claude-plugin/plugin.json` is at the repository root, and Codex's per-plugin source
  has no documented subdirectory field. A `git-subdir` entry naming `plugins/proof-skills`
  would therefore fall outside every check that repository runs on its pins.
- v0.1.0 shipped the earlier layout, with the plugin in `plugins/proof-skills/`. That tag is
  left as published and is never re-cut. v0.1.1 is the first release with the root layout, and
  the first one the `opum-marketplace` entry can pin.
- `opum-marketplace` lists `proof-skills` as a federated entry that pins
  `opum-ai/proof-skills` at a release tag such as `v0.1.1`, never a moving branch, with
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
- The proof-skills entry has the same shape as every other `opum-marketplace` entry: a plain
  `github` source pinned to a tag, with no subdirectory to name.
- Paths in this repository's docs, scripts and evals are relative to the repository root:
  `skills/<name>/`, `evals/`, and `scripts/verify-assets.sh`. The `.claude/skills` symlinks
  point at `../../skills/<name>`.
- Local development does not need a marketplace. `claude plugin validate .` and
  `claude plugin eval .`, run from the repository root, check and evaluate the plugin.
