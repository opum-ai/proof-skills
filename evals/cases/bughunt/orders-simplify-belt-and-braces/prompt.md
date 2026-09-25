---
description: 'Bug hunt on the py-orders fixture'
tags: [bughunt, proof-simplify]
runs: 1
max_turns: 200
timeout_seconds: 3600
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
append_system_prompt: 'This is an offline evaluation run. There is no Artifact tool and no user to ask: make reasonable choices yourself. Write any report to formal/reports/<concern>.html in the repo, and end with a final message that summarizes findings, fixes, what was verified (with bounds), and what was not. git does not work in this sandbox; that is expected.'
---

cancel_order in orders/service.py has a row lock AND a conditional update AND a post-check, all bolted on after an old incident. Use formal methods to work out what we can safely simplify here, then do it.
