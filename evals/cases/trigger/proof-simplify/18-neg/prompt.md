---
description: 'Near miss: should NOT trigger proof-simplify'
tags: [trigger, proof-simplify, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

clean up the error handling in api/handlers.go, there's too much copy paste
