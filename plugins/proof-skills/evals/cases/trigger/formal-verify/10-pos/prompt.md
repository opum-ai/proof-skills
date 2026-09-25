---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

we lose messages occasionally in our kafka -> transform -> s3 pipeline when a pod restarts mid-batch. code is in pipeline/sink.py. help me find exactly where with a formal model
