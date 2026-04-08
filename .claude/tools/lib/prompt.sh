#!/usr/bin/env bash
# tools/lib/prompt.sh
# Builds the ingest prompt from processed source + schema + index

build_ingest_prompt() {
  local source_file="$1"
  local wiki_root="$2"
  local basename
  basename="$(basename "$source_file")"

  printf '%s\n\n' "$(cat "$wiki_root/CLAUDE.md")"
  printf '## Current Index\n\n%s\n\n' "$(cat "$wiki_root/wiki/index.md")"
  printf '## Task: Ingest Source\n\n'
  printf 'Source file: %s\n\n' "$basename"
  printf 'Follow the Ingest Workflow in CLAUDE.md exactly. Write all wiki pages, update index.md, append to log.md.\n\n'
  printf '## Source Content\n\n%s\n' "$(cat "$source_file")"
}

build_lint_prompt() {
  local wiki_root="$1"

  printf '%s\n\n' "$(cat "$wiki_root/CLAUDE.md")"
  printf '## Current Index\n\n%s\n\n' "$(cat "$wiki_root/wiki/index.md")"
  printf '## Recent Log\n\n%s\n\n' "$(tail -50 "$wiki_root/wiki/log.md")"
  printf '## Task: Lint\n\nRun the Lint Workflow from CLAUDE.md. Output a full report.\n'
}
