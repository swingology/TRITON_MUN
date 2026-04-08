#!/usr/bin/env bash
# tools/autopush.sh
# Pushes the wiki to GitHub when conditions are met.
#
# Triggers:
#   --force         Push regardless of conditions
#   --time N        Push if last push was more than N hours ago (default: 4)
#   --commits N     Push if there are N or more unpushed commits (default: 3)
#   --after-ingest  Push if the last commit is an ingest commit
#   (no args)       Evaluate all conditions, push if any are met
#
# Usage:
#   ./tools/autopush.sh                  # auto-evaluate
#   ./tools/autopush.sh --force          # push now
#   ./tools/autopush.sh --time 2         # push if last push > 2h ago
#   ./tools/autopush.sh --commits 5      # push if 5+ unpushed commits
#   ./tools/autopush.sh --after-ingest   # push only if last commit is ingest
set -euo pipefail

WIKI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$WIKI_ROOT"

# ─── Config ──────────────────────────────────────────────────────────────────

REMOTE="${WIKI_REMOTE:-origin}"
BRANCH="${WIKI_BRANCH:-main}"
TIME_THRESHOLD="${WIKI_PUSH_HOURS:-4}"      # hours before time-based push
COMMIT_THRESHOLD="${WIKI_PUSH_COMMITS:-3}"  # unpushed commits before push

# ─── Helpers ─────────────────────────────────────────────────────────────────

log() { echo "[autopush] $*"; }
warn() { echo "[autopush] WARN: $*" >&2; }

has_remote() {
  git remote get-url "$REMOTE" &>/dev/null
}

unpushed_count() {
  git rev-list "${REMOTE}/${BRANCH}..HEAD" --count 2>/dev/null || echo "0"
}

hours_since_last_push() {
  # Time since the tip of the remote branch was last fetched
  local ref_file="$WIKI_ROOT/.git/refs/remotes/$REMOTE/$BRANCH"
  if [[ ! -f "$ref_file" ]]; then
    echo "9999"
    return
  fi
  local mod_time now elapsed
  mod_time=$(stat -c %Y "$ref_file" 2>/dev/null || stat -f %m "$ref_file" 2>/dev/null)
  now=$(date +%s)
  elapsed=$(( (now - mod_time) / 3600 ))
  echo "$elapsed"
}

last_commit_is_ingest() {
  git log -1 --format="%s" | grep -qi "ingest"
}

do_push() {
  log "Pushing to $REMOTE/$BRANCH..."
  git push "$REMOTE" "$BRANCH"
  log "Push complete."
}

# ─── Remote check ────────────────────────────────────────────────────────────

if ! has_remote; then
  warn "No remote '$REMOTE' configured."
  echo ""
  echo "Set up a remote first:"
  echo "  git remote add origin git@github.com:YOUR_USER/YOUR_REPO.git"
  echo ""
  echo "Or set WIKI_REMOTE to use a different remote name."
  exit 1
fi

# Check for anything to push
UNPUSHED=$(unpushed_count)
if [[ "$UNPUSHED" -eq 0 ]]; then
  log "Nothing to push — wiki is up to date with $REMOTE/$BRANCH."
  exit 0
fi

log "Unpushed commits: $UNPUSHED"

# ─── Parse args ──────────────────────────────────────────────────────────────

MODE="auto"
FORCE=false
CUSTOM_TIME=""
CUSTOM_COMMITS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)         FORCE=true; shift ;;
    --after-ingest)  MODE="after-ingest"; shift ;;
    --time)          MODE="time"; CUSTOM_TIME="$2"; shift 2 ;;
    --commits)       MODE="commits"; CUSTOM_COMMITS="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$CUSTOM_TIME" ]]    && TIME_THRESHOLD="$CUSTOM_TIME"
[[ -n "$CUSTOM_COMMITS" ]] && COMMIT_THRESHOLD="$CUSTOM_COMMITS"

# ─── Push logic ──────────────────────────────────────────────────────────────

if [[ "$FORCE" == true ]]; then
  log "Force push requested."
  do_push
  exit 0
fi

SHOULD_PUSH=false
REASON=""

case "$MODE" in
  after-ingest)
    if last_commit_is_ingest; then
      SHOULD_PUSH=true
      REASON="last commit is an ingest"
    else
      log "Last commit is not an ingest — skipping push."
    fi
    ;;

  time)
    HOURS=$(hours_since_last_push)
    log "Hours since last push: $HOURS (threshold: $TIME_THRESHOLD)"
    if (( HOURS >= TIME_THRESHOLD )); then
      SHOULD_PUSH=true
      REASON="${HOURS}h since last push (threshold: ${TIME_THRESHOLD}h)"
    fi
    ;;

  commits)
    log "Unpushed commits: $UNPUSHED (threshold: $COMMIT_THRESHOLD)"
    if (( UNPUSHED >= COMMIT_THRESHOLD )); then
      SHOULD_PUSH=true
      REASON="${UNPUSHED} unpushed commits (threshold: ${COMMIT_THRESHOLD})"
    fi
    ;;

  auto)
    # Evaluate all conditions — push if any are met
    HOURS=$(hours_since_last_push)
    log "Auto-evaluate: unpushed=$UNPUSHED, hours_since_push=${HOURS}h"

    if (( UNPUSHED >= COMMIT_THRESHOLD )); then
      SHOULD_PUSH=true
      REASON="${UNPUSHED} unpushed commits"
    elif (( HOURS >= TIME_THRESHOLD )); then
      SHOULD_PUSH=true
      REASON="${HOURS}h since last push"
    elif last_commit_is_ingest; then
      SHOULD_PUSH=true
      REASON="last commit is an ingest"
    fi
    ;;
esac

if [[ "$SHOULD_PUSH" == true ]]; then
  log "Pushing — reason: $REASON"
  do_push
else
  log "Conditions not met — no push needed."
  log "  Unpushed: $UNPUSHED / $COMMIT_THRESHOLD commits"
  log "  Last push: $(hours_since_last_push)h ago / ${TIME_THRESHOLD}h threshold"
fi
