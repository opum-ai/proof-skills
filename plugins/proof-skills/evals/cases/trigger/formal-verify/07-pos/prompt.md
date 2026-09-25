---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

the spec in formal/cache-coherence/ was written 4 months ago and a bunch of code in cache/ changed since. is the model still accurate?
