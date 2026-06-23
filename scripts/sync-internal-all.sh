#!/usr/bin/env bash
# Rebuild internal/all from main, then merge integration source branches in order.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/internal-all-lib.sh
source "$SCRIPT_DIR/lib/internal-all-lib.sh"
# shellcheck source=scripts/lib/resolve-internal-all-conflicts.sh
source "$SCRIPT_DIR/lib/resolve-internal-all-conflicts.sh"

usage() {
  cat <<'EOF'
Usage: scripts/sync-internal-all.sh [options]

  Rebuilds internal/all: reset to main, merge each integration branch.

Options:
  --force       Run even if source branch SHAs are unchanged
  --check       Dry-run: report whether sync is needed, exit 0/1
  --trigger BR  Log which branch triggered the sync (for hooks)
  -h, --help    Show this help

Integration branches (after main):
  pr/tablet-rotation-sw800, feature/hide-field-nav-arrows,
  fix/brapi-oauth-fieldbook-redirect, debug/trait-resourcefile-paths,
  feature/soda-dark-theme, quick/build-local
EOF
}

FORCE=0
CHECK_ONLY=0
TRIGGER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --check) CHECK_ONLY=1; shift ;;
    --trigger) TRIGGER="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

ROOT="$(internal_all_repo_root)"
cd "$ROOT"

if [[ -n "${FIELD_BOOK_INTERNAL_ALL_SYNC:-}" ]]; then
  exit 0
fi

if ! git rev-parse --verify "$INTERNAL_ALL_BRANCH" >/dev/null 2>&1; then
  echo "error: branch $INTERNAL_ALL_BRANCH does not exist" >&2
  exit 1
fi

if ! git rev-parse --verify main >/dev/null 2>&1; then
  echo "error: branch main does not exist" >&2
  exit 1
fi

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  if internal_all_sources_changed; then
    echo "internal/all sync needed (source branch tips changed)"
    exit 0
  fi
  echo "internal/all is up to date"
  exit 1
fi

if [[ "$FORCE" -eq 0 ]] && ! internal_all_sources_changed; then
  echo "internal/all: sources unchanged, skipping sync (use --force to rebuild)"
  exit 0
fi

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "error: working tree has uncommitted tracked changes; commit or stash before syncing internal/all" >&2
  exit 1
fi

PREVIOUS_BRANCH="$(git branch --show-current)"
RESTORE_BRANCH="$PREVIOUS_BRANCH"

cleanup() {
  export FIELD_BOOK_INTERNAL_ALL_SYNC=
  if [[ -n "$RESTORE_BRANCH" ]] && git rev-parse --verify "$RESTORE_BRANCH" >/dev/null 2>&1; then
    git checkout "$RESTORE_BRANCH" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

export FIELD_BOOK_INTERNAL_ALL_SYNC=1

if [[ -n "$TRIGGER" ]]; then
  echo "internal/all: sync triggered by update to $TRIGGER"
fi

echo "internal/all: resetting to main ($(git rev-parse --short main))"
git checkout "$INTERNAL_ALL_BRANCH"
git reset --hard main

merge_branch() {
  local branch="$1"
  if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
    echo "internal/all: skip missing branch $branch"
    return 0
  fi
  if [[ "$branch" == "main" ]]; then
    return 0
  fi
  echo "internal/all: merging $branch ($(git rev-parse --short "$branch"))"
  if git merge "$branch" --no-edit -m "integrate: $branch"; then
    return 0
  fi
  internal_all_resolve_conflicts_for_branch "$branch"
  if ! internal_all_finish_conflict_resolution; then
    echo "error: merge failed for $branch — unresolved conflicts on $INTERNAL_ALL_BRANCH" >&2
    exit 1
  fi
}

for branch in "${INTERNAL_ALL_SOURCES[@]}"; do
  merge_branch "$branch"
done

internal_all_record_state
echo "internal/all: sync complete at $(git rev-parse --short HEAD)"

if [[ "$PREVIOUS_BRANCH" != "$INTERNAL_ALL_BRANCH" ]]; then
  echo "internal/all: checked out $INTERNAL_ALL_BRANCH (was on $PREVIOUS_BRANCH)"
  RESTORE_BRANCH=""
fi
