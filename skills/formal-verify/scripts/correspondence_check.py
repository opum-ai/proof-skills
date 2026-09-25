#!/usr/bin/env python3
"""Check that model -> code pointers still resolve (drift signal for W6).

Scans .tla/.qnt/.lean/.md files under a formal/ directory for tags of the form
    src: path/to/file.ext:10-24     (also :10 or no line range)
and CORRESPONDENCE.md table cells like `path/to/file.ext:10-24`.

Usage:
    correspondence_check.py formal/ [--root .] [--since <git-ref>] [--json]

Exit codes: 0 all pointers resolve; 1 broken pointers; 2 usage error.
With --since, also lists mapped source files changed since <git-ref> (informational).
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

TAG = re.compile(r"src:\s*`?([\w./@+-]+\.[A-Za-z0-9]+)(?::(\d+)(?:-(\d+))?)?`?")
CELL = re.compile(r"`([\w./@+-]+\.[A-Za-z0-9]+):(\d+)(?:-(\d+))?`")
MODEL_EXT = {".tla", ".qnt", ".lean", ".md", ".cfg"}


def scan(formal: Path):
    for f in sorted(formal.rglob("*")):
        if f.suffix not in MODEL_EXT or not f.is_file() or ".lake" in f.parts:
            continue
        text = f.read_text(errors="replace")
        pats = [TAG] + ([CELL] if f.name.upper().startswith("CORRESPONDENCE") else [])
        for lineno, line in enumerate(text.splitlines(), 1):
            for pat in pats:
                for m in pat.finditer(line):
                    path, a, b = m.group(1), m.group(2), m.group(3)
                    yield {
                        "model_file": str(f),
                        "model_line": lineno,
                        "target": path,
                        "start": int(a) if a else None,
                        "end": int(b) if b else (int(a) if a else None),
                    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("formal", type=Path)
    ap.add_argument("--root", type=Path, default=Path("."), help="repo root that src: paths are relative to")
    ap.add_argument("--since", help="git ref; list mapped files changed since then")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if not args.formal.is_dir():
        print(f"not a directory: {args.formal}", file=sys.stderr)
        return 2

    seen, broken, targets = set(), [], set()
    for ref in scan(args.formal):
        key = (ref["model_file"], ref["model_line"], ref["target"], ref["start"])
        if key in seen:
            continue
        seen.add(key)
        # Skip pointers to model files themselves (e.g. `Spec.tla:12`).
        if Path(ref["target"]).suffix in {".tla", ".qnt", ".lean", ".cfg"}:
            continue
        p = args.root / ref["target"]
        targets.add(ref["target"])
        if not p.is_file():
            broken.append({**ref, "problem": "file missing"})
            continue
        if ref["end"]:
            n = sum(1 for _ in p.open(errors="replace"))
            if ref["end"] > n:
                broken.append({**ref, "problem": f"line {ref['end']} past end of file ({n} lines)"})

    changed = []
    if args.since:
        try:
            out = subprocess.run(
                ["git", "-C", str(args.root), "diff", "--name-only", f"{args.since}..HEAD", "--", *sorted(targets)],
                capture_output=True, text=True, check=True,
            ).stdout
            changed = [l for l in out.splitlines() if l]
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"warning: git diff failed: {e}", file=sys.stderr)

    if args.json:
        print(json.dumps({"pointers": len(seen), "broken": broken, "changed_since": changed}, indent=2))
    else:
        print(f"{len(seen)} pointers, {len(targets)} source files, {len(broken)} broken")
        for b in broken:
            print(f"  BROKEN {b['model_file']}:{b['model_line']} -> {b['target']}:{b['start']}-{b['end']} ({b['problem']})")
        if args.since:
            print(f"{len(changed)} mapped files changed since {args.since}")
            for c in changed:
                print(f"  CHANGED {c}")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
