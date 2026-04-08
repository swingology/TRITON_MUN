#!/usr/bin/env bash
# tools/ingest.sh
# Ingests a single source file into the wiki.
# Usage: ./tools/ingest.sh <source-file> [--dry-run]
set -euo pipefail

WIKI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOLS="$WIKI_ROOT/.claude/tools"
# shellcheck source=tools/lib/prompt.sh
source "$TOOLS/lib/prompt.sh"

DRY_RUN=false
SOURCE=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) SOURCE="$arg" ;;
  esac
done

if [[ -z "$SOURCE" || ! -f "$SOURCE" ]]; then
  echo "Usage: ingest.sh <source-file> [--dry-run]" >&2
  exit 1
fi

echo "→ Preprocessing: $SOURCE"
PROCESSED="$("$TOOLS/preprocess.sh" "$SOURCE")"
trap 'rm -f "$PROCESSED"' EXIT

echo "→ Building prompt..."
PROMPT_FILE="$(mktemp /tmp/wiki-ingest-prompt-XXXXXX.txt)"
trap 'rm -f "$PROCESSED" "$PROMPT_FILE"' EXIT
build_ingest_prompt "$PROCESSED" "$WIKI_ROOT" > "$PROMPT_FILE"

echo "→ Prompt size: $(wc -c < "$PROMPT_FILE") bytes"

if [[ "$DRY_RUN" == true ]]; then
  echo "→ Dry run — prompt written to: $PROMPT_FILE"
  echo "→ First 20 lines:"
  head -20 "$PROMPT_FILE"
  exit 0
fi

echo "→ Running qwen3.5:397b-cloud ingest..."
cd "$WIKI_ROOT"
claude --print \
  --allowedTools "Read,Write,Edit,Glob,Grep" \
  -p "$(cat "$PROMPT_FILE")"

echo "→ Done: $(basename "$SOURCE")"
