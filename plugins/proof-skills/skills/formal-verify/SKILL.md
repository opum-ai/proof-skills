---
name: formal-verify
description: End-to-end formal-methods bug hunting for real codebases in any language — scope a risky concern, model it in TLA+ and/or Lean 4, check it, turn every counterexample into a failing test, fix the code, re-verify, and publish the results as an Artifact report. Use this skill whenever the user wants to find race conditions, lost updates, deadlocks, stale caches, double-applied retries, broken idempotency, message reordering or loss bugs, state-machine violations, dataflow/pipeline loss or duplication, or graph/DAG/scheduler bugs; whenever they say "formally verify", "model check", "prove", "TLA+", "Lean", "invariant", "spec this out", "is this thread-safe", "can this race", or ask for a concurrency/async/distributed review of a module or PR — even if they never name a formal-methods tool. Also the entry point for keeping specs in CI and detecting spec/code drift. Routes to tlaplus-model, lean-model, and proof-simplify for the tool-specific work.
---

# formal-verify

Formal models find bugs that tests and reviewers miss because they explore *every*
interleaving and *every* small input, not the handful someone thought of. An agent
can now write the models quickly; the hard parts are choosing what to model, keeping the
model honest to the code, and proving a counterexample is real. This skill owns those
parts. The tool-specific mechanics live in sibling skills:

| Skill | Use it for |
|---|---|
| `tlaplus-model` | Interleavings, message passing, retries, liveness, protocols. Exhaustive on small models (TLC) or bounded-symbolic (Apalache/Quint). |
| `lean-model` | Pure logic and data structures, graph algorithms, state machines needing *unbounded* proofs, executable reference models for differential testing. |
| `proof-simplify` | After something is verified: use the proven invariants to delete redundant code, then re-verify. |

Shared material for all four skills sits in this skill's `references/`. Sibling skills
reach it at `${CLAUDE_SKILL_DIR}/../formal-verify/references/`.

## Pick the workflow

Read `references/workflows.md` for the full step list of each. Match the request:

| The user wants… | Workflow |
|---|---|
| "Find bugs / races in X", "is this safe under concurrency" | **W1 Bug hunt** (default) |
| "Review this PR/diff for races" | **W2 Change review** — model only the delta and what it touches |
| "Check this design / protocol before we build it" | **W3 Design verification** — no code yet; spec is the design |
| "Simplify this using the proofs", "is this lock/check needed" | **W4 Proof-guided simplification** → `proof-simplify` |
| "Keep this verified", "add the spec to CI" | **W5 Regression guard** |
| "The code changed — is the spec still right?" | **W6 Drift check** |
| "Prove it for all N", "TLC passed but I want certainty" | **W7 Escalate TLA+ → Lean** |
| "Explain this counterexample / TLC trace" | **W8 Explain a trace** |

## W1 Bug hunt — the core loop

Each step exists because skipping it is how formal-methods efforts fail in practice.

