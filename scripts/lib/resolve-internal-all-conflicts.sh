#!/usr/bin/env bash
# Auto-resolve known internal/all merge conflicts (idempotent).
set -euo pipefail

internal_all_has_conflicts() {
  git diff --name-only --diff-filter=U | grep -q .
}

internal_all_resolve_conflicts_for_branch() {
  local branch="$1"
  case "$branch" in
    feature/hide-field-nav-arrows)
      internal_all_resolve_preference_keys
      ;;
    feature/soda-dark-theme)
      internal_all_resolve_themed_activity
      ;;
  esac
}

internal_all_resolve_preference_keys() {
  local file="app/src/main/java/com/fieldbook/tracker/preferences/PreferenceKeys.kt"
  if [[ ! -f "$file" ]] || ! grep -q '<<<<<<<' "$file"; then
    return 0
  fi
  echo "internal/all: auto-resolving $file (keep ALLOW_ROTATION + ALLOW_HIDE_FIELD_NAV_ARROWS)"
  git checkout --theirs -- "$file"
}

internal_all_resolve_themed_activity() {
  local file="app/src/main/java/com/fieldbook/tracker/activities/ThemedActivity.kt"
  if [[ ! -f "$file" ]] || ! grep -q '<<<<<<<' "$file"; then
    return 0
  fi
  echo "internal/all: auto-resolving $file (AppThemeResolver + RotationPolicy)"
  python3 - "$file" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = re.sub(
    r"import com\.fieldbook\.tracker\.R\n<<<<<<< HEAD\nimport com\.fieldbook\.tracker\.preferences\.PreferenceKeys\nimport com\.fieldbook\.tracker\.utilities\.RotationPolicy\n=======\nimport com\.fieldbook\.tracker\.utilities\.AppThemeResolver\n>>>>>>> feature/soda-dark-theme\nimport com\.fieldbook\.tracker\.utilities\.SharedPreferenceUtils",
    "import com.fieldbook.tracker.R\nimport com.fieldbook.tracker.utilities.AppThemeResolver\nimport com.fieldbook.tracker.utilities.RotationPolicy\nimport com.fieldbook.tracker.utilities.SharedPreferenceUtils",
    text,
)
text = re.sub(
    r"\n<<<<<<< HEAD\n\n}\n=======\n}\n>>>>>>> feature/soda-dark-theme\n",
    "\n}\n",
    text,
)
open(path, "w", encoding="utf-8").write(text)
PY
}

internal_all_finish_conflict_resolution() {
  if internal_all_has_conflicts; then
    echo "error: unresolved merge conflicts remain:" >&2
    git diff --name-only --diff-filter=U >&2
    return 1
  fi
  git add -A
  git commit --no-edit
}
