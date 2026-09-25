---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Every check the report claims (model runs, sanity checks, coverage, mapping check, test runs before/after) has a saved log file in the repo; nothing is claimed without a log

FAIL if it is absent, only vaguely gestured at, or contradicted.
