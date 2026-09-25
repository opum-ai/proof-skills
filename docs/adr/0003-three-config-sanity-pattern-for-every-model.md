---
# yaml-language-server: $schema=../../.lore/schemas/adr.schema.json
type: ADR
title: Three-config sanity pattern for every model
summary: "Every shipped TLA+ model carries MC.cfg (must pass), MC_bug.cfg (fix off, must fail), and MC_sanity.cfg (reachability, must fail); Lean models carry a non-vacuity witness and a trust audit."
tags:
  - architecture
generated:
  by: lore/0.8.0
  at: 2026-09-23T02:24:13.141Z
---

# Three-config sanity pattern for every model

## Status

Accepted (2026-09-22)

## Context

The published evidence agrees on the main failure mode of agent-written specs: they pass
because they cannot fail.
- At most 26.6% of LLM-generated TLA+ specs parse, and 8.6% are semantically correct.
- Agents propose trivial properties, and "fix" specs by assuming the race away.

Four things can each make a green run meaningless:
- a model where the interesting state is unreachable,
- an implication with a false premise,
- a fix toggle that is not wired in, and
- fairness added to make liveness pass.

## Decision

Each TLA+ model has three configs:
- `MC.cfg`: the fix on and all properties checked. It must exit 0.
- `MC_bug.cfg`: the fix off. It must fail the target property (exit 12 for an invariant,
  13 for liveness or an action property).
- `MC_sanity.cfg`: a reachability invariant that must be violated (exit 12).

Lean models prove a non-vacuity witness (a path checked by `decide`) and pass
`check_trust.sh` (no sorry, standard axioms only).

`scripts/verify-assets.sh` enforces this for every shipped model: 27 TLC checks plus the
Lean audit. CI templates carry a "bug-mode configs must fail" job.

## Consequences

- Every pattern proves it can detect its own bug.
- Models cost slightly more to write, and the extra configs are cheap to run (well under
  a second each at the shipped bounds).
- User projects get the same structure (`formal-verify` W5 regression guard).
