---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Adds a Go regression test with workers >= 2 that fails on the unchanged original code on the property assertion (not an API/signature error) and passes after the fix, run with go test -race

FAIL if it is absent, only vaguely gestured at, or contradicted.
