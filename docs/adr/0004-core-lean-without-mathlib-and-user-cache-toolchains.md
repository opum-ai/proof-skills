---
# yaml-language-server: $schema=../../.lore/schemas/adr.schema.json
type: ADR
title: Core Lean without Mathlib and user-cache toolchains
summary: "Lean templates depend only on core Lean 4.34 plus optional plausible; TLA+ tools and an optional portable JRE install into ~/.cache/proof-skills without sudo."
tags:
  - architecture
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.226Z
---

# Core Lean without Mathlib, and user-cache toolchains

## Status

Accepted (2026-09-22)

## Context

- A `lake new … math` project downloads about 7.9 GB of prebuilt `.lake` cache
  (measured during research). That is too heavy for a bug hunt, a CI job, or a
  contributor's laptop.
- Core Lean 4.34 already ships what software models need: `grind`, `omega`, `decide`,
  `bv_decide`, `simp`, `mvcgen`, `Std.HashMap`, and `Relation.TransGen`.
- TLA+ needs Java 11+, which many developer machines lack; the target machine for this repo
  had none.
- Skills must not surprise users with system-wide installs.

## Decision

- The Lean template and the patterns require only core Lean plus `plausible`, pinned to the
  tag that matches `lean-toolchain` (v4.34.0). `new_project.sh --no-plausible` removes even that.
- `setup_tla.sh` installs `tla2tools.jar` (pinned v1.8.0 by default) and CommunityModules
  into `$PROOF_SKILLS_TOOLS`, which defaults to `~/.cache/proof-skills`. `--with-jre` also
  downloads a portable Temurin 21 JRE there. `tlc.sh` and `doctor.sh` find it automatically.
- `setup_lean.sh` installs elan with `--no-modify-path`. Projects pin their own toolchain.
- The skills tell the agent to ask before installing anything system-wide.

## Consequences

- A cold start is minutes, not an hour. CI caches stay small.
- Mathlib-dependent work (probability, heavy combinatorics) needs a separate project.
  `lean-model/references/setup.md` explains when that is worth it.
- Pinning means a periodic bump. The [release runbook](../runbooks/release-a-new-version.md)
  covers upgrading toolchains.
