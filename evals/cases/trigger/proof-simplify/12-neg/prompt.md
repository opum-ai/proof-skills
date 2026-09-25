---
description: 'Near miss: should NOT trigger proof-simplify'
tags: [trigger, proof-simplify, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

delete the feature flag `new_checkout` and its code paths, it's been at 100% for months
