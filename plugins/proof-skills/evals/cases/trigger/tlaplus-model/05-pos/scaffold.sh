#!/usr/bin/env bash
# Stub monorepo so queries that name files (controllers/quota.go, ...) are answerable.
exec python3 "$(dirname "$0")/../../../../triggers/make_trigger_root.py" --no-claude-dir . >/dev/null
