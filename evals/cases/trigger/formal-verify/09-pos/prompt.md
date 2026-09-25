---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

is `TokenBucket.take()` in lib/ratelimit.ts thread safe? it's called from worker_threads and I'm seeing more requests through than the limit allows
