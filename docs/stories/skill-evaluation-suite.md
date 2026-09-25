---
type: Story
title: Skill evaluation suite
tags:
  - skills
summary: Five realistic buggy fixtures (Python asyncio, TypeScript, Go, Python threads, Rust) with eval prompts, run with and without the skills and graded against objective assertions.
tasks:
  - ps-6
  - ps-7
  - ps-8
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:12.966Z
lore_task_status: done
---

# Skill evaluation suite

## Goal

Measure whether the skills make the agent better at real formal-verification tasks than the
same agent without them, and catch regressions when the skills change. The method is
skill-creator's: with-skill and baseline runs, graded assertions, a benchmark, and human review.

## Acceptance criteria

- [x] Five fixtures in `evals/fixtures/`, each with a planted bug that its existing tests miss:

  | Fixture | Language | Bug class |
  |---|---|---|
  | `py-webhooks` | Python asyncio | check-then-act across awaits → double capture |
  | `ts-job-queue` | TypeScript | lease expiry without fencing → stale overwrite, double processing |
  | `go-dag` | Go | readiness counts Running dependencies as satisfied |
  | `py-orders` | Python threads | belt-and-braces lock + CAS + post-check: simplification target |
  | `rust-pool` | Rust std threads | capacity check-then-act (safety) + lost wakeup (liveness) |
- [x] `evals/evals.json` has the prompt in the user's words and the expected output for each fixture.
- [x] Iteration-1 benchmark (pass rate, time, tokens; with and without skill) is recorded in
  `evals-workspace/iteration-1/benchmark.md`.
- [x] The human review in the eval viewer is complete, and its feedback is folded into iteration 2.
- [x] Trigger evals (20 queries per skill in `evals/triggers/`) are run through skill-creator's
  description optimizer. The best description on the held-out split is applied.

## Tasks

<!-- lore:tasks:begin -->
| Task | Title | Status |
|---|---|---|
| [PS-6](../../.quest/completed/PS-6.json) | Run skill-creator eval iterations 1 and 2 | Done |
| [PS-7](../../.quest/completed/PS-7.json) | Tune skill descriptions with trigger evals | Done |
| [PS-8](../../.quest/completed/PS-8.json) | Port evals to claude plugin eval | Done |
<!-- lore:tasks:end -->

## Notes

### Trigger (description) evals (2026-09-23, claude-opus-5-5, 2 runs per query)

These evals check whether each description makes Claude load the skill for the right
requests, and skip it for near misses. There are 20 queries per skill in
`evals/triggers/`. skill-creator's `run_loop` splits them 60/40 into train and held-out
test. It proposes up to 3 descriptions and keeps the one that scores best on test. Each
score counts the queries that behave correctly (triggered on at least half their runs, or
correctly skipped).

| Skill | Original (train / test) | Chosen (train / test) | Change |
|---|---|---|---|
| formal-verify | 11/12 / 7/8 | 11/12 / 7/8 | kept the original |
| tlaplus-model | 11/12 / 7/8 | 11/12 / 8/8 | now names pasted TLC traces; lists the near misses to skip (race detectors, Jepsen, Alloy) |
| lean-model | 11/12 / 6/8 | 12/12 / 8/8 | now excludes pure mathematics, syntax translation, and other provers |
| proof-simplify | 12/13 / 7/7 | 12/13 / 7/7 | kept the original |

Precision was 100% for every chosen description: no false triggers on near misses. The
remaining misses are positives where the model answered directly, for example "is
`TokenBucket.take()` thread safe?". The same description scored 81% and then 92% on
train in two runs, so treat differences under about 10 points as noise.

The first attempts measured 0% recall, and that was a harness problem, not the
descriptions:
1. The stock `run_eval.py` stops at the first tool call that is not `Skill`. Agents usually
   run `ls` or `find` first.
2. In an empty project root, the model cannot find the file a query names, so it asks for
   the code. `make_trigger_root.py` now builds a read-only stub repository.
3. Parallel workers share `.claude/commands/`. The model may load another worker's
   identical copy of the skill.

`evals/triggers/run_eval-keep-scanning.patch` fixes items 1 and 3.

### `claude plugin eval` trigger suite (2026-09-23, 80 cases, 2 runs each)

The same 80 queries, run through `claude plugin eval` against the installed plugin, with
all four skills loaded together ([Run plugin evals](../runbooks/run-plugin-evals.md)).
76 of 80 cases scored 1.0, over 16 minutes and $25.34.

