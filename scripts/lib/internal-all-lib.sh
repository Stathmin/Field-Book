# Shared helpers for internal/all integration (source with `. scripts/lib/internal-all-lib.sh`).

INTERNAL_ALL_BRANCH="internal/all"

# Merge order after main (main is the reset base).
INTERNAL_ALL_SOURCES=(
  main
  pr/tablet-rotation-sw800
  feature/hide-field-nav-arrows
  fix/brapi-auth-avoid-default-server-ping
  debug/trait-resourcefile-paths
  quick/build-local
)

internal_all_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

internal_all_is_source_branch() {
  local branch="$1"
  local b
  for b in "${INTERNAL_ALL_SOURCES[@]}"; do
    if [[ "$branch" == "$b" ]]; then
      return 0
    fi
  done
  return 1
}

internal_all_state_file() {
  echo "$(internal_all_repo_root)/.git/fieldbook-internal-all.state"
}

internal_all_record_state() {
  local state_file
  state_file="$(internal_all_state_file)"
  : >"$state_file"
  local b
  for b in "${INTERNAL_ALL_SOURCES[@]}"; do
    if git rev-parse --verify "$b" >/dev/null 2>&1; then
      echo "$b $(git rev-parse "$b")" >>"$state_file"
    fi
  done
}

internal_all_sources_changed() {
  local state_file
  state_file="$(internal_all_state_file)"
  if [[ ! -f "$state_file" ]]; then
    return 0
  fi
  local b
  for b in "${INTERNAL_ALL_SOURCES[@]}"; do
    if ! git rev-parse --verify "$b" >/dev/null 2>&1; then
      continue
    fi
    local current recorded
    current="$(git rev-parse "$b")"
    recorded="$(grep -E "^${b} " "$state_file" 2>/dev/null | awk '{print $2}')"
    if [[ "$current" != "$recorded" ]]; then
      return 0
    fi
  done
  return 1
}
