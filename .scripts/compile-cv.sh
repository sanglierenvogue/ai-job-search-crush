#!/usr/bin/env bash
#
# compile-cv.sh — Compile a Markdown CV to PDF via Pandoc + Typst.
#
# Usage:
#   .scripts/compile-cv.sh <cv.md> [out.pdf]
#
# The Markdown source must carry the identity frontmatter and the content
# (see md-typst-templates/template.md). The Typst intermediate is written to
# a build/ directory next to the source; the PDF is written next to it (or to
# out.pdf when given).
#
# The page count is printed. A count other than 2 is a warning, not a failure
# (the CV skill decides whether to cut content).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $(basename "$0") <cv.md> [out.pdf]" >&2
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

TEMPLATE="$ROOT/md-typst-templates/cv.typ"
FONTS="$ROOT/md-typst-templates/fonts"
[[ -f "$TEMPLATE" ]] || { echo "error: missing template: $TEMPLATE" >&2; exit 66; }

command -v pandoc >/dev/null 2>&1 || { echo "error: pandoc not found" >&2; exit 69; }
command -v typst  >/dev/null 2>&1 || { echo "error: typst not found" >&2; exit 69; }

echo "pandoc: $SRC -> $TYP"
pandoc "$SRC" --template="$TEMPLATE" -o "$TYP"

# Pandoc over-escapes characters in frontmatter values interpolated into the
# template (a@b.com -> a\@b.com, some_user -> some\_user, and similar for
# $ # * ~). Inside a Typst string literal those sequences are not escapes, so
# the backslash is rendered literally into the PDF (an unreadable email).
# Undo the over-escaping from resume.with( through the font-override block
# (which also re-renders $firstname$); \X escapes inside raw content blocks
# are left alone on purpose.
awk '
  /resume\.with\(/ { inblk = 1 }
  inblk {
    gsub(/\\@/, "@"); gsub(/\\_/, "_"); gsub(/\\\$/, "$")
    gsub(/\\#/, "#"); gsub(/\\\*/, "*"); gsub(/\\~/, "~")
  }
  # accent-color hex is also interpolated outside the .with( block (e.g.
  # rgb("#...") in the show rules); Pandoc escapes it the same way, so
  # un-escape those lines too.
  /rgb\("/ { gsub(/\\#/, "#") }
  { print }
  inblk && /^#let cv-body\(\)/ { inblk = 0 }
' "$TYP" > "$TYP.tmp" && mv "$TYP.tmp" "$TYP"

FONT_ARGS=()
if [[ -d "$FONTS" ]]; then
  FONT_ARGS=(--font-path "$FONTS")
fi

echo "typst:  $TYP -> $OUT"
typst compile "${FONT_ARGS[@]}" "$TYP" "$OUT"

if command -v pdfinfo >/dev/null 2>&1; then
  PAGES="$(pdfinfo "$OUT" 2>/dev/null | awk '/^Pages:/ {print $2}')"
  echo "pdf:    $OUT ($PAGES pages)"
  if [[ "$PAGES" != "2" ]]; then
    echo "warning: expected exactly 2 pages, got $PAGES" >&2
  fi
else
  echo "pdf:    $OUT (pdfinfo not available; page count not checked)"
fi

# ATS text-layer checks: line-break hyphens are written into the PDF text
# layer as U+00AD (soft hyphen, UTF-8 C2 AD) and break keyword matching in
# Applicant Tracking Systems; a backslash in the extracted text means an
# over-escaped frontmatter value (e.g. email) leaked into the document.
if command -v pdftotext >/dev/null 2>&1; then
  SOFT_HYPHEN_LINES="$(pdftotext "$OUT" - 2>/dev/null | grep -c $'\xc2\xad' || true)"
  if [[ "${SOFT_HYPHEN_LINES:-0}" != "0" ]]; then
    echo "warning: PDF text layer contains soft hyphens (U+00AD) on $SOFT_HYPHEN_LINES lines; ATS keyword matching may fail" >&2
  fi
  BACKSLASH_LINES="$(pdftotext "$OUT" - 2>/dev/null | grep -c '\\' || true)"
  if [[ "${BACKSLASH_LINES:-0}" != "0" ]]; then
    echo "warning: PDF text layer contains backslashes on $BACKSLASH_LINES lines; check frontmatter values (email, addresses)" >&2
  fi
fi
