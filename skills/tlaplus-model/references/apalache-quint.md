# Apalache and Quint

## When to leave TLC

| Situation | Use |
|---|---|
| Large or unbounded integer domains, big records | Apalache (SMT) or `quint verify` |
| You want a bounded guarantee: "no bug in ≤ k steps, for any values" | Apalache `check --length=k` |
| Unbounded safety proof by induction | Apalache inductive-invariant recipe |
| The team prefers typed, programming-language syntax | Quint (compiles to Apalache or TLC) |
| Liveness or fairness | Stay with TLC; temporal support elsewhere is limited |

In Quint's summary: "TLC trades scalability for completeness; Apalache trades completeness
for scalability."

## Apalache

This skill does not install it. Get it from https://apalache-mc.org or via Quint, which
downloads it automatically.

Types are required on `CONSTANTS` and `VARIABLES`:
```tla
CONSTANT
    \* @type: Set(Str);
    Workers
VARIABLES
    \* @type: Str -> Str;
    wpc
```

```bash
apalache-mc typecheck Spec.tla
apalache-mc check --inv=Safety --length=15 Spec.tla                    # bounded model check
apalache-mc check --cinit=ConstInit --inv=Safety --length=10 Spec.tla  # constants chosen by ConstInit
apalache-mc simulate --max-run=1000 --length=30 Spec.tla
# Inductive invariant (unbounded safety):
apalache-mc check --init=Init   --inv=IndInv --length=0 Spec.tla   # Init => IndInv
apalache-mc check --init=IndInv --inv=IndInv --length=1 Spec.tla   # IndInv /\ Next => IndInv'
apalache-mc check --init=IndInv --inv=Safety --length=0 Spec.tla   # IndInv => Safety
```

Finding an inductive invariant follows the same loop as in Lean. A failed step 2 gives a
counterexample to induction (CTI): a state that satisfies `IndInv` but is unreachable, and
whose successor breaks it. Strengthen `IndInv` to exclude that state, then repeat.

## Quint

`npm i -g @informalsystems/quint`

```bash
quint typecheck spec.qnt
quint run --invariant=noLostUpdate --max-steps=30 --max-samples=10000 spec.qnt   # random simulation
quint verify --invariant=noLostUpdate --max-steps=10 spec.qnt                    # Apalache backend
quint verify --backend=tlc --invariant=noLostUpdate --temporal=eventuallyDone spec.qnt
quint run --mbt --out-itf=trace.itf.json --n-traces=50 spec.qnt                 # traces for MBT
quint test spec.qnt
```

A minimal Quint equivalent of the lost-update pattern:
```quint
module lostUpdate {
  const THREADS: Set[str]
  var counter: int
  var tmp: str -> int
  var pc: str -> str

  action init = all {
    counter' = 0, tmp' = THREADS.mapBy(_ => 0), pc' = THREADS.mapBy(_ => "read"),
  }
  action read(t) = all { pc.get(t) == "read", tmp' = tmp.set(t, counter),
                         pc' = pc.set(t, "write"), counter' = counter }
  action write(t) = all { pc.get(t) == "write", counter' = tmp.get(t) + 1,
                          pc' = pc.set(t, "done"), tmp' = tmp }
  action step = nondet t = oneOf(THREADS) any { read(t), write(t) }

  val noLostUpdate = THREADS.forall(t => pc.get(t) == "done") implies counter == THREADS.size()
}
module main { import lostUpdate(THREADS = Set("a", "b")).* }
```
Checked with Quint 0.32.0: `quint typecheck` passes, and
`quint run --main=main --invariant=noLostUpdate --max-steps=10 lu.qnt` reports the violation in
four states (both threads read 0, both write 1).
