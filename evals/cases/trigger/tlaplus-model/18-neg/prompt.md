---
description: 'Near miss: should NOT trigger tlaplus-model'
tags: [trigger, tlaplus-model, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

fix the deadlock the Go race detector reported in cmd/server/main.go line 88 — the lock order is obvious from the stack trace
