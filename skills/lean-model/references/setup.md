# Setup: elan, lake, toolchains

## Install

```bash
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain stable
# or: scripts/setup_lean.sh [--elan-home DIR]
```

## Project layout and commands

| Command | Effect |
|---|---|
| `lake new foo` | new project (std template: library plus executable, TOML config). Other templates: `exe`, `lib`, `math` |
| `lake build` | build the default targets and their dependencies |
| `lake build Plausible` | build one dependency's modules |
| `lake env lean F.lean` | elaborate one file with dependency paths set. Does **not** build dependencies. |
| `lake exe replay` | run an executable target |
| `lake update` | refresh `lake-manifest.json`. Commit that file. |
| `elan override set leanprover/lean4:v4.34.0` | pin a toolchain for a directory |

The `lean-toolchain` file pins the exact Lean version, and elan honors it automatically. Pin
dependency `rev`s to the tag that matches the toolchain (for example, plausible `v4.34.0`
with Lean `v4.34.0`). In a 2026 Rust-to-Lean experience report, toolchain drift was the top
source of friction.

## Mathlib: usually no

| | No Mathlib (the template) | Mathlib |
|---|---|---|
| First build | seconds | downloads about 8 GB of prebuilt `.lake` |
| Available | List/Array/HashMap, `omega`, `grind`, `decide`, `bv_decide`, `simp`, `mvcgen`, `Relation.TransGen` | Finset, combinatorics, probability, `aesop`, a much larger lemma library |
| Use when | software models: state machines, protocols, pipelines, graph algorithms | real mathematics (probability as in SampCert, algebra) |

## Agent tooling

- **lean-lsp-mcp:** `claude mcp add lean-lsp uvx lean-lsp-mcp`. Set `LEAN_PROJECT_PATH` and
  run `lake build` first. Useful tools:
  - `lean_goal` (proof state at a position),
  - `lean_diagnostic_messages`,
  - `lean_multi_attempt` (try several tactics),
  - `lean_verify` (axiom audit),
  - `lean_loogle` / `lean_leansearch` (lemma search).
- **Veil** (verse-lab): a Lean DSL for transition systems. It has `#model_check`,
  `#check_invariants`, SMT automation, and falls back to Lean proofs. It suits
  distributed-protocol models. It pins its own toolchain (4.32 as of September 2026), so
  keep it in its own project.
- **Iris-Lean:** separation logic for fine-grained concurrent memory. Powerful, but more
  than a bug hunt needs.

## Toolchain versions in this repository

Every pattern and template was checked on Lean `v4.34.0`, Lake 5.0.0, and plausible
`v4.34.0` (September 2026). When upgrading, bump `lean-toolchain` and the plausible `rev`
together, then run `lake update && lake build && scripts/check_trust.sh .`.
