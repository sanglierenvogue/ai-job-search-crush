#!/usr/bin/env bash
#
# render-pdf.sh — Render every page of a PDF to a PNG for visual inspection.
#
# Usage:
#   .scripts/render-pdf.sh <in.pdf> [out-prefix] [dpi]
#
# Writes <out-prefix>-1.png, <out-prefix>-2.png, ... (default prefix is the
# PDF's basename, in the PDF's directory; default dpi is 100). The list of
# produced files is printed one per line on stdout.
set -euo pipefail

if [[ $# -lt 1 || $# -gt 3 ]]; then
  echo "usage: $(basename "$0") <in.pdf> [out-prefix] [dpi]" >&2
  exit 64
fi

PDF="$1"
[[ -f "$PDF" ]] || { echo "error: no such file: $PDF" >&2; exit 66; }
DPI="${3:-100}"

PDF_DIR="$(cd -- "$(dirname -- "$PDF")" && pwd)"
PREFIX="${2:-$PDF_DIR/$(basename -- "$PDF" .pdf)}"

command -v pdftoppm >/dev/null 2>&1 || { echo "error: pdftoppm not found (install poppler-utils)" >&2; exit 69; }

pdftoppm -png -r "$DPI" "$PDF" "$PREFIX" >/dev/null
for f in "$PREFIX"-*.png; do
  echo "$f"
done
