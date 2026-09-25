---
description: 'Should trigger proof-simplify'
tags: [trigger, proof-simplify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

our Lean proof shows the `pending` and `queued` states behave identically — can we merge them in the OrderStatus enum and delete the transitions between them?
