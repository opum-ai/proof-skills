---
description: 'Should trigger tlaplus-model'
tags: [trigger, tlaplus-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

can you write a quint spec for our CRDT counter merge and run the simulator to look for a divergence
