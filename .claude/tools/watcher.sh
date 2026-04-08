#!/usr/bin/env bash
# tools/watcher.sh
# Watches raw/ for new files and queues them for ingest.
# Run in background: ./tools/watcher.sh &
# Stop: kill $(cat /tmp/wiki-watcher.pid)
set -euo pipefail

WIKI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RAW_DIR="$WIKI_ROOT/raw"
CLIPPINGS_DIR="$WIKI_ROOT/Clippings"
PENDING="$WIKI_ROOT/raw/.queue/pending.txt"
PID_FILE="/tmp/wiki-watcher.pid"

# Build watch targets — only include directories that exist
WATCH_DIRS=("$RAW_DIR")
[[ -d "$CLIPPINGS_DIR" ]] && WATCH_DIRS+=("$CLIPPINGS_DIR")

echo $$ > "$PID_FILE"
echo "Watcher started (PID $$). Watching: ${WATCH_DIRS[*]}"
echo "Queue: $PENDING"
echo "Stop with: kill \$(cat $PID_FILE)"

inotifywait -m -r \
  --exclude '\.queue' \
  -e close_write,moved_to \
  --format '%w%f' \
  "${WATCH_DIRS[@]}" |
while IFS= read -r filepath; do
  basename="$(basename "$filepath")"
  [[ "$basename" == .* ]] && continue
  [[ "$filepath" == *.processed.md ]] && continue

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Queued: $filepath"
  echo "$filepath" >> "$PENDING"
done
