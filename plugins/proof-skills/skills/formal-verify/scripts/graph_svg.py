#!/usr/bin/env python3
"""Render a small graph (DAG, dependency graph, state machine, protocol topology) as a
self-contained inline <figure><svg>, with counterexample nodes/edges highlighted.

Input JSON (file path or "-" for stdin):
{
  "title": "Graph 1 -> 3 with 2 workers",          # figcaption + aria-label (one claim)
  "direction": "LR",                                # "LR" (default) or "TB"
  "nodes": [{"id": "1", "label": "step 1", "note": "Running"}, ...],   # label/note optional
  "edges": [{"from": "1", "to": "3", "label": "depends on"}, ...],     # label optional
  "highlight": {"nodes": ["3"], "edges": [["1", "3"]]},                # the counterexample
  "steps": {"1": 1, "3": 2}                          # optional: badge = trace step number
}

Layout: layered (longest path from sources, cycles broken by DFS back edges, one
barycenter pass to reduce crossings). Back edges are drawn as curves. Colors use
currentColor plus CSS variables --fv-bad / --fv-muted with safe fallbacks, so the
figure works in light and dark themes. Output: HTML fragment on stdout.

Usage: graph_svg.py graph.json > graph.html
"""
from __future__ import annotations

import html
import json
import sys
from collections import defaultdict

NODE_W, NODE_H, GAP_MAJOR, GAP_MINOR, PAD, MARGIN = 132, 46, 84, 26, 24, 40


def layers_of(ids, edges):
    succ = defaultdict(list)
    for a, b in edges:
        succ[a].append(b)
    # DFS to find back edges (break cycles)
    color, back = {}, set()

    def dfs(u):
        color[u] = 1
        for v in succ[u]:
            if color.get(v) == 1:
                back.add((u, v))
            elif v not in color:
                dfs(v)
        color[u] = 2

    for n in ids:
        if n not in color:
            dfs(n)
    fwd = [(a, b) for a, b in edges if (a, b) not in back and a != b]
    layer = {n: 0 for n in ids}
    for _ in range(len(ids)):  # longest path relaxation on the DAG part
        changed = False
        for a, b in fwd:
            if layer[b] < layer[a] + 1:
                layer[b] = layer[a] + 1
                changed = True
        if not changed:
            break
    return layer, back


def order_layers(ids, layer, edges):
    by = defaultdict(list)
    for n in ids:
        by[layer[n]].append(n)
    pos = {}
    for l in sorted(by):
        if l > 0:
            preds = defaultdict(list)
            for a, b in edges:
                if layer.get(b) == l and a in pos:
                    preds[b].append(pos[a])
            by[l].sort(key=lambda n: (sum(preds[n]) / len(preds[n])) if preds[n] else 1e9)
        for i, n in enumerate(by[l]):
            pos[n] = i
    return by, pos


