---
# yaml-language-server: $schema=../../.lore/schemas/runbook.schema.json
type: Runbook
title: Run skill evals
summary: "Run the with-skill vs baseline eval suite over the five fixtures, grade assertions, aggregate the benchmark, and review in the skill-creator viewer."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.483Z
---

# Run skill evals

## Purpose

Measure the skills against a no-skill baseline on realistic tasks, and catch regressions
after skill edits. This follows the skill-creator loop.

## Prerequisites

- Claude Code with the `skill-creator` plugin.
- Toolchains ([Install toolchains](install-toolchains.md)), plus the fixture languages:
  Python 3 with pytest, Node 20+, Go, and Rust (cargo).
- About 10 concurrent subagents' worth of budget. Each run takes 10–40 minutes.

## Steps

1. Create the iteration workspace, with a fresh fixture copy per configuration:
   ```bash
   W=evals-workspace/iteration-N
   for e in $(jq -r '.evals[] | "\(.name)=\(.fixture)"' plugins/proof-skills/evals/evals.json); do
     name=${e%%=*}; fx=${e#*=}
     for c in with_skill without_skill; do
       mkdir -p $W/eval-$name/$c/outputs && cp -R plugins/proof-skills/evals/fixtures/$fx $W/eval-$name/$c/outputs/repo
     done
   done
   ```
2. In Claude Code, ask for the evals to be run ("run iteration N of the proof-skills
   evals"). Every with-skill and baseline run starts in the same turn. With-skill runs
   point at `plugins/proof-skills/skills/formal-verify` (or `proof-simplify` for eval 4).
   Baselines are told not to use the skills. All runs are in eval mode: the report goes to
   `outputs/report.html`, not a published Artifact.
3. As each run completes, record `timing.json` (tokens, duration).
4. Grade each run against the `assertions` in `eval_metadata.json`, following the grader
   instructions in skill-creator's `agents/grader.md`. Save the result as `grading.json`
   with `text`/`passed`/`evidence`.
5. Aggregate and review:
   ```bash
   SC=<skill-creator dir>
   (cd $SC && python -m scripts.aggregate_benchmark <repo>/$W --skill-name proof-skills)
   python $SC/eval-viewer/generate_review.py $W --skill-name proof-skills --benchmark $W/benchmark.json
   ```
   For iteration 2 and later, add `--previous-workspace evals-workspace/iteration-(N-1)`.
6. Read `feedback.json` after the review. Fold general lessons into the skills (not
   fixture-specific patches), then run iteration N+1.

7. **Trigger (description) evals.** `plugins/proof-skills/evals/triggers/make_trigger_sets.py` writes 20 queries
   per skill (should-trigger and near-miss should-not-trigger) to `plugins/proof-skills/evals/triggers/<skill>.json`.
   Run skill-creator's optimizer from a scratch project, not this repo, so the installed
   copies of the skills do not compete with the copy under test. The scratch project must
   not be empty. The queries name files such as `controllers/quota.go`. In an empty root the
   model finds nothing and asks for the code, so every positive query scores as a miss.
   `plugins/proof-skills/evals/triggers/make_trigger_root.py <dir>` writes a stub monorepo with every named file.
   Make it read-only (`chmod -R a-w`, then `chmod u+w <dir>/.claude <dir>/.claude/commands`), because
   the eval model starts modeling in it.
   First patch a **copy** of skill-creator's `scripts/`. The stock `run_eval.py` stops at
   the first tool call that is not `Skill` or `Read`. These skills attract agents that run
   `ls` or `find` before they load a skill, so the stock script reports 0% recall even when
   the skill fires. The stock script also has parallel workers share one `.claude/commands/`
   directory, so the model sees one identical copy of the skill per worker. It may call a copy
   whose random ID belongs to another worker, and the stock script counts that as a miss.
   `plugins/proof-skills/evals/triggers/run_eval-keep-scanning.patch` fixes both. It keeps scanning for up to six
   tool calls, accepts any copy of the skill under test, and caps each query at `--max-turns 6`:
   ```bash
   cp -R <skill-creator>/scripts /tmp/sc/ && (cd /tmp/sc && patch -p1 < <repo>/plugins/proof-skills/evals/triggers/run_eval-keep-scanning.patch)
   python3 <repo>/plugins/proof-skills/evals/triggers/make_trigger_root.py /tmp/trigger-root && cd /tmp/trigger-root
   PYTHONPATH=/tmp/sc python3 -m scripts.run_loop \
     --eval-set <repo>/plugins/proof-skills/evals/triggers/<skill>.json \
     --skill-path <repo>/plugins/proof-skills/skills/<skill> \
     --model claude-opus-5-5 --max-iterations 3 --runs-per-query 2 --timeout 180 \
     --results-dir /tmp/trigger-results/<skill>
   ```
   Rebuild the stub root between skills. Apply the `best_description` from the results (selected on the held-out 40%
   split), then re-run `quick_validate.py` and `claude plugin validate`.

## Rollback

`rm -rf evals-workspace/iteration-N`. The workspace is git-ignored.
