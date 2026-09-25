---
type: llm
focus: last_message
---

You are grading the final report of an agent that investigated a codebase. PASS if the report states or shows the following, with specifics (names, files, numbers, commands or results) rather than a vague claim:

A model checker or prover (TLC, Apalache, Quint, or Lean) was actually run and produced a counterexample for the original code

FAIL if it is absent, only vaguely gestured at, or contradicted.
