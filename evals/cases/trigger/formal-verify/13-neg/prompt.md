---
description: 'Near miss: should NOT trigger formal-verify'
tags: [trigger, formal-verify, negative]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

my pytest suite is flaky on CI only — tests/test_api.py::test_upload times out randomly. can you look at the fixture setup?
