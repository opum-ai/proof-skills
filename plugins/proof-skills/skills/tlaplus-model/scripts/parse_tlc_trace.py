#!/usr/bin/env python3
"""Turn a TLC counterexample into a step list with changed variables and code pointers.

Input (auto-detected):
  * JSON written by `tlc -dumpTrace json cex.json`   (preferred: exact action names + params)
  * TLC's plain text output (stdout of a failing run) (fallback)

Code pointers: for each action, the spec is scanned for a `\\* src: path:lines` comment
on the line above the action's definition, on the definition line itself, or inside
its body. Pass the spec with --spec (defaults to the module named in the trace, looked
up next to the trace file).

Usage:
  parse_tlc_trace.py cex.json [--spec Spec.tla] [--format md|json] [--hide var1,var2]
  parse_tlc_trace.py tlc-output.txt --format md

The JSON output matches the `trace` array of formal-verify/assets/findings.schema.json.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

SRC_TAG = re.compile(r"\\\*\s*src:\s*(\S+)")
TEXT_STATE = re.compile(r"^State (\d+): <(.+?)>\s*$")
TEXT_ACTION = re.compile(r"^(\w+)(?:\((.*?)\))?\s+line (\d+), col \d+ to line (\d+), col \d+ of module (\w+)")


class Raw(str):
    """A value already in TLA+ text form (from TLC's text output)."""


def tla_value(v) -> str:
    """Render a JSON-decoded TLC value compactly, close to TLA+ syntax."""
    if isinstance(v, Raw):
        return str(v)
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, str):
        return json.dumps(v)
    if isinstance(v, list):
        return "<<" + ", ".join(tla_value(x) for x in v) + ">>"
    if isinstance(v, dict):
        return "[" + ", ".join(f"{k} |-> {tla_value(x)}" for k, x in v.items()) + "]"
    return str(v)


def changed(prev: dict | None, cur: dict) -> dict:
    if prev is None:
        return {k: tla_value(v) for k, v in cur.items()}
    out = {}
    for k, v in cur.items():
        if prev.get(k) != v:
            if isinstance(v, dict) and isinstance(prev.get(k), dict):
                sub = {kk: vv for kk, vv in v.items() if prev[k].get(kk) != vv}
                out[k] = ", ".join(f"{kk} |-> {tla_value(vv)}" for kk, vv in sub.items()) + " (changed keys)"
            else:
                out[k] = tla_value(v)
    return out


DEF_RE = re.compile(r"^(\w+)\s*(?:\([^)]*\))?\s*==")
COMMENT_RE = re.compile(r"^\s*(\\\*|\(\*|\*)")


def _index_file(path: Path) -> dict[str, str]:
    """Map operator name -> src tag for one module. A tag belongs to a definition if it is
    in the contiguous comment block directly above it, or on/inside its body."""
    lines = path.read_text(errors="replace").splitlines()
    defs = [(i, m.group(1)) for i, l in enumerate(lines) if (m := DEF_RE.match(l))]
    idx: dict[str, str] = {}
    for n, (i, name) in enumerate(defs):
        above = []
        j = i - 1
        while j >= 0 and COMMENT_RE.match(lines[j]):
            above.append(lines[j]); j -= 1
        end = defs[n + 1][0] if n + 1 < len(defs) else len(lines)
        while end - 1 > i and COMMENT_RE.match(lines[end - 1]):
            end -= 1                      # trailing comment block belongs to the next definition
        for l in above + lines[i:end]:
            if m := SRC_TAG.search(l):
                idx[name] = m.group(1)
                break
    return idx


def src_index(spec: Path | None) -> dict[tuple[str, str], str]:
    """Map (module, operator) -> src tag across every .tla file next to the spec, so tags
    are found even when the checked root module EXTENDS the spec that holds them."""
    if not spec:
        return {}
    files = sorted(spec.parent.glob("*.tla")) if spec.parent.is_dir() else []
    idx: dict[tuple[str, str], str] = {}
    for f in files:
        if "_TTrace_" in f.name:
            continue
        for name, tag in _index_file(f).items():
            idx[(f.stem, name)] = tag
    return idx


