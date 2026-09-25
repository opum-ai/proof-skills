# Correspondence: <concern>

Spec commit: `<git sha when this map was last verified against code>`

## Map

| Model element | Code | Kind | Abstraction | Notes |
|---|---|---|---|---|
| `ActionName(p)` | `path/to/file.ext:10-24` `function_name()` | action | what is merged or omitted | |
| `varName` | `path/to/file.ext:5` `self.field` | variable | domain reduced to {…} | |

## Assumptions

Facts about the environment that the model relies on. Each is a place a bug could hide.

- A1: …
- A2: …

## Granularity

State the atomicity rule used (for example, "one action per await-delimited block" or "one action per
locked section") and list any place where the model merges steps the code performs separately.
