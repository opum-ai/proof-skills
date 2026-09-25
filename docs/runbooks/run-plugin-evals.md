---
# yaml-language-server: $schema=../../.lore/schemas/runbook.schema.json
type: Runbook
title: Run plugin evals
tags:
  - skills
  - evals
summary: "Run the claude plugin eval suite: 80 trigger cases and 5 bug-hunt cases generated from the skill-creator eval data, with scaffolded fixtures and linked toolchains."
generated:
  by: lore/0.8.0
  at: 2026-09-23T14:37:48.286Z
---

# Run plugin evals

## Purpose

Run the plugin's own eval suite with `claude plugin eval`, locally or in CI. It loads the
real plugin, as a user would install it, and can compare against a no-plugin baseline.
[Run skill evals](run-skill-evals.md) covers the deeper skill-creator loop, in which graders
re-run every model check.

The cases live in `plugins/proof-skills/evals/cases/` and are generated. Do not edit them
by hand. Edit the sources, then run `python3 plugins/proof-skills/evals/make_cases.py`:

| Suite | Tag | Cases | Source | Graders |
|---|---|---|---|---|
| Trigger | `trigger` | 80 (20 per skill) | `evals/triggers/make_trigger_sets.py` | `tool_used: Skill` (fires, or does not fire) |
| Bug hunt | `bughunt` | 5 | `evals/evals.json` + `evals/fixtures/` | one LLM grader per assertion (on the trace), plus `file_exists` checks for `findings.json` and the report |

## Prerequisites

- **Both suites.** Every run starts in an empty throwaway workspace with a throwaway
  `$HOME`. Each case has a `scaffold.sh` that builds its starting repo, so every command
  below needs `--scaffold`. The scaffold scripts are ours, and they run as you.
- **Trigger suite.** Nothing else. Each scaffold writes the stub monorepo from
  `evals/triggers/make_trigger_root.py`.
- **Bug-hunt suite.**
  - `plugins/proof-skills/skills/tlaplus-model/scripts/setup_tla.sh --with-jre` must have
    been run once.
  - elan (for Lean), plus the fixture languages: Python 3 with pytest, Node 20+, Go, Rust.
  - The run's Bash sandbox cannot read your real home or reach the network, so symlinks and
    downloads fail. `evals/scaffold_env.sh` finds each tool's real install. It clones any
    install under your home into the run's `$HOME` (copy-on-write with `cp -c` on APFS),
    and writes shell profiles that put the clones first on PATH. Tools under Homebrew or
    `/usr` are used as-is. It handles `~/.cache/proof-skills`, `~/.elan`, the active
    Python prefix and its user site-packages (pytest), the active Node prefix, and
    `~/.cargo` with `~/.rustup`.
  - **git does not work inside a run on macOS.** `/usr/bin/git` is an `xcrun` shim, and it
    needs a per-user cache directory that the sandbox blocks. The scaffold commits the
    fixture before the run, and the system prompt tells the agent to expect this.

## Steps

Run these from the repo root. From inside `plugins/proof-skills/`, use `.` as the target instead.

1. Trigger suite, with the plugin only. At the default 2 runs per case with `-j 8`, all
   80 cases take about 17 minutes and cost about $25. `--runs 1` halves the cost.
   ```bash
   claude plugin eval plugins/proof-skills --tag trigger --scaffold --ablation none -j 8 --threshold 0
   ```
   Use `--case 'trigger-lean-model-*'` to run one skill's set. The glob accepts `*` only, not
   `?` or `[...]`. Each should-fire case scores 1.0 when the intended skill fires. It scores
   0.33 when only a sibling skill fires, for example `formal-verify` routing to
   `tlaplus-model`. `--ablation none` is right here: without the plugin no skill can fire,
   so a baseline arm adds cost and no information.
2. Bug-hunt suite, with and without the plugin (20–40 minutes per run):
   ```bash
   claude plugin eval plugins/proof-skills --tag bughunt --scaffold \
     --allow-tools Bash Write Edit --runs 1 -j 5 --threshold 0
   ```
   The report's `Δ` column is the plugin's lift over the baseline. `z3-fired-*` is a
   with-arm indicator only, and is not part of the score.
3. Results go to `plugins/proof-skills/evals/results/<timestamp>/` (git-ignored), with
   `aggregate-result.json` and `report.html`. `--json <file>` also writes the full result.
4. For CI, add `--trust-plugin` and a real `--threshold`, for example 0.8 for the trigger
   suite. The default threshold of 1.0 fails on any single miss.

The judge model is Haiku by default (`--judge-model` to change it), and it reads the
trace. These graders are weaker than the skill-creator graders, which re-ran TLC, the
Lean builds and the tests. Treat a bug-hunt score as a regression signal, and use the
[skill-creator loop](run-skill-evals.md) for claims about rigor.

## Rollback

`rm -r plugins/proof-skills/evals/results`. Nothing else is written outside the throwaway
workspaces. The toolchains are clones, so a run cannot change your real installs.
