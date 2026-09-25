---
description: 'Should trigger proof-simplify'
tags: [trigger, proof-simplify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

do we still need the mutex in CacheWarmer.refresh()? the spec in formal/cache/ says only the scheduler thread ever calls it
