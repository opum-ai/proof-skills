---
# yaml-language-server: $schema=../../.lore/schemas/runbook.schema.json
type: Runbook
title: Install toolchains
summary: "Install TLA+ (Java, tla2tools, CommunityModules), Lean 4 (elan), and optional Quint/Apalache without sudo, then confirm with doctor.sh."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:23:36.717Z
---

# Install toolchains

## Purpose

Get a machine ready to run the skills: TLC for TLA+, Lean 4 for proofs, and optionally
Quint or Apalache. Nothing here needs sudo, and everything lands in user directories.

## Prerequisites

- `curl`, `bash`, `python3` (3.9+), and `git`.
- About 1 GB free: a JRE of about 200 MB, one Lean toolchain of about 700 MB, and TLA+ jars of about 10 MB.
- The skills installed, either as the plugin or as a clone of this repo.

## Steps

1. See what is already present:
   ```bash
   skills/formal-verify/scripts/doctor.sh
   ```
2. TLA+:
   ```bash
   skills/tlaplus-model/scripts/setup_tla.sh            # uses Java on PATH
   skills/tlaplus-model/scripts/setup_tla.sh --with-jre # no Java? portable Temurin 21
   ```
   The tools install into `~/.cache/proof-skills`. Override the location with
   `PROOF_SKILLS_TOOLS=/path` (the same variable tells `tlc.sh` where to look). Add
   `--nightly` for the nightly jar; the pinned release is the default.
3. Lean 4:
   ```bash
   skills/lean-model/scripts/setup_lean.sh
   export PATH="$HOME/.elan/bin:$PATH"
   ```
   Each project's `lean-toolchain` selects the exact version (v4.34.0 for the shipped
   patterns). The first `lake build` downloads it.
4. Optional:
   - Quint: `npm i -g @informalsystems/quint`
   - Apalache: download from https://apalache-mc.org (Quint's `verify` also fetches it automatically)
5. Confirm:
   ```bash
   skills/formal-verify/scripts/doctor.sh   # every required row "ok"
   scripts/verify-assets.sh                                      # 27 TLC checks + Lean audit pass
   ```

## Rollback

```bash
rm -rf ~/.cache/proof-skills          # TLA+ jars and the portable JRE
elan self uninstall                   # Lean toolchains and elan
npm rm -g @informalsystems/quint      # if installed
```
