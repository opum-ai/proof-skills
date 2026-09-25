# What the evidence says (September 2026)

This is research that informed these skills. Use it to set expectations with users, and to
explain why the workflow insists on certain steps.

## Agent-driven formal verification works when it has feedback from outside the model

- **Boris Cherny (Anthropic), 2026-09-22:** used Claude Opus 5.5 with Lean to formally verify
  the Claude Agent SDK. "A couple short prompts = 16 PRs fixing various bugs and race
  conditions." He also uses TLA+, sometimes combined with Lean, "to look for issues around
  data flow, concurrency, and state mgmt." His point is that you need not know either
  language well. The prompts and PRs are not public. https://x.com/bcherny/status/2102543349102338309
- **Specula (UIUC, 2026; winner of the TLA+ Foundation / NVIDIA GenAI challenge).** Agents
  turn code into TLA+, validate the spec against runtime traces, model-check it, then
  reproduce each violation with a timing-controlled test.
  - Results: 249 bugs across 48 systems in 7 languages, 207 of them previously unknown.
  - 98.5% of reported bugs were reproduced, with 0 false positives.
  - Median counterexample 9 steps (p90 18); BFS found 93.5% of them.
  - Cost: a median of $57 per system.
  - Ablation: the full pipeline found 62 bugs on 5 systems; a TLA+-only agent found 3.

  The gains come from runtime feedback and reproduction.
  https://arxiv.org/abs/2607.25333 · https://github.com/specula-org/Specula
- **Plain text → TLA+ is weak without checks.** Across 30 LLMs, at most 26.6% of generated
  specs parsed and 8.6% were semantically correct. https://arxiv.org/abs/2606.05792
- **Hillel Wayne (2025).** LLMs are excellent at TLA+ syntax, `UNCHANGED` bookkeeping, and
  explaining long traces. They are poor at proposing properties, and they "fix" specs by
  assuming the race away. https://buttondown.com/hillelwayne/archive/ai-is-a-gamechanger-for-tla-users/
- **Agentic Proving (2026).** Frontier agents with Lean LSP tooling reached 98.1% end-to-end
  on the CLEVER verified-code benchmark. https://arxiv.org/abs/2605.23772

## Industrial practice

- **AWS.** TLA+ since 2011; the P language, Dafny, Kani, and Lean today. Formal methods
  enabled S3's move to strong consistency. Cedar pairs Lean models about 10× smaller than
  the Rust with nightly differential testing.
  https://cacm.acm.org/practice/systems-correctness-practices-at-amazon-web-services ·
  https://aws.amazon.com/blogs/opensource/lean-into-verified-software-development/
- **Azure Cosmos DB.** Small specs of the client-visible consistency levels found
  documentation errors and helped during an outage. https://arxiv.org/abs/2210.13661
- **MongoDB.**
  - Trace-checking Raft failed after 10 weeks. The spec's atomicity (step-down plus step-up
    in one action) did not match the code.
  - Tests generated from the spec reached 100% branch coverage of the modeled code, against
    21% for handwritten tests and 92% for AFL.

  https://www.mongodb.com/company/blog/engineering/conformance-checking-at-mongodb-testing-our-code-matches-our-tla-specs
- **Datadog.** TLA+ for idempotency and replication, with deterministic simulation as "the
  workhorse". Specs derived from ADRs serve as agents' maps.
  https://www.datadoghq.com/blog/engineering/formal-modeling-and-simulation/
- **Microsoft CCF.** "Smart casual verification": trace validation of the C++ against TLA+
  in CI found 6 bugs. https://www.usenix.org/conference/nsdi25/presentation/howard
- **TigerBeetle.** Relies on deterministic simulation (VOPR) over TLA+ refinement: "TLA+
  debugs the algorithm, not the code."

## How the evidence shaped these skills

| Evidence | Rule in these skills |
|---|---|
| Agents propose weak properties and edit their own success criteria | Harvest properties with citations; freeze them; report every change |
| Unvalidated specs are often wrong | Sanity invariants that must fail, bug toggles, coverage |
| Runtime feedback is what finds real bugs | Reproduce every counterexample in code; trace validation; differential testing |
| Atomicity mismatch wrecks conformance | Granularity rule: one action per atomic region; split by default |
| Small bounds find most bugs (median 9 steps) | Start with 2 actors and tiny domains; grow one bound at a time |
| Small models are affordable to prove and to keep current | Scope one concern; the correspondence map; drift checks |
