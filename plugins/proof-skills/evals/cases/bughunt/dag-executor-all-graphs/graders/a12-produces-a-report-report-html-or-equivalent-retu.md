---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Produces a report (report.html or equivalent returned report) containing: verdict with bounds, per-finding trace mapped to code, what was verified, assumptions/scope, trust base, and re-run commands

FAIL if it is absent, only vaguely gestured at, or contradicted.
