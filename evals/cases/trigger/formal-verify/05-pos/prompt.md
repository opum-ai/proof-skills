---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

I have a DAG runner in rust (crates/runner/src/sched.rs) that sometimes deadlocks when a task fails and gets retried. find out why with whatever formal tools make sense
