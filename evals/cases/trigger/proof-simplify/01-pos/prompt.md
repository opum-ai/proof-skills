---
description: 'Should trigger proof-simplify'
tags: [trigger, proof-simplify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

we have a TLA+ model of our job leasing that passes. there's a lot of defensive code in worker/lease.go — double checks of ownership, a second lock. can we use the model to delete what's redundant?
