---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Ran a sanity/non-vacuity check on the FIXED (or simplified) model itself — a must-fail invariant, reachability witness, or coverage run, not just a bug toggle — and saved its tool output

FAIL if it is absent, only vaguely gestured at, or contradicted.
