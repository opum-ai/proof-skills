---
description: 'Should trigger lean-model'
tags: [trigger, lean-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

model the retry logic in our webhook dispatcher as a transition system in Lean and prove at-most-once delivery by induction
