#!/usr/bin/env bash
# Copy the fixture repo into the run's workspace and commit it as the baseline, then make
# your toolchains usable inside the sandboxed run (see scaffold_env.sh).
set -euo pipefail
FIX="$(cd "$(dirname "$0")/../../../fixtures/go-dag" && pwd)"
cp -R "$FIX"/. .
git init -q && git add -A && git -c user.email=eval@example.invalid -c user.name=eval commit -qm "fixture: go-dag"
source "$(dirname "$0")/../../../scaffold_env.sh"
