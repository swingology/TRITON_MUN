#!/usr/bin/env bash
# tools/search.sh
# Search the wiki by text, tag, and/or domain.
# Usage: search.sh [query] [--tag TAG] [--domain DOMAIN] [--files]
set -euo pipefail

WIKI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WIKI_DIR="$WIKI_ROOT/wiki"

# Resolve rg: prefer system PATH, fall back to Claude Code vendored binary
RG="rg"
if ! command -v rg &>/dev/null; then
  # Try common vendor locations for Claude Code's bundled ripgrep
  _VENDOR_RG="$(find /home -name "rg" -path "*/ripgrep/*" 2>/dev/null | head -1 || true)"
  if [[ -n "$_VENDOR_RG" && -x "$_VENDOR_RG" ]]; then
    RG="$_VENDOR_RG"
  else
    echo "Error: rg (ripgrep) not found. Install with: sudo apt install ripgrep" >&2
    exit 1
  fi
fi

QUERY=""
TAG=""
DOMAIN=""
FILES_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)    TAG="$2";    shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --files)  FILES_ONLY=true; shift ;;
    *)        QUERY="$1"; shift ;;
  esac
done

SEARCH_PATH="$WIKI_DIR"
[[ -n "$DOMAIN" ]] && SEARCH_PATH="$WIKI_DIR/$DOMAIN"

RG_ARGS=("--glob" "*.md" "-l")
[[ "$FILES_ONLY" == false && -n "$QUERY" ]] && RG_ARGS=("--glob" "*.md" "-C" "2" "--heading")

if [[ -n "$TAG" && -n "$QUERY" ]]; then
  TAG_FILES="$("$RG" "tags:.*$TAG" "$SEARCH_PATH" --glob "*.md" -l 2>/dev/null || true)"
  if [[ -z "$TAG_FILES" ]]; then
    echo "No pages tagged: $TAG"
    exit 0
  fi
  echo "$TAG_FILES" | xargs "$RG" "$QUERY" "${RG_ARGS[@]}" 2>/dev/null || echo "No matches."

elif [[ -n "$TAG" ]]; then
  "$RG" "tags:.*$TAG" "$SEARCH_PATH" --glob "*.md" -l 2>/dev/null || echo "No pages tagged: $TAG"

elif [[ -n "$QUERY" ]]; then
  "$RG" "$QUERY" "$SEARCH_PATH" "${RG_ARGS[@]}" 2>/dev/null || echo "No matches."

else
  find "$SEARCH_PATH" -name "*.md" | sort
fi
