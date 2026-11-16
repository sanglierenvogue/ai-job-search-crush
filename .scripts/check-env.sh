#!/usr/bin/env bash
#
# check-env.sh — Verify the toolchain the CV / cover-letter workflows need.
#
# Usage:
#   .scripts/check-env.sh
#
# Prints one status line per tool. Exits non-zero if a required tool is
# missing or below its minimum version. The stock CV and cover-letter
# pipelines are pure Pandoc + Typst; the LaTeX toolchain (lualatex, xelatex)
# is optional and only needed for user-registered LaTeX templates under
# templates/.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# version_ok <version-string> <min-version>  (uses sort -V)
version_ok() {
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | tail -1)" == "$1" ]]
}

check_cmd() {
  local name="$1" min="${2:-}"
  local path ver
  if ! path="$(command -v "$name" 2>/dev/null)"; then
    echo "MISSING  $name"
    MISSING=$((MISSING + 1))
    return
  fi
  if [[ -n "$min" ]]; then
    ver="$("$path" --version 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)"
    if [[ -n "$ver" ]] && version_ok "$ver" "$min"; then
      echo "OK       $name $ver (min $min)"
    else
      echo "TOOOLD   $name ${ver:-unknown} (min $min)"
      MISSING=$((MISSING + 1))
    fi
  else
    echo "OK       $name"
  fi
}

MISSING=0
OPTIONAL_MISS=0

echo "== Optional: LaTeX (only for user-registered custom templates) =="
# The stock pipeline is Pandoc + Typst only; a missing LaTeX toolchain must
# not fail the check.
check_cmd lualatex
check_cmd xelatex
OPTIONAL_MISS=$((MISSING))
MISSING=0

echo "== CV / cover-letter toolchain =="
check_cmd pandoc 3.5
check_cmd typst  0.12
check_cmd pdftoppm
check_cmd pdfinfo

echo "== Vendored assets =="
for f in \
  "$ROOT/md-typst-templates/cv.typ" \
  "$ROOT/md-typst-templates/template.md" \
  "$ROOT/md-typst-templates/cover.typ" \
  "$ROOT/md-typst-templates/cover-template.md" \
  "$ROOT/md-typst-templates/report.typ" \
  "$ROOT/md-typst-templates/modern-cv/0.10.0/lib.typ" \
  "$ROOT/job-applications/main_example.md"
do
  if [[ -f "$f" ]]; then
    echo "OK       ${f#"$ROOT"/}"
  else
    echo "MISSING  ${f#"$ROOT"/}"
    MISSING=$((MISSING + 1))
  fi
done

if [[ "$OPTIONAL_MISS" -gt 0 ]]; then
  echo
  echo "note: $OPTIONAL_MISS optional LaTeX tool(s) missing - fine unless templates/ holds a LaTeX template."
fi

if [[ "$MISSING" -gt 0 ]]; then
  echo
  echo "FAIL: $MISSING problem(s) — install/fix the items above."
  exit 1
fi
echo
echo "PASS: toolchain ready."