def lookup(idx: dict[tuple[str, str], str], module: str | None, name: str) -> str | None:
    if module and (module, name) in idx:
        return idx[(module, name)]
    hits = {tag for (m, n), tag in idx.items() if n == name}
    return hits.pop() if len(hits) == 1 else None


def from_json(doc: dict) -> tuple[list[dict], str | None]:
    cex = doc.get("counterexample", doc)
    steps, module = [], None
    actions = cex.get("action") or []
    states = cex.get("state") or []
    if actions:
        first = actions[0][0][1]
        steps.append({"step": 1, "action": "Init", "state": first})
        for a in actions:
            meta, (num, st) = a[1], a[2]
            module = module or meta.get("location", {}).get("module")
            ctx = meta.get("context") or {}
            params = ", ".join(tla_value(ctx[p]) for p in meta.get("parameters", []) if p in ctx)
            steps.append({"step": num, "action": meta.get("name", "?"), "params": params,
                          "actor": params or None, "state": st,
                          "module": meta.get("location", {}).get("module")})
    else:
        for num, st in states:
            steps.append({"step": num, "action": "?" if num > 1 else "Init", "state": st})
    return steps, module


def parse_text_value(s: str):
    return Raw(s.strip())  # keep TLA+ text as-is; diffing works on strings


def from_text(text: str) -> tuple[list[dict], str | None]:
    steps, cur, module = [], None, None
    last_var = None
    for raw in text.splitlines():
        line = raw.rstrip()
        if m := TEXT_STATE.match(line):
            num, label = int(m.group(1)), m.group(2)
            action, params = "Init", ""
            if am := TEXT_ACTION.match(label):
                action, params = am.group(1), am.group(2) or ""
                module = module or am.group(5)
            elif label.startswith("Initial predicate"):
                action = "Init"
            else:
                action = label.split()[0]
            cur = {"step": num, "action": action, "params": params, "actor": params or None, "state": {},
                   "module": am.group(5) if am else None}
            steps.append(cur)
            last_var = None
            continue
        if cur is None:
            continue
        if line.startswith("/\\ ") and " = " in line:
            k, v = line[3:].split(" = ", 1)
            cur["state"][k.strip()] = parse_text_value(v)
            last_var = k.strip()
        elif line.startswith("   ") and last_var:          # multi-line value continuation
            cur["state"][last_var] = Raw(cur["state"][last_var] + " " + line.strip())
        elif not line.strip():
            cur = None if cur and cur["state"] else cur
    return steps, module


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("trace", type=Path)
    ap.add_argument("--spec", type=Path)
    ap.add_argument("--format", choices=["md", "json"], default="md")
    ap.add_argument("--hide", default="", help="comma-separated variables to omit (auxiliary vars)")
    args = ap.parse_args()

    raw = args.trace.read_text(errors="replace")
    try:
        steps, module = from_json(json.loads(raw))
    except (json.JSONDecodeError, TypeError, KeyError, IndexError):
        steps, module = from_text(raw)
    if not steps:
        print("no counterexample found in input", file=sys.stderr)
        return 1

    spec = args.spec or (args.trace.parent / f"{module}.tla" if module else None)
    srcs = src_index(spec)
    hide = {h for h in args.hide.split(",") if h}

    out, prev = [], None
    for s in steps:
        st = {k: v for k, v in s["state"].items() if k not in hide}
        item = {"step": s["step"], "action": s["action"] + (f"({s['params']})" if s.get("params") else ""),
                "changed": changed(prev, st)}
        if s.get("actor"):
            item["actor"] = s["actor"]
        if tag := lookup(srcs, s.get("module"), s["action"]):
            item["code"] = tag
        out.append(item)
        prev = st
    if out:
        out[-1]["violation"] = True   # TLC reports the violating state last (safety)

    if args.format == "json":
        print(json.dumps(out, indent=2))
    else:
        print("| # | Action | Code | Changed |")
        print("|---|---|---|---|")
        for i in out:
            ch = "; ".join(f"`{k}` = {v}" for k, v in i["changed"].items()) or "(stutter)"
            ch = ch.replace("|", "\\|")  # keep TLA+ `|->` from splitting table cells
            mark = " ⚠" if i.get("violation") else ""
            print(f"| {i['step']} | `{i['action']}`{mark} | {i.get('code', '')} | {ch} |")
    return 0


if __name__ == "__main__":
    sys.exit(main())
