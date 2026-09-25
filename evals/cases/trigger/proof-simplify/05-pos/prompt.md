---
description: 'Should trigger proof-simplify'
tags: [trigger, proof-simplify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

the invariant says claimed_by is non-null iff status == CLAIMED. can we encode that in the types and delete the runtime checks scattered around jobs/*.py?
