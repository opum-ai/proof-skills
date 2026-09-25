---
description: 'Should trigger proof-simplify'
tags: [trigger, proof-simplify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

after the bug hunt last week our webhook handler has both a dedup claim and an idempotency key. the model says the key alone is enough — should we remove the claim and how do we prove it's safe
