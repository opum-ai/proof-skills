---
description: 'Near miss: should NOT trigger formal-verify'
tags: [trigger, formal-verify, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

write hypothesis property-based tests for my JSON parser in parser/json.py
