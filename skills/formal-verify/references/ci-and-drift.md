# CI guards and drift detection (W5, W6)

A spec that runs only once rots. Two mechanisms keep it alive:
- **CI** re-checks the model on every change.
- **Drift detection** re-checks that the model still describes the code.

## Config tiers

| Tier | When | Budget | Contents |
|---|---|---|---|
| fast | every PR touching mapped files | < 2 min | smallest bounds that still catch every past bug; all safety invariants; bug-mode configs that must fail |
| deep | nightly | < 60 min | larger bounds, liveness configs, simulation with `-depth 100` |
| proof | every PR touching `lean/` | `lake build` time | all theorems, zero `sorry`, axiom audit |

## GitHub Actions: TLA+

```yaml
name: tla
on:
  pull_request:
    paths: ["formal/**", "src/**"]        # narrow to files in CORRESPONDENCE.md
jobs:
  tlc:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: "21" }
      - name: Fetch TLA+ tools (pinned)
        run: |
          mkdir -p .tla && cd .tla
          curl -fsSLO https://github.com/tlaplus/tlaplus/releases/download/v1.8.0/tla2tools.jar
          curl -fsSLO https://github.com/tlaplus/CommunityModules/releases/latest/download/CommunityModules-deps.jar
      - name: Model check (fast tier)
        run: |
          for cfg in formal/*/tla/MC.cfg; do
            d=$(dirname "$cfg")
            java -XX:+UseParallelGC -cp .tla/tla2tools.jar:.tla/CommunityModules-deps.jar \
              tlc2.TLC -workers auto -config "$cfg" -metadir /tmp/tlc "$d/MC.tla" || exit 1
          done
      - name: Bug-mode configs must fail
        run: |
          for cfg in formal/*/tla/MC_bug*.cfg; do
            [ -e "$cfg" ] || continue
            d=$(dirname "$cfg")
            if java -cp .tla/tla2tools.jar:.tla/CommunityModules-deps.jar tlc2.TLC \
                 -workers auto -config "$cfg" -metadir /tmp/tlc "$d/MC.tla"; then
              echo "::error::$cfg passed but must fail — the check lost its teeth"; exit 1
            fi
          done
```

Pin the jar version in CI, even if local work uses nightly. Otherwise a nightly change
can turn CI red with no code change.

## GitHub Actions: Lean

```yaml
name: lean
on:
  pull_request:
    paths: ["formal/**/lean/**"]
jobs:
  lake:
    runs-on: ubuntu-latest
    strategy:
      matrix: { project: [formal/<concern>/lean] }   # one entry per Lean project
    steps:
      - uses: actions/checkout@v4
      - uses: leanprover/lean-action@v1
        with: { lake-package-directory: "${{ matrix.project }}" }
      - name: No sorry, audited axioms
        working-directory: ${{ matrix.project }}
        run: bash ../../../<path-to>/lean-model/scripts/check_trust.sh .
```

Copy `lean-model/scripts/check_trust.sh` into the repo (for example, `formal/scripts/`) so CI
does not depend on the plugin being installed.

## Drift detection

Run `scripts/correspondence_check.py formal/` (from this skill) in CI. It:
- extracts `src: path:lines` tags from `.tla`, `.qnt`, and `.lean` files and CORRESPONDENCE.md rows,
- fails if a referenced file is missing or a line range runs past the end of the file,
- with `--since <git-ref>`, lists mapped files changed since that ref, so the PR author must
  confirm the model still matches.

This catches moved and deleted code mechanically. Semantic drift (the code at the same line
now does something else) needs one of:
- **trace validation:** implementation logs replayed through the spec
  (`tlaplus-model/references/trace-validation.md`). This is the strongest option and runs continuously.
- **model-based testing:** traces generated from the spec drive the real code
  (`quint run --mbt`, or TLC `-simulate` plus a driver).
- **differential testing:** a Lean executable model compared with the real function on random inputs
  (`lean-model/references/differential-testing.md`).
- **review:** the PR template asks "Does this change behavior described in `formal/*/CORRESPONDENCE.md`?"

## PR nudge

CODEOWNERS entry for mapped paths, or a PR template checkbox:
```
- [ ] This PR touches files listed in formal/*/CORRESPONDENCE.md → spec updated / not needed because …
```
