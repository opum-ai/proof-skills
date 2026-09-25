---
# yaml-language-server: $schema=../../.lore/schemas/runbook.schema.json
type: Runbook
title: Verify skill assets
summary: "Re-run every shipped TLA+ model (fix/bug/sanity), the trace-validation harness, the proof-simplify refinement, and the Lean build + trust audit with scripts/verify-assets.sh."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.399Z
---

# Verify skill assets

## Purpose

The skills ship runnable models, and a model that stops behaving as documented misleads
every future user. Run this before each release, after any toolchain bump, and in CI.

## Prerequisites

- Toolchains installed ([Install toolchains](install-toolchains.md)).
- `PROOF_SKILLS_TOOLS` set if the tools are not in `~/.cache/proof-skills`.
- `elan`/`lake` on `PATH` for the Lean part.

## Steps

1. Run everything:
   ```bash
   scripts/verify-assets.sh            # or --tla-only / --lean-only
   ```
2. Expected: `== 28 checks, all passed`:
   - 21 pattern checks (7 patterns × MC/MC_bug/MC_sanity, with the exit codes listed in
     [TLA+ pattern catalog](../reference/tla-pattern-catalog.md)),
   - 2 trace-validation checks (accepted: 0, rejected: 10),
   - 4 proof-simplify checks,
   - 1 Lean build with trust audit (24 theorems, 0 problems).
3. On a failure, run the single case to see the log:
   ```bash
   skills/tlaplus-model/scripts/tlc.sh <Spec>.tla --config <cfg>.cfg
   ```
   A `MC_bug`/`MC_sanity` config that *passes* means a check has lost its teeth. Treat that
   as a release blocker.
4. After editing any pattern, update its row in the pattern catalog and in the tool skill's
   `references/patterns.md`.

## Rollback

Nothing to roll back: the script writes only temporary `-metadir` directories and removes
trace-explorer files.
