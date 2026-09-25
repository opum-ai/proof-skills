# TLC, SANY, PlusCal: command-line reference

Checked against tla2tools v1.8.0 and the 2026-09 nightly (`TLC2 Version 2026.09.x`).

## Commands

```bash
CP=tla2tools.jar:CommunityModules-deps.jar          # community modules optional
java -cp $CP tla2sany.SANY Spec.tla                  # parse + level-check (exit 0 ok, 255 error)
java -cp $CP pcal.trans -nocfg Spec.tla              # PlusCal -> TLA+ (in place, between BEGIN/END TRANSLATION)
java -XX:+UseParallelGC -cp $CP tlc2.TLC -workers auto -config MC.cfg Spec.tla
java -cp $CP tlc2.REPL                               # evaluate expressions interactively
```

## TLC flags that matter

| Flag | Effect |
|---|---|
| `-workers N\|auto` | worker threads (default 1) |
| `-config F` | config file (default `<Spec>.cfg`) |
| `-deadlock` | **disable** the deadlock check (prefer an explicit `Terminated` action) |
| `-dumpTrace json F` | write the counterexample as JSON: `counterexample.action[i] = [[n, state], {name, location, context, parameters}, [n+1, state]]`. Other formats: `tla`, `tlc`, `tlcplain`, `tlcTESpec`, `tlcaction`, `dot` |
| `-difftrace` | print only the changed variables per state |
| `-simulate [num=N,file=F,stats=full]` | random behaviors instead of BFS; pair with `-depth N` (default 100) and `-seed` |
| `-coverage M` | per-action coverage every M minutes; look for actions with 0 distinct states |
| `-continue` | keep going after a violation (collect several) |
| `-dfid N` | depth-first iterative deepening |
| `-fpmem F`, `-metadir D`, `-checkpoint M`, `-recover D` | memory, state dir, checkpointing |
| `-lncheck final` | check liveness once at the end (faster on big graphs) |
| `-maxSetSize N` | enlarge the enumerable set limit (default 1e6) |
| `-postCondition Mod!Op` | same as the `POSTCONDITION` keyword |
| `-inv expr` | ad-hoc invariant without editing the config |

## Config (`.cfg`) keywords

`SPECIFICATION Spec` or `INIT Init` + `NEXT Next` · `CONSTANT(S) X = {a, b}` (bare identifiers
are model values; `"s"` strings and numbers are allowed) · `INVARIANT(S)` · `PROPERTY/PROPERTIES`
(temporal and action properties) · `SYMMETRY Perms` (with `Perms == Permutations(S)`, `EXTENDS TLC`;
safety only) · `CONSTRAINT` (state constraint that prunes exploration; report it) · `ACTION_CONSTRAINT` ·
`VIEW` (fingerprint projection) · `ALIAS` (a record of derived values shown in traces) · `POSTCONDITION` ·
`CHECK_DEADLOCK FALSE`.

## Exit codes (verified)

| Code | Meaning |
|---|---|
| 0 | no violation within bounds |
| 10 | ASSUME false, or POSTCONDITION false (for example, a trace rejected in trace validation) |
| 11 | deadlock |
| 12 | invariant violated |
| 13 | temporal property **or action property** violated |
| 14 | evaluation error / failed `Assert` |
| 150+ | parse, semantic, or config error |

## Performance checklist

1. Use the smallest constants that still show the behavior (2 actors).
2. Replace large sets with small symbolic ones; avoid `SUBSET` of anything bigger than about 6 elements.
3. Use `SYMMETRY` over interchangeable model values (safety configs only).
4. Use a `VIEW` that drops history or auxiliary variables from fingerprints.
5. Merge steps that cannot interleave meaningfully. Only merge after arguing why, and record it in CORRESPONDENCE.md.
6. Split into several scenario configs rather than one giant one.
7. Switch to `-simulate` for deep bugs in big models, or to Apalache for bounded symbolic checks.
8. Give the JVM memory (`-Xmx8g`) and use `-XX:+UseParallelGC`.

## ALIAS for readable traces

```tla
Alias == [ db |-> db, cache |-> cache, stale |-> (cache # None /\ cache # db),
           inFlight |-> {r \in Readers : rpc[r] = "fill"} ]
```
Add `ALIAS Alias` to the config; each trace state then shows these fields instead of the raw variables.
