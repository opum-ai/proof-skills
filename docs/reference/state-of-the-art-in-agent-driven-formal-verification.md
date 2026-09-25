---
# yaml-language-server: $schema=../../.lore/schemas/reference.schema.json
type: Reference
title: State of the art in agent-driven formal verification
summary: "Research summary (September 2026) on LLM agents doing TLA+ and Lean verification of real software, industrial practice, tooling, and how each finding shaped the skills."
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.652Z
---

# State of the art in agent-driven formal verification

Research carried out on 2026-09-22 for this project. The agent-facing condensed version is
`plugins/proof-skills/skills/formal-verify/references/evidence.md`.

## Details

### The prompt

Boris Cherny (Anthropic) posted on 2026-09-22:

> "I used Opus 5.5 to formally verify the Claude Agent SDK using Lean. A couple short prompts
> = 16 PRs fixing various bugs and race conditions. … TLA+ also works well. I sometimes
> combine Lean and TLA+ to look for issues around data flow, concurrency, and state mgmt.
> I don't know either language well, but Claude is excellent at both."

The prompts and PRs are not public (none are visible in the public Agent SDK repos). The
skills therefore generalize from published methods rather than copying a recipe.

### Agent pipelines and benchmarks

| Work | Result | Lesson used |
|---|---|---|
| Specula (UIUC, arXiv 2607.25333, Aug 2026) | 249 bugs / 48 systems / 7 languages; 207 new; 98.5% reproduced; 0 false positives; median $57 per system; the full pipeline found 62 bugs on 5 systems against 3 for a TLA+-only agent | Runtime feedback plus reproduction is what matters. Median counterexample 9 steps, so small bounds are enough |
| LLM → TLA+ evaluation (arXiv 2606.05792) | ≤ 26.6% of specs parse, ≤ 8.6% semantically correct, across 30 models | Treat every spec as a hypothesis; sanity checks |
| Hillel Wayne (2025) | Good at syntax, `UNCHANGED`, trace explanation; bad at properties; "fixes" specs unrealistically | Harvest and freeze properties; forbid silent model weakening |
| TraceFix (arXiv 2605.07935) | PlusCal protocols repaired from TLC counterexamples within ≤ 4 rounds | The counterexample → fix loop converges |
| OmniLink (arXiv 2601.11836) | Trace validation of unmodified concurrent code | Trace validation as a drift defense |
| Agentic Proving (arXiv 2605.23772) | 98.1% end-to-end on CLEVER with Lean LSP tooling | lean-lsp-mcp is worth installing |
| Rust → Lean experience report (arXiv 2605.30106) | Toolchain drift is the top friction | Pin toolchains and dependency tags together |

### Industrial practice

| Organization | Practice |
|---|---|
| AWS | TLA+ since 2011; P, Dafny, Kani, Lean. Cedar pairs Lean models about 10× smaller than the Rust with nightly differential testing |
| Azure Cosmos DB | Consistency-level specs found documentation errors and helped in an outage |
| MongoDB | Trace-checking Raft failed on atomicity mismatch. Spec-generated tests reached 100% branch coverage (handwritten 21%, AFL 92%) |
| Datadog | TLA+ plus deterministic simulation; ADR-derived specs as agents' maps |
| Microsoft CCF | Trace validation in CI; 6 bugs found |
| TigerBeetle | Deterministic simulation over TLA+ refinement |

### Tooling (verified September 2026)

| Tool | State |
|---|---|
| TLC | tla2tools v1.8.0; nightly 2026.09. `-dumpTrace json`; exit codes 0/10/11/12/13/150 (13 also covers action properties) |
| Apalache | SMT bounded checking, inductive invariants; types required |
| Quint | 0.32.0; `run`, `verify`, `--mbt`; quint-connect for Rust |
| TLA+ agent tooling | VS Code extension MCP server; tlaplus/AgentSkills; Specula skills |
| Lean | 4.34.0 stable. `grind`, `bv_decide` (LeanSAT in core), `mvcgen`, `decide +kernel`; plausible v4.34.0 |
| Lean agent tooling | lean-lsp-mcp; Aristotle (hosted); Goedel-Prover-V2 (open, maths-tuned) |
| Lean frameworks | Veil (transition systems, SMT, on 4.32); Iris-Lean (separation logic); Loom/Velvet |

### Sources

- Cherny post: https://x.com/bcherny/status/2102543349102338309
- Specula: https://arxiv.org/abs/2607.25333, https://github.com/specula-org/Specula; critique: http://muratbuffalo.blogspot.com/2026/08/specula-scaling-formal-specifications.html
- https://arxiv.org/abs/2606.05792 · https://arxiv.org/abs/2605.07935 · https://arxiv.org/abs/2601.11836 · https://arxiv.org/abs/2605.23772 · https://arxiv.org/abs/2605.30106
- https://buttondown.com/hillelwayne/archive/ai-is-a-gamechanger-for-tla-users/
- Trace validation: https://arxiv.org/abs/2404.16075 · CCF: https://www.usenix.org/conference/nsdi25/presentation/howard
- AWS: https://cacm.acm.org/practice/systems-correctness-practices-at-amazon-web-services · Cedar: https://aws.amazon.com/blogs/opensource/lean-into-verified-software-development/
- Cosmos DB: https://arxiv.org/abs/2210.13661 · MongoDB: https://www.mongodb.com/company/blog/engineering/conformance-checking-at-mongodb-testing-our-code-matches-our-tla-specs
- Datadog: https://www.datadoghq.com/blog/engineering/formal-modeling-and-simulation/
- TLC docs: https://github.com/tlaplus/tlaplus/blob/master/general/docs/current-tools.md · Apalache: https://apalache-mc.org · Quint: https://quint.sh
- Lean: https://lean-lang.org/doc/reference/latest/ · plausible: https://github.com/leanprover-community/plausible · lean-lsp-mcp: https://github.com/oOo0oOo/lean-lsp-mcp · Veil: https://github.com/verse-lab/veil
