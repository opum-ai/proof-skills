---
description: 'Should trigger lean-model'
tags: [trigger, lean-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

lake build succeeds but I want to make sure there's no sorry or sneaky axiom anywhere in formal/lean before we claim it's verified
