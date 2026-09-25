---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

before we build it: here's our design doc for leader election with leases in Postgres (docs/rfc/017-leader.md). check whether two leaders can ever be active at once