1. **Scope one concern.** Pick one shared resource or protocol ("cache fill vs.
   invalidation", "job claim vs. lease expiry", "DAG executor dispatch"). Rank candidates by
   blast radius × concurrency. Write a short scope note (in scope, abstracted, out of scope).
   A whole-system model never converges; a 150-line spec of one concern finds the bug.
2. **Harvest properties before modeling.** Pull invariants from docs, comments,
   issue trackers, past fix commits, and API contracts. Cite a source for each
   (`README.md:40`, `#1234`). Split them into *protocol-level* properties (any correct
   implementation must satisfy them) and *code-level* ones. Freeze the protocol-level set
   in its own file (`Properties.tla` / `Properties.lean`) and do not weaken it later
   without the user's explicit OK. Agents that edit their own success criteria "find" no bugs.
3. **Choose the tool.** Use `references/choosing-tools.md`. Default: TLA+ for
   anything with interleavings; Lean for algorithmic/data-structure correctness or when an
   unbounded proof is wanted; both when a protocol wraps a non-trivial algorithm.
4. **Build the correspondence map as you model.** Every model action/function gets a
   row pointing to `file:line` in the source and stating what was abstracted
   (`references/correspondence.md`, template in `assets/CORRESPONDENCE.md`). This is what
   turns a counterexample into a code-level explanation, and what W6 drift checks read.
5. **Model and check** via `tlaplus-model` or `lean-model`. Always run the sanity checks
   those skills describe (must-fail invariants, action coverage, mutation of a guard).
   A spec that cannot fail proves nothing.
6. **Reproduce every counterexample in real code** before calling it a bug
   (`references/reproduce-and-fix.md`). Write a deterministic reproduction that forces the
   trace's interleaving (barriers, injected delays, fake clocks, controllable executors).
   Run it against the **unchanged** code and save the failing log first. It must fail on the
   property assertion, not on an API or signature change. Honor the user's stated deliverable:
   if they said "no more unit tests", put the reproduction in `formal/<concern>/repro/` as a
   script instead of adding it to their test suite. If it will not reproduce, fix the model,
   not the verdict. Record unreproduced traces as *suspected*, never as bugs.
7. **Fix, then re-verify.** Fix the code, mirror the fix in the model, re-run the model
   and the new test. Mutation-check the fix: revert it in the model and confirm the
   property fails again. This proves the property actually guards the bug.
8. **Record and report.** Keep a log of every check you cite in `formal/<concern>/evidence/`:
   TLC or Lean output, coverage, `correspondence_check.py`, mutation runs, and test runs
   before and after the fix. Report other problems you noticed along the way (for example, an
   input the code silently mishandles) as separate findings, and do not fix them without
   asking. Write findings to `formal/findings.json`
   (schema: `assets/findings.schema.json`), then publish the Artifact report
   (next section). Offer W4 (simplify) and W5 (CI guard) as follow-ups.

**Match the depth to the question.** One scoped model, the sanity checks, one reproduction,
and the report is the floor. Add a second tool (for example, Lean after TLA+) only when the
user asks for an unbounded guarantee, or when the bounded result leaves a real doubt.

Keep the user informed at step boundaries. Ask before step 7 if the fix is non-obvious,
touches public API, or has several reasonable designs.

## Where files go in the target project

```
formal/
  README.md                     # what is modeled, how to run it (keep short)
  findings.json                 # machine-readable results; drives the report
  <concern>/                    # one directory per scoped concern, kebab-case
    SCOPE.md                    # scope note from step 1
    CORRESPONDENCE.md           # model ↔ code map from step 4
    tla/ Spec.tla Properties.tla MC.cfg MC_live.cfg
    lean/ lakefile.toml lean-toolchain <Pkg>/Model.lean <Pkg>/Properties.lean
    repro/                      # reproductions kept out of the user's test suite, if asked
    evidence/                   # saved logs for every check the report cites
  reports/                      # local copy of each published report (HTML)
```

Adapt to an existing convention if the repo has one (`specs/`, `tla/`, `proofs/`).

## Report: publish as an Artifact

Results go to the user as a published Artifact page, not as terminal scroll. Follow
`references/report-artifact.md` for the required content. In short:

1. Load the `artifact-design` skill (page contract, theming, layout). Load
   `artifact-diagramming` too. Any concern with a shape (a graph, DAG, state machine, or
   protocol topology) gets a diagram with the counterexample highlighted:
   `scripts/graph_svg.py` renders one from a small JSON spec.
2. Build one HTML page from `formal/findings.json`: verdict summary first, then one
   section per finding (property violated, minimal trace, code mapping, reproduction test,
   fix), then what was verified, the trust base, and the exact commands to re-run.
3. Publish with the Artifact tool and save a copy to `formal/reports/`. On republish of
   the same concern, reuse the same file path so the URL stays stable.

If no Artifact tool exists in this environment, write the same page to
`formal/reports/<date>-<concern>.html` and say so. When running as a subagent that may not
publish or write report files, put the report's content (verdict, findings with traces,
what was verified with bounds, trust base, re-run commands) in the final message, so the
parent session can publish it.

## Honesty rules

- Say exactly what was checked: model bounds (e.g. "2 workers, 3 jobs, ≤2 retries"),
  states explored, depth, which properties, which `sorry`/axioms remain. "Verified" without
  bounds is a false claim.
- A passing check means "no counterexample within this model", not "the code is correct".
  Name the abstractions that could hide a bug.
- Never report a counterexample as a bug until step 6 reproduced it.
- Never weaken a frozen property, add a state constraint, or add fairness to make a
  check pass without flagging it in the report as a model change.

## Toolchains

Run `scripts/doctor.sh` to see what is installed. The tool skills carry install scripts:
`tlaplus-model/scripts/setup_tla.sh` (Java 11+, tla2tools.jar, community modules) and
`lean-model/scripts/setup_lean.sh` (elan, Lean toolchain). Ask before installing anything
system-wide; the scripts default to a project-local or user-cache location.

## Reference files

- `references/workflows.md` — W1–W8 step lists, entry/exit criteria, hand-offs.
- `references/choosing-tools.md` — TLA+ vs Lean vs Quint vs "just write a stress test".
- `references/correspondence.md` — how to map model ↔ code and keep it current.
- `references/reproduce-and-fix.md` — trace → deterministic test, per language/runtime.
- `references/report-artifact.md` — report content contract and publishing steps.
- `references/ci-and-drift.md` — CI jobs, budgets, drift detection (W5, W6).
- `references/evidence.md` — what the published evidence says works, with sources.
