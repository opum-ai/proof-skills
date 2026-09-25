---
description: 'Should trigger lean-model'
tags: [trigger, lean-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

prove that the topological sort in scheduler/topo.rs always produces an order consistent with the edges, for every DAG
