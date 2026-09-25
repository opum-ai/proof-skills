---
description: 'Near miss: should NOT trigger proof-simplify'
tags: [trigger, proof-simplify, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

is it safe to remove the retry around the S3 upload? we've never seen it fail
