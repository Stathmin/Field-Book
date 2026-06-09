#!/usr/bin/env bash
# Run JVM unit tests without assembleDebug. Reuses Gradle daemon + build cache.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ $# -gt 0 ]]; then
  TEST_FILTER="$1"
  shift
else
  TEST_FILTER='com.fieldbook.tracker.theme.*'
fi

exec "$ROOT/gradlew" \
  :app:testDebugUnitTest \
  --tests "$TEST_FILTER" \
  --build-cache \
  --parallel \
  "$@"
