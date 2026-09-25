---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

Can this race? Two pods run `reconcile()` in controllers/quota.go at the same time and both read the current usage from etcd before writing. I want a real answer, not a guess.
