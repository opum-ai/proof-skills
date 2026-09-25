# proof-skills

**Formal verification for real codebases, driven by Claude.** Four Claude Code skills. They
model the risky part of your code in **TLA+** or **Lean 4**, find the interleaving or input
that breaks it, prove the finding against your real code with a failing test, fix it, and
re-verify. They can then use the proofs to **delete code you no longer need**. Results are
published as a shareable Artifact report.

> "I used Opus 5.5 to formally verify the Claude Agent SDK using Lean. A couple short prompts
> = 16 PRs fixing various bugs and race conditions. … I sometimes combine Lean and TLA+ to look
> for issues around data flow, concurrency, and state mgmt. I don't know either language well,
> but Claude is excellent at both." ([Boris Cherny, Sept 2026](https://x.com/bcherny/status/2102543349102338309))

These skills make that approach repeatable on **any project, in any language**.

**Status:** v0.1.0. Owned by [Opum AI](https://github.com/opum-ai) and released under the
MIT license. The source is public at [opum-ai/proof-skills](https://github.com/opum-ai/proof-skills).

## What it finds

| Bug class | Example |
|---|---|
| Races, check-then-act, lost updates | `x = count; count = x + 1` across threads |
| Async/await interleavings | cache fill racing an invalidation; dedup checked before an `await` and marked after it |
| Retries and idempotency | webhook redelivery leading to a double charge |
| Leases and fencing | a paused worker commits after its lease was reclaimed |
| Deadlocks and lost wakeups | notify before decrement; wait on a re-acquired lock |
| Dataflow loss, duplication, and stalls | the last partial batch is never flushed at end of stream |
| State-machine violations | `paid → cancelled` from a read-decide-write handler |
| Graphs and DAGs | a scheduler dispatching before its dependencies finish, checked across *all* small graphs, proven for *every* graph |

## The skills

| Skill | Role |
|---|---|
| **`formal-verify`** | Entry point. Picks the workflow, scopes one concern, harvests and freezes properties, maps model ↔ code, reproduces every counterexample in real code, fixes, re-verifies, and publishes the report. |
| **`tlaplus-model`** | TLA+/PlusCal/Quint modeling and TLC checking. Seven verified bug patterns, a TLC wrapper that prints code-mapped traces, and a trace-validation harness. |
| **`lean-model`** | Lean 4 models with executable twins. BFS counterexamples that become theorems, inductive-invariant proofs for all sizes, a `sorry`/axiom trust audit, and differential testing. |
| **`proof-simplify`** | Turns proven facts into safe deletions (dead guards, useless locks, redundant flags), each justified by a re-check, refinement, or reachable-state equivalence. |

### Eight workflows

1. **Bug hunt.** "Why do we double-charge?"
2. **PR review for races.**
3. **Design verification** before code exists.
4. **Proof-guided simplification.** "Do we still need this lock?"
5. **CI regression guard.**
6. **Spec/code drift check.**
7. **TLA+ → Lean escalation.** "Prove it for all N."
8. **Explain a TLC trace.**

## Install

In Claude Code:

```text
/plugin marketplace add opum-ai/opum-marketplace
/plugin install proof-skills@opum
```

proof-skills ships through Opum AI's public plugin marketplace,
[opum-ai/opum-marketplace](https://github.com/opum-ai/opum-marketplace), which is named `opum`.
If you already have that marketplace, the `add` does nothing. Run
`/plugin marketplace update opum` first instead. Both repositories are public, so no GitHub
credentials are needed.

The skills are then available as `/proof-skills:formal-verify` and so on. They also trigger
automatically when you describe a concurrency or state bug.

### Toolchains (no sudo)

```bash
S=$(ls -d ~/.claude/plugins/cache/opum/proof-skills/*/skills | tail -1)   # or plugins/proof-skills/skills in a clone
$S/formal-verify/scripts/doctor.sh             # what's installed
$S/tlaplus-model/scripts/setup_tla.sh --with-jre   # tla2tools + CommunityModules (+ portable JRE)
$S/lean-model/scripts/setup_lean.sh            # elan; projects pin Lean 4.34.0
```

Everything goes into `~/.cache/proof-skills` and `~/.elan`. The Lean templates need no
Mathlib, so there is no 8 GB download. Quint and Apalache are optional.

## Usage

Just describe the problem:

```text
> Our connection pool sometimes goes over max connections and a request occasionally
  hangs in acquire(). Can you model it formally and fix it?

> Prove our DAG executor never starts a step before its dependencies finish — for every graph.

> cancel_order has a row lock AND a conditional UPDATE AND a post-check. What can we safely remove?
```

A bug hunt leaves this in your repo:

```
formal/
  findings.json              # machine-readable results (drives the report)
  <concern>/
    SCOPE.md                 # what is modeled, what is abstracted
    CORRESPONDENCE.md        # model element → file:line, plus the assumptions
    tla/  Spec.tla  Properties.tla  MC.cfg  MC_bug.cfg  MC_sanity.cfg
    lean/ lakefile.toml  <Pkg>/{System,Properties}.lean
    evidence/                # a saved log for every check the report cites
    repro/                   # reproductions, when you don't want new tests in your suite
  reports/<concern>.html     # local copy of the published Artifact
```

For each confirmed bug it also leaves a reproduction that fails on the original code for
the reason the model predicts, and passes after the fix. By default this is a regression
test next to your existing tests. If you ask for no new tests, it is a script in `repro/`.

## Why you can trust the results

The skills are built around the known failure modes of agent-written specs. Published
evaluations found that at most 8.6% of LLM-generated TLA+ specs are semantically correct,
and that agents tend to weaken their own success criteria. The skills counter this in
five ways:
- **Every model must be able to fail.** Each spec ships three configs: one where the fix is
  on and the check must pass, one where the fix is off and it must fail, and one where a
  reachability check must fail.
- **Every counterexample is reproduced in real code** before it is called a bug.
- **Properties are frozen and cited.** Any weakening is flagged in the report.
- **Bounds are always stated.** A passing check means "no counterexample within these
  bounds", never "correct".
- **The Lean trust audit is enforced:** 0 `sorry`, standard axioms only, and `native_decide`
  only when disclosed.

The shipped models are re-verified by `scripts/verify-assets.sh`. The current run shows 28
checks passing:
- 21 TLA+ pattern checks,
- 2 trace-validation checks,
- 4 simplification and refinement checks, and
- a Lean build with 24 theorems, 0 trust problems.

## Evaluation

The skills were benchmarked with the `skill-creator` plugin for Claude Code:
the same prompt was run with and without the skills on five buggy fixtures, and each run
was graded against objective assertions. Graders re-ran the model checks, proofs and tests
to confirm the claims.

| Fixture | Bug class | With skills | Without |
|---|---|---|---|
| Python asyncio webhooks | check-then-act across `await` → double capture | 13/13 | 6/13 |
| TypeScript job queue | stale lease holder clobbers results; SQL claim race | 15/15 | 9/15 |
| Go DAG executor | step dispatched before its dependency finishes | 14/14 | 8/14 |
| Python order service | simplification: remove the lock, remove the dead post-check | 15/15 | 9/15 |
| Rust connection pool | over-capacity race + two lost-wakeup hangs | 12/13 | 6/13 |
| **Mean (iteration 2, claude-opus-5-5)** | | **98%** | **54%** |

Both configurations find and fix the planted bugs. What the skills add is rigor you can
check:
- stated bounds;
- sanity checks on the fixed model;
- mutation checks at the same bounds;
- a model-to-code map;
- reproductions that fail for the right reason;
- saved logs for every claim;
- a structured report with diagrams.

The cost is about 2× the time and tokens.

The same fixtures also ship as a `claude plugin eval` suite, which runs the installed plugin
against a no-plugin baseline. There, a Haiku judge reads only the final message. The plugin
scores a mean 0.76 against 0.57 without it (Δ +0.19), and 1.0 on 76 of the 80 trigger cases.

The skill descriptions were also tuned for triggering. Each skill has 20 queries: requests
it should handle, and near misses it should skip. On the held-out split the chosen
descriptions score 7/8 (formal-verify), 8/8 (tlaplus-model), 8/8 (lean-model) and 7/7
(proof-simplify), with no false triggers. In the `claude plugin eval` run, one near miss did
trigger. Details are in
[`docs/stories/skill-evaluation-suite.md`](docs/stories/skill-evaluation-suite.md); the
prompts and fixtures are in [`plugins/proof-skills/evals/`](plugins/proof-skills/evals/).

## Repository layout

```
plugins/proof-skills/
  .claude-plugin/plugin.json
  skills/formal-verify/              orchestrator: workflows, correspondence, reproduction, report contract
  skills/tlaplus-model/              TLA+ skill: scripts/, assets/patterns/, references/
  skills/lean-model/                 Lean skill: scripts/, assets/{lean-patterns,template}/, references/
  skills/proof-simplify/             simplification skill: assets/tla/, references/
.claude/skills/*                     symlinks to the plugin skills (local development)
plugins/proof-skills/evals/          eval cases, prompts and five buggy fixtures (Python, TypeScript, Go, Rust)
scripts/verify-assets.sh             re-verify every shipped model
docs/                                design docs (OKF bundle): epic, stories, ADRs, runbooks, references
```

## Development

```bash
scripts/verify-assets.sh                       # all models behave as documented
claude plugin validate ./plugins/proof-skills  # manifest check

# plugin eval suite, from the repo root (cases generated by plugins/proof-skills/evals/make_cases.py)
claude plugin eval plugins/proof-skills --tag trigger --scaffold --ablation none -j 8 --threshold 0
claude plugin eval plugins/proof-skills --tag bughunt --scaffold --allow-tools Bash Write Edit --runs 1 -j 5 --threshold 0

quest board                                    # tracker: tasks PS-1..PS-12
lore check                                     # docs bundle consistency
```

The eval cases need `--scaffold`, because each one builds its starting repo. The bug-hunt
suite also needs `setup_tla.sh --with-jre` run once. Without `--threshold 0`, a run exits
non-zero if any case scores below 1.0. The trigger suite costs about $25 and the bug-hunt
suite about $14. See [Run plugin evals](docs/runbooks/run-plugin-evals.md).

Design decisions, runbooks, and the research behind the skills are in [`docs/`](docs/index.md).
Start with the [epic](docs/epics/formal-verification-skills.md) and the
[state-of-the-art summary](docs/reference/state-of-the-art-in-agent-driven-formal-verification.md).

## Known limitations

These are tracked in Quest (`quest task list`):
- **PS-9: four trigger misses.** Two formal-verify queries are answered directly without
  the skill, and one tlaplus-model query routes to a sibling skill. One proof-simplify near
  miss triggers when it shouldn't.
- **PS-10: bug-hunt graders are shallow.** In `claude plugin eval`, they judge only the final
  message, so the assertions about saved evidence always fail.
- **PS-11: no git inside eval runs.** The run sandbox blocks macOS `/usr/bin/git`.
- **PS-12: eval runs are shallower.** `claude plugin eval` runs take minutes, where the
  skill-creator runs took about 23 minutes. They are a regression signal, not a
  replacement for the skill-creator benchmark.

## Contributing

- Branch from `main`, and open a PR in
  [opum-ai/proof-skills](https://github.com/opum-ai/proof-skills). New
  patterns are especially welcome: a small spec or Lean file with a fix toggle and the three
  configs.
- Keep patterns tiny, and state their bounds and results in the pattern catalog.
- Before opening a PR, run `scripts/verify-assets.sh`, `claude plugin validate ./plugins/proof-skills` and
  `lore check`.
- Track work with `quest`, and write docs with `lore` (see `CLAUDE.md`).

## License

MIT. See [LICENSE](LICENSE).
