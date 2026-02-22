
#!/usr/bin/env bash
# xcode-swiftformat.sh
# Run SwiftFormat from Xcode (Scheme Pre-action recommended) or manually.
# - Works with Homebrew installs on Apple Silicon/Intel
# - Finds repo root, prefers config in repo
# - Can format only changed files or all files
set -euo pipefail

# --- PATH fix for Xcode-run scripts (brew not always visible) ---
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# --- Settings (override via env vars in Xcode script if desired) ---
: "${SWIFTFORMAT_BIN:=swiftformat}"
: "${SWIFTFORMAT_CONFIG:=.swiftformat}"
: "${SWIFTFORMAT_MODE:=all}"          # all | changed | auto
: "${SWIFTFORMAT_BASE_BRANCH:=main}"  # used when MODE=changed

log() { echo "[SwiftFormat] $*"; }
warn() { echo "[SwiftFormat][warn] $*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

START_DIR="${SRCROOT:-$(pwd)}"

if have git && git -C "$START_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$START_DIR" rev-parse --show-toplevel)"
else
  REPO_ROOT="$START_DIR"
fi

cd "$REPO_ROOT"

if ! have "$SWIFTFORMAT_BIN"; then
  warn "SwiftFormat not found in PATH. Install (e.g., brew install swiftformat) or set SWIFTFORMAT_BIN."
  exit 0
fi

CONFIG_ARGS=()
if [[ -f "$REPO_ROOT/$SWIFTFORMAT_CONFIG" ]]; then
  CONFIG_ARGS=(--config "$REPO_ROOT/$SWIFTFORMAT_CONFIG")
fi

MODE="$SWIFTFORMAT_MODE"
# Flag file override: touch Tools/.lint-all to force all-files mode
if [[ "$MODE" == "auto" && -f "$REPO_ROOT/Tools/.lint-all" ]]; then
  MODE="all"
fi
if [[ "$MODE" == "auto" ]]; then
  # In CI or Release, do NOT mutate sources by default.
  # In local Debug, format changed files (fast) if git available, else do nothing.
  if [[ "${CI:-}" != "" || "${CONFIGURATION:-}" == "Release" ]]; then
    log "Auto mode in CI/Release: not formatting sources. (Set SWIFTFORMAT_MODE=all if you really want this.)"
    exit 0
  fi
  MODE="changed"
fi

if [[ "$MODE" == "changed" ]] && have git; then
  BASE_REF="$SWIFTFORMAT_BASE_BRANCH"
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

  log "Formatting changed files (${#CHANGED_SWIFT[@]})."
  # SwiftFormat accepts file paths as args
  "$SWIFTFORMAT_BIN" ${CONFIG_ARGS[@]+"${CONFIG_ARGS[@]}"} "${CHANGED_SWIFT[@]}"
  exit 0
fi

if [[ "$MODE" == "all" ]]; then
  log "Formatting entire repository at: $REPO_ROOT"
  "$SWIFTFORMAT_BIN" ${CONFIG_ARGS[@]+"${CONFIG_ARGS[@]}"} .
  exit 0
fi

log "Mode=$MODE; nothing to do."
exit 0
