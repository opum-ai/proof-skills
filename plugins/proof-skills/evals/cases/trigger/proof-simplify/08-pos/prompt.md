---
description: 'Should trigger proof-simplify'
tags: [trigger, proof-simplify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

is the `if already_applied: return` guard in apply_migration() dead code given the proven invariant in formal/migrations/Properties.lean?
