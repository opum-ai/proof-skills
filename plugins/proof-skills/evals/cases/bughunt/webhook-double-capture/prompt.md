---
description: 'Bug hunt on the py-webhooks fixture'
tags: [bughunt, formal-verify]
runs: 1
max_turns: 200
timeout_seconds: 3600
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
append_system_prompt: 'This is an offline evaluation run. There is no Artifact tool and no user to ask: make reasonable choices yourself. Write any report to formal/reports/<concern>.html in the repo, and end with a final message that summarizes findings, fixes, what was verified (with bounds), and what was not. git does not work in this sandbox; that is expected.'
---

The payment provider retries webhooks and every couple of weeks we see a double capture in prod, but all our tests pass. Can you formally verify app/payments.py (and whatever it touches) and find what's going on? Fix it if you find something.
