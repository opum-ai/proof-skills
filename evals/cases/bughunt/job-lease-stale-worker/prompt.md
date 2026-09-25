---
description: 'Bug hunt on the ts-job-queue fixture'
tags: [bughunt, formal-verify]
runs: 1
max_turns: 200
timeout_seconds: 3600
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
append_system_prompt: 'This is an offline evaluation run. There is no Artifact tool and no user to ask: make reasonable choices yourself. Write any report to formal/reports/<concern>.html in the repo, and end with a final message that summarizes findings, fixes, what was verified (with bounds), and what was not. git does not work in this sandbox; that is expected.'
---

Can you prove our job queue never lets a job's result get clobbered or processed twice? Lease logic is in src/store.ts and src/worker.ts. I want an actual proof or a concrete counterexample, not more unit tests.
