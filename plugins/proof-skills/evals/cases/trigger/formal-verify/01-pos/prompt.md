---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

we keep getting duplicate emails from our notification worker, maybe 1 in 5k sends. its a python asyncio thing in services/notify/sender.py that checks redis for a sent-key then sends then sets the key. can you figure out formally whether it can double send and fix it
