---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Identifies the root cause as check-then-act across await points: seen() check, then capture(), then mark(), letting concurrent deliveries of the same event both capture

FAIL if it is absent, only vaguely gestured at, or contradicted.
