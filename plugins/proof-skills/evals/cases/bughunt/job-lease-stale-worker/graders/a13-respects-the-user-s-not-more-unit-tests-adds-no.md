---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

Respects the user's 'not more unit tests': adds no new unit-test files to the repo's test suite; reproductions live outside it (e.g. formal/<concern>/repro/)

FAIL if it is absent, only vaguely gestured at, or contradicted.
