---
description: 'Should trigger lean-model'
tags: [trigger, lean-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

prove in Lean that our interval merge function in lib/intervals.py never loses coverage — I'll accept a model of it, just keep the model faithful
