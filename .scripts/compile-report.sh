#!/usr/bin/env bash
#
# compile-report.sh — Compile a generic multi-section Markdown document
# (company research, job fit evaluation) to PDF via Pandoc + Typst.
#
# Usage:
#   .scripts/compile-report.sh <report.md> [out.pdf]
#
# The Markdown source is plain Markdown (headings, tables, bullets, optional
# `paper-size` frontmatter key). The Typst intermediate is written to a
# build/ directory next to the source; the PDF is written next to it (or to
# out.pdf when given).
#
# No frontmatter de-escaping pass is needed: the template interpolates only
# `paper-size` (values like `us-letter`/`a4` carry no escapable characters).
# The page count is printed; reports have no fixed page expectation.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $(basename "$0") <report.md> [out.pdf]" >&2
  exit 64
fi

SRC="$1"
[[ -f "$SRC" ]] || { echo "error: no such file: $SRC" >&2; exit 66; }

SRC_DIR="$(cd -- "$(dirname -- "$SRC")" && pwd)"
BASE="$(basename -- "$SRC" .md)"
BUILD_DIR="$SRC_DIR/build"
mkdir -p "$BUILD_DIR"
TYP="$BUILD_DIR/$BASE.typ"

OUT="${2:-$SRC_DIR/$BASE.pdf}"

TEMPLATE="$ROOT/md-typst-templates/report.typ"
FONTS="$ROOT/md-typst-templates/fonts"
[[ -f "$TEMPLATE" ]] || { echo "error: missing template: $TEMPLATE" >&2; exit 66; }

command -v pandoc >/dev/null 2>&1 || { echo "error: pandoc not found" >&2; exit 69; }
command -v typst  >/dev/null 2>&1 || { echo "error: typst not found" >&2; exit 69; }

echo "pandoc: $SRC -> $TYP"
pandoc "$SRC" --template="$TEMPLATE" -o "$TYP"

FONT_ARGS=()
if [[ -d "$FONTS" ]]; then
  FONT_ARGS=(--font-path "$FONTS")
fi

echo "typst:  $TYP -> $OUT"
typst compile "${FONT_ARGS[@]}" "$TYP" "$OUT"

if command -v pdfinfo >/dev/null 2>&1; then
  PAGES="$(pdfinfo "$OUT" 2>/dev/null | awk '/^Pages:/ {print $2}')"
  echo "pdf:    $OUT ($PAGES pages)"
else
  echo "pdf:    $OUT (pdfinfo not available; page count not checked)"
fi

# A backslash in the extracted text means leaked escaping (e.g. an email or
# URL value that should not carry backslashes).
if command -v pdftotext >/dev/null 2>&1; then
  BACKSLASH_LINES="$(pdftotext "$OUT" - 2>/dev/null | grep -c '\\' || true)"
  if [[ "${BACKSLASH_LINES:-0}" != "0" ]]; then
    echo "warning: PDF text layer contains backslashes on $BACKSLASH_LINES lines; check source content (emails, URLs)" >&2
  fi
fi
