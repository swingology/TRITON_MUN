#!/usr/bin/env bash
# tools/lint.sh
# Runs a wiki health check via the LLM.
# Usage: ./tools/lint.sh
set -euo pipefail

WIKI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOLS="$WIKI_ROOT/.claude/tools"
source "$TOOLS/lib/prompt.sh"

echo "→ Building lint prompt..."
PROMPT_FILE="$(mktemp /tmp/wiki-lint-prompt-XXXXXX.txt)"
trap 'rm -f "$PROMPT_FILE"' EXIT
build_lint_prompt "$WIKI_ROOT" > "$PROMPT_FILE"

DATE="$(date '+%Y-%m-%d')"
REPORT="$WIKI_ROOT/wiki/queries/lint-$DATE.md"

echo "→ Running lint (qwen3.5:397b-cloud)..."
cd "$WIKI_ROOT"
claude --print \
  --allowedTools "Read,Write,Edit,Glob,Grep" \
  -p "$(cat "$PROMPT_FILE")"

echo "→ Lint complete. Report: $REPORT"
