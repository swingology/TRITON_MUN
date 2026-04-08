#!/usr/bin/env bash
# tools/preprocess.sh
# Preprocesses a source file for LLM ingestion.
# Handles: .md (with image extraction), .pdf, images
# Outputs: path to processed .md file (caller is responsible for cleanup)
set -euo pipefail

WIKI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RAW_ASSETS="$WIKI_ROOT/raw/assets"

SOURCE="${1:-}"
if [[ -z "$SOURCE" || ! -f "$SOURCE" ]]; then
  echo "Error: file not found: ${SOURCE:-<none>}" >&2
  exit 0
fi

EXT="${SOURCE##*.}"
EXT="${EXT,,}"  # lowercase
PROCESSED="${SOURCE}.processed.md"

case "$EXT" in
  md)
    cp "$SOURCE" "$PROCESSED"

    # Download remote images referenced in the markdown
    while IFS= read -r img_url; do
      if [[ "$img_url" =~ ^https?:// ]]; then
        img_name="$(basename "$img_url" | sed 's/[?#].*//')"
        img_local="$RAW_ASSETS/$img_name"
        curl -sL --max-time 10 "$img_url" -o "$img_local" 2>/dev/null || true
        sed -i "s|$img_url|$img_local|g" "$PROCESSED"
      fi
    done < <(grep -oP '!\[.*?\]\(\K[^)]+' "$SOURCE" 2>/dev/null || true)

    # Extract text from local images via tesseract
    while IFS= read -r img_path; do
      if [[ -f "$img_path" && "$img_path" =~ \.(png|jpg|jpeg|webp|tiff|bmp)$ ]]; then
        img_text="$(tesseract "$img_path" stdout 2>/dev/null || echo '[image: OCR failed]')"
        if [[ -n "$img_text" ]]; then
          printf '\n<!-- OCR: %s -->\n%s\n' "$img_path" "$img_text" >> "$PROCESSED"
        fi
      fi
    done < <(grep -oP '!\[.*?\]\(\K[^)]+' "$PROCESSED" 2>/dev/null || true)
    ;;

  pdf)
    # Extract text
    pdftotext "$SOURCE" "$PROCESSED" 2>/dev/null || {
      echo "Warning: pdftotext failed, using empty content" >&2
      touch "$PROCESSED"
    }

    # Extract images and OCR them
    PDF_IMGS="$(mktemp -d)"
    trap 'rm -rf "$PDF_IMGS"' RETURN
    pdfimages -all "$SOURCE" "$PDF_IMGS/img" 2>/dev/null || true

    for img in "$PDF_IMGS"/img*; do
      [[ -f "$img" ]] || continue
      img_text="$(tesseract "$img" stdout 2>/dev/null || true)"
      if [[ -n "$img_text" ]]; then
        printf '\n<!-- OCR from PDF image -->\n%s\n' "$img_text" >> "$PROCESSED"
      fi
      cp "$img" "$RAW_ASSETS/" 2>/dev/null || true
    done
    ;;

  png|jpg|jpeg|webp|tiff|bmp)
    # Direct image — OCR it
    tesseract "$SOURCE" "${PROCESSED%.md}" 2>/dev/null || echo '[OCR failed]' > "$PROCESSED"
    PROCESSED="${PROCESSED%.md}.txt"
    mv "$PROCESSED" "${SOURCE}.processed.md"
    PROCESSED="${SOURCE}.processed.md"
    cp "$SOURCE" "$RAW_ASSETS/" 2>/dev/null || true
    ;;

  *)
    cp "$SOURCE" "$PROCESSED"
    ;;
esac

echo "$PROCESSED"
