#!/usr/bin/env bash
# tools/ingest-queue.sh
# Processes all files in raw/.queue/pending.txt one at a time.
# Usage: ./tools/ingest-queue.sh [--dry-run]
set -euo pipefail

WIKI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PENDING="$WIKI_ROOT/raw/.queue/pending.txt"
DONE="$WIKI_ROOT/raw/.queue/done.txt"
TOOLS="$WIKI_ROOT/.claude/tools"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

if [[ ! -f "$PENDING" || ! -s "$PENDING" ]]; then
  echo "Queue is empty."
  exit 0
fi

COUNT=0
FAILED=0
REMAINING=()

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  if [[ ! -f "$file" ]]; then
    echo "⚠ Skipping (not found): $file"
    FAILED=$((FAILED + 1))
    continue
  fi

  echo ""
  echo "[$((COUNT + 1))] Processing: $file"

  if [[ "$DRY_RUN" == true ]]; then
    echo "  → dry run, skipping"
    REMAINING+=("$file")
    continue
  fi

  if "$TOOLS/ingest.sh" "$file"; then
    echo "$file" >> "$DONE"
    COUNT=$((COUNT + 1))
  else
    echo "✗ Failed: $file" >&2
    REMAINING+=("$file")
    FAILED=$((FAILED + 1))
  fi
done < "$PENDING"

# Rewrite pending.txt with only failed/remaining entries
printf '%s\n' "${REMAINING[@]}" > "$PENDING"

echo ""
echo "Done. Processed: $COUNT | Failed: $FAILED | Remaining: ${#REMAINING[@]}"