def render(spec: dict) -> str:
    nodes = spec["nodes"]
    ids = [str(n["id"]) for n in nodes]
    meta = {str(n["id"]): n for n in nodes}
    edges = [(str(e["from"]), str(e["to"]), e.get("label", "")) for e in spec.get("edges", [])]
    pairs = [(a, b) for a, b, _ in edges]
    hl_nodes = {str(x) for x in spec.get("highlight", {}).get("nodes", [])}
    hl_edges = {(str(a), str(b)) for a, b in spec.get("highlight", {}).get("edges", [])}
    steps = {str(k): v for k, v in spec.get("steps", {}).items()}
    lr = spec.get("direction", "LR").upper() != "TB"

    layer, back = layers_of(ids, pairs)
    by, pos = order_layers(ids, layer, pairs)
    width_count = max(len(v) for v in by.values())
    n_layers = max(by) + 1

    def xy(n):
        l, i = layer[n], pos[n]
        offset = (width_count - len(by[l])) / 2
        major = PAD + l * (NODE_W + GAP_MAJOR if lr else NODE_H + GAP_MAJOR)
        minor = PAD + MARGIN + (i + offset) * (NODE_H + GAP_MINOR if lr else NODE_W + GAP_MINOR)
        return (major, minor) if lr else (minor, major)

    if lr:
        W = PAD * 2 + n_layers * NODE_W + (n_layers - 1) * GAP_MAJOR
        H = PAD * 2 + 2 * MARGIN + width_count * NODE_H + (width_count - 1) * GAP_MINOR
    else:
        W = PAD * 2 + 2 * MARGIN + width_count * NODE_W + (width_count - 1) * GAP_MINOR
        H = PAD * 2 + n_layers * NODE_H + (n_layers - 1) * GAP_MAJOR + 30

    out = []
    title = spec.get("title", "Graph")
    out.append(f'<figure class="fv-graph" style="margin:0;overflow-x:auto">')
    out.append(
        f'<svg viewBox="0 0 {W} {H}" role="img" aria-label="{html.escape(title)}" '
        f'style="max-width:100%;height:auto;min-width:{min(W, 560)}px;color:inherit;font-family:inherit">'
    )
    out.append(
        '<defs>'
        '<marker id="fv-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
        '<path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker>'
        '<marker id="fv-arrow-bad" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
        '<path d="M0,0 L10,5 L0,10 z" fill="var(--fv-bad, #c0392b)"/></marker>'
        '</defs>'
    )

    def anchor(n, toward):
        x, y = xy(n)
        tx, ty = xy(toward)
        cx, cy = x + NODE_W / 2, y + NODE_H / 2
        if lr:
            return (x + NODE_W, cy) if tx > x else (x, cy) if tx < x else (cx, y + NODE_H if ty > y else y)
        return (cx, y + NODE_H) if ty > y else (cx, y) if ty < y else (x + NODE_W if tx > x else x, cy)

    for a, b, label in edges:
        bad = (a, b) in hl_edges
        stroke = "var(--fv-bad, #c0392b)" if bad else "currentColor"
        width = 2.4 if bad else 1.4
        marker = "fv-arrow-bad" if bad else "fv-arrow"
        if a == b:  # self loop
            x, y = xy(a)
            path = f"M{x + NODE_W * 0.65},{y} C{x + NODE_W * 0.65},{y - 34} {x + NODE_W * 0.35},{y - 34} {x + NODE_W * 0.35},{y}"
            lx, ly = x + NODE_W / 2, y - 30
        else:
            (x1, y1), (x2, y2) = anchor(a, b), anchor(b, a)
            span = abs(layer[b] - layer[a])
            if (a, b) in back or span != 1:
                # Curve around intermediate layers: bow to the outer side of the graph.
                ma, mb = (y1, y2) if lr else (x1, x2)          # minor-axis coords
                lo = PAD + MARGIN                                   # first node row edge
                hi = (H if lr else W) - PAD - MARGIN                # last node row edge
                mid_minor = (ma + mb) / 2
                near_top = mid_minor < (lo + hi) / 2
                if (a, b) in back:
                    near_top = not near_top                         # back edges use the other side
                outward = lo - MARGIN * 0.7 if near_top else hi + MARGIN * 0.7
                bow = outward if span > 1 or (a, b) in back else mid_minor + 46
                if lr:
                    mx, my = (x1 + x2) / 2, 2 * bow - mid_minor
                else:
                    mx, my = 2 * bow - mid_minor, (y1 + y2) / 2
                path = f"M{x1},{y1} Q{mx},{my} {x2},{y2}"
                lx, ly = ((x1 + x2) / 2, bow - 4) if lr else (bow, (y1 + y2) / 2)
            else:
                path = f"M{x1},{y1} L{x2},{y2}"
                lx, ly = (x1 + x2) / 2, (y1 + y2) / 2 - 6
        dash = ' stroke-dasharray="5 4"' if (a, b) in back else ""
        out.append(f'<path d="{path}" fill="none" stroke="{stroke}" stroke-width="{width}"{dash} marker-end="url(#{marker})"/>')
        if label:
            fill = "var(--fv-bad, #c0392b)" if bad else "var(--fv-muted, currentColor)"
            out.append(f'<text x="{lx:.0f}" y="{ly:.0f}" text-anchor="middle" font-size="11" fill="{fill}" '
                       f'paint-order="stroke" stroke="var(--fv-bg, Canvas)" stroke-width="5" stroke-linejoin="round">{html.escape(label)}</text>')

    for n in ids:
        x, y = xy(n)
        bad = n in hl_nodes
        stroke = "var(--fv-bad, #c0392b)" if bad else "currentColor"
        fill = "var(--fv-bad-soft, rgba(192,57,43,.12))" if bad else "none"
        out.append(f'<rect x="{x}" y="{y}" width="{NODE_W}" height="{NODE_H}" rx="6" fill="{fill}" stroke="{stroke}" stroke-width="{2.2 if bad else 1.3}"/>')
        label = meta[n].get("label", n)
        note = meta[n].get("note", "")
        ty = y + (NODE_H / 2 - 3 if note else NODE_H / 2 + 4)
        out.append(f'<text x="{x + NODE_W / 2}" y="{ty}" text-anchor="middle" font-size="13" font-weight="600" fill="currentColor">{html.escape(str(label))}</text>')
        if note:
            nfill = "var(--fv-bad, #c0392b)" if bad else "var(--fv-muted, currentColor)"
            out.append(f'<text x="{x + NODE_W / 2}" y="{y + NODE_H / 2 + 13}" text-anchor="middle" font-size="11" fill="{nfill}">{html.escape(note)}</text>')
        if n in steps:
            out.append(f'<circle cx="{x + NODE_W - 2}" cy="{y + 2}" r="10" fill="var(--fv-bad, #c0392b)"/>')
            out.append(f'<text x="{x + NODE_W - 2}" y="{y + 6}" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">{steps[n]}</text>')

    out.append("</svg>")
    out.append(f"<figcaption>{html.escape(title)}</figcaption></figure>")
    return "\n".join(out)


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    src = sys.stdin if sys.argv[1] == "-" else open(sys.argv[1])
    print(render(json.load(src)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
