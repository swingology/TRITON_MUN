#!/usr/bin/env bash
# tools/watcher-mac.sh
# macOS watcher using fswatch. Watches raw/ and Clippings/ for new files.
# Usage: ./tools/watcher-mac.sh [--auto-ingest]
# Run in background: ./tools/watcher-mac.sh &
# Stop: kill $(cat /tmp/wiki-watcher.pid)
set -euo pipefail

WIKI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RAW_DIR="$WIKI_ROOT/raw"
CLIPPINGS_DIR="$WIKI_ROOT/Clippings"
PENDING="$WIKI_ROOT/raw/.queue/pending.txt"
DONE="$WIKI_ROOT/raw/.queue/done.txt"
PID_FILE="/tmp/wiki-watcher.pid"
AUTO_INGEST=false

[[ "${1:-}" == "--auto-ingest" ]] && AUTO_INGEST=true

if ! command -v fswatch &>/dev/null; then
  echo "Error: fswatch not installed. Run: brew install fswatch" >&2
  exit 1
fi

mkdir -p "$(dirname "$PENDING")"
touch "$PENDING"
touch "$DONE"

echo $$ > "$PID_FILE"
echo "Watcher started (PID $$)"
echo "Watching: $RAW_DIR"
[[ -d "$CLIPPINGS_DIR" ]] && echo "Watching: $CLIPPINGS_DIR"
echo "Queue: $PENDING"
echo "Auto-ingest: $AUTO_INGEST"
echo "Stop with: kill \$(cat $PID_FILE)"

# Build watch targets
WATCH_DIRS=("$RAW_DIR")
[[ -d "$CLIPPINGS_DIR" ]] && WATCH_DIRS+=("$CLIPPINGS_DIR")

fswatch -0 \
  --event Created \
  --event Updated \
  --event MovedTo \
  --exclude '\.queue' \
  --exclude '/\.' \
  "${WATCH_DIRS[@]}" |
while IFS= read -r -d '' filepath; do
  basename="$(basename "$filepath")"
  # Skip dotfiles, already-processed files, and directories
  [[ "$basename" == .* ]] && continue
  [[ "$filepath" == *.processed.md ]] && continue
  [[ -d "$filepath" ]] && continue

  # Skip non-markdown / non-text files
  case "$filepath" in
    *.md|*.txt|*.pdf) ;;
    *) continue ;;
  esac

  # Deduplicate: skip if already in queue or already ingested
  if grep -qxF "$filepath" "$PENDING" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Already queued (skipped): $filepath"
    continue
  fi
  if grep -qxF "$filepath" "$DONE" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Already ingested (skipped): $filepath"
    continue
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Queued: $filepath"
  echo "$filepath" >> "$PENDING"

  if [[ "$AUTO_INGEST" == true ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto-ingesting: $filepath"
    "$WIKI_ROOT/.claude/tools/ingest.sh" "$filepath" || echo "⚠ Ingest failed: $filepath"
  fi
done
