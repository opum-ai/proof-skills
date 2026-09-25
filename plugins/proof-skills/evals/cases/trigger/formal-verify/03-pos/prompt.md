---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

review PR #482 in our payments repo for concurrency issues — it changes the refund flow to use a background job and I'm nervous about double refunds
