---
description: 'Should trigger tlaplus-model'
tags: [trigger, tlaplus-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

I want to replay our production event logs through the spec to see if the implementation ever does something the spec forbids
