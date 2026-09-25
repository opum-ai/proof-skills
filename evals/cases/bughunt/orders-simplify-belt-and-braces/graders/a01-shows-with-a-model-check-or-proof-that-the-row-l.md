---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Shows (with a model-check or proof) that the row lock alone does not prevent paid -> cancelled because the payment webhook path does not take the lock

FAIL if it is absent, only vaguely gestured at, or contradicted.
