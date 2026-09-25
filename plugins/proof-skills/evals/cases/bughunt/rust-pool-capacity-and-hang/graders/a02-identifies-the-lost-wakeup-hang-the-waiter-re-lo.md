---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Identifies the lost-wakeup/hang: the waiter re-locks and waits after checking (notification can land in between) and/or release notifies before decrementing

FAIL if it is absent, only vaguely gestured at, or contradicted.
