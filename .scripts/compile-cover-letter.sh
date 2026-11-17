#!/usr/bin/env bash
#
# compile-cover-letter.sh — Compile a Markdown cover letter to PDF via
# Pandoc + Typst (modern-cv coverletter template).
#
# Usage:
#   .scripts/compile-cover-letter.sh <letter.md> [out.pdf]
#
# The Markdown source must carry the identity/frontmatter and the letter
# body (see md-typst-templates/cover-template.md). The Typst intermediate
# is written to a build/ directory next to the source; the PDF is written
# next to it (or to out.pdf when given).
#
# The page count is printed. A count other than 1 is a warning, not a
# failure (the workflow decides whether to cut content or tighten
# par-spacing).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $(basename "$0") <letter.md> [out.pdf]" >&2
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

TEMPLATE="$ROOT/md-typst-templates/cover.typ"
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
# The affected region spans the coverletter.with(...) frontmatter block AND
# the two generated calls that interpolate frontmatter values
# (hiring-entity-info, letter-heading); undo the over-escaping from
# coverletter.with( through the letter-heading line. \X escapes inside the
# letter body (raw content blocks) are left alone on purpose.
awk '
  /coverletter\.with\(/ { inblk = 1 }
  inblk {
    gsub(/\\@/, "@"); gsub(/\\_/, "_"); gsub(/\\\$/, "$")
    gsub(/\\#/, "#"); gsub(/\\\*/, "*"); gsub(/\\~/, "~")
  }
  { print }
  inblk && /^#letter-heading\(/ { inblk = 0 }
' "$TYP" > "$TYP.tmp" && mv "$TYP.tmp" "$TYP"

# The letter-heading font override in cover.typ loads the package's lang.toml
# relative to the generated .typ file; copy the vendored package file next
# to it so the localized strings resolve.
cp "$ROOT/md-typst-templates/modern-cv/0.10.0/lang.toml" "$BUILD_DIR/lang.toml"

FONT_ARGS=()
if [[ -d "$FONTS" ]]; then
  FONT_ARGS=(--font-path "$FONTS")
fi

echo "typst:  $TYP -> $OUT"
typst compile "${FONT_ARGS[@]}" "$TYP" "$OUT"

if command -v pdfinfo >/dev/null 2>&1; then
  PAGES="$(pdfinfo "$OUT" 2>/dev/null | awk '/^Pages:/ {print $2}')"
  echo "pdf:    $OUT ($PAGES pages)"
  if [[ "$PAGES" != "1" ]]; then
    echo "warning: expected exactly 1 page, got $PAGES" >&2
  fi
else
  echo "pdf:    $OUT (pdfinfo not available; page count not checked)"
fi

# ATS text-layer checks: line-break hyphens are written into the PDF text
# layer as U+00AD (soft hyphen, UTF-8 C2 AD) and break keyword matching in
# Applicant Tracking Systems; a backslash in the extracted text means an
# over-escaped frontmatter value (e.g. email, company) leaked into the
# document.
if command -v pdftotext >/dev/null 2>&1; then
  SOFT_HYPHEN_LINES="$(pdftotext "$OUT" - 2>/dev/null | grep -c $'\xc2\xad' || true)"
  if [[ "${SOFT_HYPHEN_LINES:-0}" != "0" ]]; then
    echo "warning: PDF text layer contains soft hyphens (U+00AD) on $SOFT_HYPHEN_LINES lines; ATS keyword matching may fail" >&2
  fi
  BACKSLASH_LINES="$(pdftotext "$OUT" - 2>/dev/null | grep -c '\\' || true)"
  if [[ "${BACKSLASH_LINES:-0}" != "0" ]]; then
    echo "warning: PDF text layer contains backslashes on $BACKSLASH_LINES lines; check frontmatter values (email, company, addresses)" >&2
  fi
fi
