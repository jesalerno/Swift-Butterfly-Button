
#!/usr/bin/env bash
# xcode-swiftlint.sh
# Run SwiftLint from Xcode (Build Phase or Scheme Pre-action).
# - Works with Homebrew installs on Apple Silicon/Intel
# - Finds repo root, prefers config in repo
# - Can lint only changed files (fast) or all files
set -euo pipefail

# --- PATH fix for Xcode-run scripts (brew not always visible) ---
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# --- Settings (override via env vars in Xcode script if desired) ---
: "${SWIFTLINT_BIN:=swiftlint}"
: "${SWIFTLINT_CONFIG:=.swiftlint.yml}"
: "${SWIFTLINT_STRICT:=0}"          # 1 = --strict
: "${SWIFTLINT_QUIET:=0}"           # 1 = --quiet
: "${SWIFTLINT_MODE:=auto}"         # auto | all | changed
: "${SWIFTLINT_BASE_BRANCH:=main}"  # used when MODE=changed and git available

# --- Helpers ---
log() { echo "[SwiftLint] $*"; }
warn() { echo "[SwiftLint][warn] $*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# Determine working directory (Xcode provides SRCROOT for project-based scripts)
START_DIR="${SRCROOT:-$(pwd)}"

# Find repo root (git) or fall back to START_DIR
if have git && git -C "$START_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$START_DIR" rev-parse --show-toplevel)"
else
  REPO_ROOT="$START_DIR"
fi

cd "$REPO_ROOT"

# Locate SwiftLint
if ! have "$SWIFTLINT_BIN"; then
  warn "SwiftLint not found in PATH. Install (e.g., brew install swiftlint) or set SWIFTLINT_BIN."
  exit 0
fi

# Locate config (optional)
CONFIG_ARGS=()
if [[ -f "$REPO_ROOT/$SWIFTLINT_CONFIG" ]]; then
  CONFIG_ARGS=(--config "$REPO_ROOT/$SWIFTLINT_CONFIG")
fi

# Common args
ARGS=()
[[ "$SWIFTLINT_STRICT" == "1" ]] && ARGS+=(--strict)
[[ "$SWIFTLINT_QUIET"  == "1" ]] && ARGS+=(--quiet)

# Choose mode
MODE="$SWIFTLINT_MODE"
# Flag file override: touch Tools/.lint-all to force all-files mode
if [[ "$MODE" == "auto" && -f "$REPO_ROOT/Tools/.lint-all" ]]; then
  MODE="all"
fi
if [[ "$MODE" == "auto" ]]; then
  # In CI or Release, lint all; in local Debug, lint changed if possible
  if [[ "${CI:-}" != "" || "${CONFIGURATION:-}" == "Release" ]]; then
    MODE="all"
  else
    MODE="changed"
  fi
fi

# Lint changed files (fast path)
if [[ "$MODE" == "changed" ]] && have git; then
  # Try to diff against merge-base of base branch; fall back to HEAD~ if needed
  BASE_REF="$SWIFTLINT_BASE_BRANCH"
  if git show-ref --verify --quiet "refs/heads/$BASE_REF"; then
    BASE_SHA="$(git merge-base "refs/heads/$BASE_REF" HEAD || true)"
  else
    BASE_SHA="$(git merge-base "origin/$BASE_REF" HEAD 2>/dev/null || true)"
  fi
  if [[ -z "${BASE_SHA:-}" ]]; then
    BASE_SHA="$(git rev-parse HEAD~1 2>/dev/null || true)"
  fi

  if [[ -n "${BASE_SHA:-}" ]]; then
    CHANGED_SWIFT=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && CHANGED_SWIFT+=("$line")
    done < <(git diff --name-only "$BASE_SHA"...HEAD -- '*.swift' || true)
  else
    CHANGED_SWIFT=()
  fi

  if [[ "${#CHANGED_SWIFT[@]}" -eq 0 ]]; then
    log "No changed .swift files detected; skipping."
    exit 0
  fi

  log "Linting changed files (${#CHANGED_SWIFT[@]}):"
  # swiftlint supports --path, but only one path at a time; run per-file
  EXIT=0
  for f in "${CHANGED_SWIFT[@]}"; do
    [[ -f "$f" ]] || continue
    "$SWIFTLINT_BIN" lint ${ARGS[@]+"${ARGS[@]}"} ${CONFIG_ARGS[@]+"${CONFIG_ARGS[@]}"} --path "$f" || EXIT=$?
  done
  exit $EXIT
fi

# Lint all
log "Linting repository (mode=$MODE) at: $REPO_ROOT"
"$SWIFTLINT_BIN" lint ${ARGS[@]+"${ARGS[@]}"} ${CONFIG_ARGS[@]+"${CONFIG_ARGS[@]}"}
