---
description: 'Should trigger proof-simplify'
tags: [trigger, proof-simplify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

simplify the retry loop in sync/replicator.ts — I think half the branches can't happen but I want proof before I delete anything
