---
description: 'Near miss: should NOT trigger formal-verify'
tags: [trigger, formal-verify, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

our postgres queries got slow after the last migration, EXPLAIN ANALYZE output attached, what index should I add
