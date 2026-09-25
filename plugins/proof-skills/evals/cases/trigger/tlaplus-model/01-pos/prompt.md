---
description: 'Should trigger tlaplus-model'
tags: [trigger, tlaplus-model, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

TLC says 'Error: Invariant NoDoubleSpend is violated.' and dumps a trace: State 1: <Initial predicate> bal = 10 /\ pc = [a |-> "read", b |-> "read"]  State 2: <ReadA> seenA = 10  State 3: <ReadB> seenB = 10  State 4: <WriteA> bal = 0 /\ spent = 10  State 5: <WriteB> bal = 0 /\ spent = 20. what is actually happening in this trace and is it a real bug?
