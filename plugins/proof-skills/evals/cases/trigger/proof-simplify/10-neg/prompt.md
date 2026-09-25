---
description: 'Near miss: should NOT trigger proof-simplify'
tags: [trigger, proof-simplify, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

remove unused imports and dead functions across the repo — just use the linter
