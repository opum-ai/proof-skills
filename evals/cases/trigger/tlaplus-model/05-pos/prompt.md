---
description: 'Should trigger tlaplus-model'
tags: [trigger, tlaplus-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

liveness property EventuallyAllAcked fails in TLC with a stuttering counterexample even though every worker should keep running — what fairness am I missing
