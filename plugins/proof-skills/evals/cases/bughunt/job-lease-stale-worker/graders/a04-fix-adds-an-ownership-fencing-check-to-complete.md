---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Fix adds an ownership/fencing check to complete (e.g. WHERE owner = $worker AND token = $token, or a monotonically increasing token) and the stale path is rejected

FAIL if it is absent, only vaguely gestured at, or contradicted.
