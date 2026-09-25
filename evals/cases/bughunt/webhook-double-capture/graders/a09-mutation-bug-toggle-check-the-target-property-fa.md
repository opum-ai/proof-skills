---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Mutation/bug-toggle check: the target property FAILS on the unfixed model and PASSES on the fixed one at the SAME bounds, with saved tool output for both

FAIL if it is absent, only vaguely gestured at, or contradicted.
