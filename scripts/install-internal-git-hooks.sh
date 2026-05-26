#!/usr/bin/env bash
# Point this repo at .githooks so internal/all stays in sync with source branches.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

HOOKS_DIR="$ROOT/.githooks"
chmod +x "$ROOT/scripts/"*.sh "$ROOT/scripts/lib/"*.sh 2>/dev/null || true
chmod +x "$HOOKS_DIR"/* 2>/dev/null || true

git config core.hooksPath .githooks
echo "Installed git hooks: core.hooksPath=.githooks"
echo "Hooks will run scripts/sync-internal-all.sh when integration source branches change."
echo "Use scripts/assemble-debug-apk.sh to build (internal/all only)."
