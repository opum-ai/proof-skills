# Report: publish results as an Artifact

Every workflow ends in a report the user can read, share, and come back to. Publish it with
the Artifact tool, built by following the `artifact-design` skill. That skill owns the page
contract (skeleton, theming, CDN allowlist, phone width), so load it before writing HTML. Load
`artifact-diagramming` as well whenever the page draws a trace, a state machine, or a graph.

This file defines **what the report must say**. `artifact-design` defines **how it looks**.

## Source of truth: `formal/findings.json`

Write the findings file first (schema: `../assets/findings.schema.json`), then build the page
from it. This keeps the report reproducible, lets CI or a later session regenerate it, and
lets `proof-simplify` read prior results.

## Required content, in this order

1. **Verdict strip.** One sentence and counts: confirmed / suspected / refuted findings,
   properties checked, and the bounds. For example: "2 confirmed races in job leasing; 5
   properties hold for 2 workers × 3 jobs × ≤2 retries (1.2M states)." A reader who stops
   here must still get the truth.
2. **Findings**, most severe first. Each finding shows:
   - ID, title, severity, status (confirmed / suspected / refuted / fixed),
   - the violated property, quoted from the spec, with its plain-English meaning,
   - **the counterexample trace** as a sequence diagram or step table: actor, action, the code
     location from CORRESPONDENCE.md, and the state variables that changed. Mark the step
     where the property breaks. Mermaid `sequenceDiagram` renders natively in Artifacts and
     suits multi-actor traces. A step table suits single-actor state machines. When the concern
     has a shape (a graph, a state machine, a topology), also draw it with the counterexample
     highlighted. See "Diagrams" below.
   - the reproduction (test or script, and its path) and its result, including the saved log of it
     failing on the original code,
   - the fix (a diff under 15 lines, or a PR link), and the evidence that it works: the re-check
     passed, and the mutation check failed as expected.
3. **What was verified.** A table of properties: name, kind (invariant / action property /
   liveness / theorem), result, tool, and bounds or "unbounded (proof)".
4. **Model scope and assumptions.** What is modeled, what is abstracted, and what is out of
   scope, from SCOPE.md, plus the Assumptions list from CORRESPONDENCE.md. This is where
   readers learn what the green checks do *not* cover.
5. **Trust base.** Every check listed here must point to a saved log under
   `formal/<concern>/evidence/`. A claim with no log is reported as "not recorded", never as passed.
   - TLA+: tool and version, states generated and distinct, depth, and the sanity checks that
     ran (must-fail invariants failed, coverage showed no dead actions).
   - Lean: toolchain, `#print axioms` output for each headline theorem, the remaining `sorry`
     count (must be 0 for any claim marked "proven"), and any use of `native_decide`.
6. **Re-run.** The exact commands, copy-pasteable.
7. **Next steps.** Suggested follow-up workflows (simplify, CI guard, deeper bounds).

## Diagrams: draw the system the bug lives in

A trace table tells the reader *what happened*. A diagram shows *where* it happened.
Include diagrams whenever the concern has a shape. Follow `artifact-diagramming`: draw the
mechanism, label every arrow, and state one claim per figure in the caption.

| Concern | Draw | How |
|---|---|---|
| Graphs, DAGs, schedulers, dependency or build graphs | The graph of the counterexample, with the violating edge or node highlighted and trace-step badges on the nodes | `../scripts/graph_svg.py` |
| State machines and lifecycles | States and allowed transitions, with the illegal transition drawn and highlighted | `../scripts/graph_svg.py` (the `edges` are the transitions) |
| Multi-actor races (threads, workers, handlers, services) | A sequence or lane diagram of the trace, marking the step where the property breaks | Mermaid `sequenceDiagram`, or inline SVG lanes |
| Protocols and topologies (queues, caches, replicas) | Components and message flows, with the dropped, duplicated or reordered message marked | `../scripts/graph_svg.py` or inline SVG |

`graph_svg.py` takes a small JSON graph (`nodes`, `edges`, `highlight`, `steps`) and emits
a self-contained `<figure><svg>`. It uses a layered layout, curves back edges and
layer-skipping edges around nodes, and draws in `currentColor` plus the CSS variables
`--fv-bad`, `--fv-muted` and `--fv-bg`. Define those variables in the page's theme tokens,
and the figure then works in both light and dark themes. Paste its output straight into the
report. Prefer it to hand-placed SVG coordinates, which drift and overlap.

Prefer inline SVG over Mermaid for anything the local fallback file (`formal/reports/`)
must also show: Mermaid renders natively in Artifacts, but not in a plain HTML file.

For W4 (simplification) reports, add a **Simplifications** section before "What was verified".
For each change it shows: the code removed or changed, the invariant that justifies it, the
re-verification result, and the lines-of-code or complexity delta.

## Trace-only report (W8)

This is a short page with the story, the diagram, the changed-variables table, and the
verdict (real bug / model artifact / property too strong). Skip the sections that do not apply.

## Publishing

- **Title:** a name, not a sentence. Use `<Concern> verification` or the system's own name,
  for example `Job lease verification`. Keep it stable across republishes.
- **Description:** the verdict sentence.
- **File path:** use `formal/reports/<concern>.html`, and reuse it on every re-run so the
  Artifact URL stays the same. Pass `icon: "shield"` (or another plain word) on the first publish.
- Keep the page self-contained: inline CSS and JS, and no fetches of repo files. Embed the data
  from findings.json into the page.
- After publishing, give the user the link and the verdict sentence. The terminal reply
  stays short; the page carries the detail.

If the Artifact tool is unavailable, write the same HTML to `formal/reports/<concern>.html`
and tell the user where it is.
