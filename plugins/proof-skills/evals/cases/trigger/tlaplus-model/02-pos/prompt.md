---
description: 'Should trigger tlaplus-model'
tags: [trigger, tlaplus-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

write a TLA+ spec for our two-phase commit coordinator (coordinator.py + participant.py) with crash failures and check atomicity
