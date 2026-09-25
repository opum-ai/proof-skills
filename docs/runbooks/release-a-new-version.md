---
# yaml-language-server: $schema=../../.lore/schemas/runbook.schema.json
type: Runbook
title: Release a new version
summary: "Bump the version, re-verify assets, validate the plugin manifest, check docs, tag and push, then have the opum-marketplace entry repinned to the new tag."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.567Z
---

# Release a new version

## Purpose

Ship a new plugin version that users receive through `/plugin update`.

## Prerequisites

- A clean working tree on `main`.
- Toolchains installed; `claude` CLI available.

## Steps

1. Choose the version (semver). Skill-behavior changes are a minor bump; fixes are a patch.
2. Bump it in `.claude-plugin/plugin.json`. The marketplace entry lives
   in `opum-marketplace`, and step 7 repins it.
3. When bumping toolchains, change `lean-toolchain` and the plausible `rev` together
   (both the patterns and the template), and `TLA_VERSION` in `setup_tla.sh`. Then update the
   versions stated in `lean-model/references/setup.md` and `tlaplus-model/references/tlc-cli.md`.
4. Verify:
   ```bash
   scripts/verify-assets.sh
   for s in skills/*; do python3 <skill-creator>/scripts/quick_validate.py $s; done
   claude plugin validate .
   lore check
   ```
5. For skill-text changes, run at least one eval iteration ([Run skill evals](run-skill-evals.md))
   and compare it with the previous benchmark.
6. Commit on `main`, tag `vX.Y.Z`, and push both to `origin` (`opum-ai/proof-skills`,
   `git push origin main --tags`). The tag is the ref that
   the marketplace pins.
7. Get the new tag into [opum-marketplace](https://github.com/opum-ai/opum-marketplace),
   Opum AI's public marketplace (named `opum`). It federates: each entry is a `github`
   source that pins `opum-ai/<repo>` at a ref, with homepage `https://github.com/opum-ai/<repo>`.
   That repository owns the `proof-skills` entry and the CI checks on its pin, and its own
   maintaining session makes changes there, so ask that session to move the pin to `vX.Y.Z`
   rather than editing the entry from here. How it lands the change is its process, not
   this runbook's. Users pick up the release with
   `/plugin marketplace update opum` and `/plugin update proof-skills@opum`.

## Rollback

Revert the release commit, bump to a new patch version (never reuse a version number), tag and
push it, and have the `opum-marketplace` pin moved to that tag as in step 7.
