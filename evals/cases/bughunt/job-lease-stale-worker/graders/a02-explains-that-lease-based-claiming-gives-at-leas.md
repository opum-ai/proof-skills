---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Explains that lease-based claiming gives at-least-once processing, so side effects can run twice and exactly-once side effects need idempotency/fencing downstream

FAIL if it is absent, only vaguely gestured at, or contradicted.
