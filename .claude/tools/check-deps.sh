#!/usr/bin/env bash
# tools/check-deps.sh
set -euo pipefail

DEPS=(inotifywait pdftotext pdfimages tesseract rg jq curl)
MISSING=()

for dep in "${DEPS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    MISSING+=("$dep")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Missing dependencies: ${MISSING[*]}"
  echo ""
  echo "Install with:"
  echo "  sudo apt install inotify-tools poppler-utils tesseract-ocr ripgrep jq curl"
  exit 1
fi

echo "All dependencies present."
