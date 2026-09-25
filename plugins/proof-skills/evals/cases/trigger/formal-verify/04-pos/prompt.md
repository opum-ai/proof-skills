---
description: 'Should trigger formal-verify'
tags: [trigger, formal-verify, positive]
runs: 2
max_turns: 6
timeout_seconds: 150
allowed_tools: [Read, Glob, Grep, Skill]
---

Our Kotlin inventory service sometimes oversells the last unit during flash sales. Stock check is `if (stock > 0) decrement()` in InventoryService.kt. Please model it and prove the fix.
