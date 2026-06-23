#!/usr/bin/env bash
# Called from git hooks when an integration source branch changes.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/internal-all-lib.sh
source "$SCRIPT_DIR/lib/internal-all-lib.sh"

BRANCH="${1:-$(git branch --show-current)}"
if internal_all_is_source_branch "$BRANCH"; then
  exec "$SCRIPT_DIR/sync-internal-all.sh" --trigger "$BRANCH"
fi
