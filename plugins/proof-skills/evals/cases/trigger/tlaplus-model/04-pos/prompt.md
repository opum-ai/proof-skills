---
description: 'Should trigger tlaplus-model'
tags: [trigger, tlaplus-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

model this in PlusCal: three workers pull from a shared queue with visibility timeouts, a message can be redelivered if the ack is late