| Skill | Should fire (intended skill) | Near miss (correctly skipped) |
|---|---|---|
| formal-verify | 8/10 | 10/10 |
| tlaplus-model | 9/10, plus one routed through a sibling (score 0.33) | 10/10 |
| lean-model | 10/10 | 10/10 |
| proof-simplify | 8/8 | 11/12 |

The four misses, all stable across both runs:
- **formal-verify 06:** the Kotlin `if (stock > 0) decrement()` oversell. The model answered
  directly.
- **formal-verify 09:** "is `TokenBucket.take()` thread safe?". The model answered directly.
- **tlaplus-model 09:** "exhaustively check our saga orchestrator". A sibling skill fired
  instead.
- **proof-simplify 20:** "reduce the number of locks in our Java pool for performance". This
  is a false trigger on a borderline query.

The timeouts and max-turns notes happen after the skill decision is made, and do not affect
the scores.

### `claude plugin eval` bug-hunt suite (2026-09-23, 5 cases, 1 run per arm)

These are the same five fixtures and assertions, run through `claude plugin eval` with and
without the plugin. Haiku judges each assertion from the final message (3 votes). The whole
suite took 17 minutes and cost $14.05.

| Case | With plugin | Without | Δ |
|---|---|---|---|
| dag-executor-all-graphs (Go) | 0.63 | 0.50 | +0.13 |
| job-lease-stale-worker (TypeScript) | 0.76 | 0.71 | +0.06 |
| orders-simplify-belt-and-braces (Python) | 0.88 | 0.71 | +0.18 |
| rust-pool-capacity-and-hang (Rust) | 0.93 | 0.40 | +0.53 |
| webhook-double-capture (Python asyncio) | 0.60 | 0.53 | +0.07 |
| **Mean** | **0.76** | **0.57** | **+0.19** |

Read these next to the skill-creator results below (98% against 54%). The lift is in the
same direction, but smaller, for three reasons:
- **Shorter runs.** All 10 runs finished within 17 minutes, 5 at a time. Under skill-creator,
  a with-skill run averaged about 23 minutes. These cases allow no subagents (`Agent` is not in
  `allowed_tools`). Deep checks were often skipped, such as the counterexample graph diagram
  and saved logs for every claim.
- **A weaker judge.** Haiku sees only the final message. The saved-logs assertion ("every
  check the report claims has a log") failed in all 10 runs. The skill-creator graders opened
  the files instead.
- **One run per arm.** Differences under about 0.1 are within noise.

Two assertions failed in both arms of the same case. They point at graders that need more
evidence than a final message carries, not at the plugin:
- webhook `pytest passes after the fix`;
- dag `adds a Go regression test with workers >= 2`.

### Iteration 2 results (2026-09-23, tightened assertions; baselines reused and re-graded)

| Eval | With skill | Without skill |
|---|---|---|
| webhook-double-capture | 13/13 | 6/13 |
| job-lease-stale-worker | 15/15 | 9/15 |
| dag-executor-all-graphs | 14/14 | 8/14 |
| orders-simplify-belt-and-braces | 15/15 | 9/15 |
| rust-pool-capacity-and-hang | 12/13 | 6/13 |
| **Mean** | **98%** | **54%** |

Changes in iteration 2:
- **Diagrams**, from user feedback: graphs and state machines are drawn with `graph_svg.py`.
- **Reproductions** must fail on the property itself, and must respect the user's stated deliverable.
- **Evidence**: every check the report cites has a log under `formal/<concern>/evidence/`.
- **SQL**: the database's isolation semantics are modeled, or flagged as an assumption.
- **Side findings** are reported as separate findings.

Cost: 1358 s and 220k tokens per task with the skill, against 564 s and 101k without.

### Iteration 1 results (2026-09-22, claude-opus-5-5, 1 run per configuration)

| Eval | With skill | Without skill |
|---|---|---|
| webhook-double-capture (Python) | 12/12 | 7/12 |
| job-lease-stale-worker (TypeScript) | 12/12 | 8/12 |
| dag-executor-all-graphs (Go) | 12/12 | 9/12 |
| orders-simplify-belt-and-braces (Python) | 13/13 | 10/13 |
| rust-pool-capacity-and-hang (Rust) | 12/12 | 9/12 |
| **Mean** | **100%** | **70%** |

- Time: 1208 s with the skill against 564 s without, about 2.1×.
- Tokens: 207k against 101k, about 2.0×.
- The whole delta comes from the rigor and traceability assertions (bounds, sanity checks,
  code map, findings.json, report). Without the skill, Opus 5.5 still finds and fixes every
  planted bug.
- Each configuration also found things the other missed; see `benchmark.json` notes.


Runbook: [Run skill evals](../runbooks/run-skill-evals.md). The eval workspace is git-ignored.
