---
description: 'Near miss: should NOT trigger formal-verify'
tags: [trigger, formal-verify, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

fix the type errors in src/scheduler.ts after upgrading to typescript 6
