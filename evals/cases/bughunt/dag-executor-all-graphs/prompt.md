---
description: 'Bug hunt on the go-dag fixture'
tags: [bughunt, formal-verify]
runs: 1
max_turns: 200
timeout_seconds: 3600
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
append_system_prompt: 'This is an offline evaluation run. There is no Artifact tool and no user to ask: make reasonable choices yourself. Write any report to formal/reports/<concern>.html in the repo, and end with a final message that summarizes findings, fixes, what was verified (with bounds), and what was not. git does not work in this sandbox; that is expected.'
---

Our build graph executor (executor.go) occasionally starts a step before its dependency has finished. Find the bug, fix it, and give me a proof that the fixed scheduler respects dependencies for every possible graph, not just the ones in our tests.
