#!/usr/bin/env bash
# Build debug APK only from the integration branch internal/all.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/internal-all-lib.sh
source "$SCRIPT_DIR/lib/internal-all-lib.sh"

ROOT="$(internal_all_repo_root)"
cd "$ROOT"

CURRENT="$(git branch --show-current)"
if [[ "$CURRENT" != "$INTERNAL_ALL_BRANCH" ]]; then
  cat >&2 <<EOF
error: assembleDebug is only allowed on branch '$INTERNAL_ALL_BRANCH' (current: '$CURRENT').

  git checkout $INTERNAL_ALL_BRANCH
  scripts/sync-internal-all.sh --force
  scripts/assemble-debug-apk.sh
EOF
  exit 1
fi

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "error: working tree has uncommitted tracked changes on $INTERNAL_ALL_BRANCH" >&2
  exit 1
fi

echo "Building debug APK on $INTERNAL_ALL_BRANCH @ $(git rev-parse --short HEAD)"
exec "$ROOT/gradlew" assembleDebug "$@"
