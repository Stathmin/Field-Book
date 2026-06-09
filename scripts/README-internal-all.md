# internal/all integration branch

`internal/all` combines active feature branches for a single debug APK build.

## Source branches (merge order)

1. `main` (reset base)
2. `pr/tablet-rotation-sw800`
3. `feature/hide-field-nav-arrows`
4. `fix/brapi-oauth-fieldbook-redirect`
5. `debug/trait-resourcefile-paths`
6. `feature/soda-dark-theme`
7. `quick/build-local`

## Setup (once per clone)

```bash
scripts/install-internal-git-hooks.sh
```

This sets `core.hooksPath` to `.githooks`. After you commit or pull on any source branch, `internal/all` is updated in the background.

## Manual sync

```bash
scripts/sync-internal-all.sh          # skip if SHAs unchanged
scripts/sync-internal-all.sh --force  # always rebuild
scripts/sync-internal-all.sh --check  # exit 0 if sync needed
```

## Debug APK (internal/all only)

```bash
git checkout internal/all
scripts/sync-internal-all.sh --force
scripts/assemble-debug-apk.sh
```

APK: `app/build/outputs/apk/debug/app-debug.apk`

Do not run `./gradlew assembleDebug` on other branches for integration builds; use the script.
