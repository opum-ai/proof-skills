---
type: Story
title: tlaplus-model skill
tags:
  - skills
summary: TLA+/PlusCal/Quint modeling skill with a verified TLC wrapper, a counterexample parser, seven runnable bug patterns, a trace-validation harness, and a pitfalls guide.
tasks:
  - ps-2
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:12.609Z
lore_task_status: done
---

# tlaplus-model skill

## Goal

Let an agent model concurrent or distributed code in TLA+ quickly and faithfully, and
check it with TLC. The skill supplies:
- runnable patterns for the common bug classes,
- a wrapper that turns TLC output into a code-mapped trace table, and
- rules that stop a model from passing vacuously.

Location: `plugins/proof-skills/skills/tlaplus-model/`.

## Acceptance criteria

- [x] `scripts/setup_tla.sh` installs tla2tools.jar (pinned v1.8.0 or `--nightly`) and
  CommunityModules into a user cache. With `--with-jre` it also installs a portable Temurin 21 JRE.
- [x] `scripts/tlc.sh` runs SANY, then TLC, saves `tlc.log` and `cex.json`, prints
  `trace.md`, and exits with TLC's verified codes (0, 10, 11, 12, 13, 150).
- [x] `scripts/parse_tlc_trace.py` reads both `-dumpTrace json` and text output, and maps
  actions to `src:` tags.
- [x] Seven patterns: LostUpdate, CacheAside, IdempotentRetry, JobLease, BatchPipeline,
  DagScheduler, and OrderStateMachine. Each has `MC.cfg` (passes), `MC_bug.cfg` (fails), and
  `MC_sanity.cfg` (fails). All 21 behave as specified ([TLA+ pattern catalog](../reference/tla-pattern-catalog.md)).
- [x] A trace-validation harness (`TraceCacheAside.tla`): a good log is accepted (exit 0)
  and a drifted log is rejected (exit 10).
- [x] The Quint example type-checks, and `quint run` finds the lost update (Quint 0.32.0).
- [x] References: patterns, the TLC CLI, pitfalls, trace validation, and Apalache/Quint.

## Tasks

<!-- lore:tasks:begin -->
| Task | Title | Status |
|---|---|---|
| [PS-2](../../.quest/completed/PS-2.json) | Build tlaplus-model skill | Done |
<!-- lore:tasks:end -->

## Notes

Checking the patterns caught one research-provided snippet that did not parse:
`None == -1` needs `EXTENDS Integers`. This is now a documented rule. TLC reports an
*action property* violation with exit 13, not 12; both the wrapper and the docs say so.
