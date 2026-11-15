#!/usr/bin/env bash
#
# check-env.sh — Verify the toolchain the CV / cover-letter workflows need.
#
# Usage:
#   .scripts/check-env.sh
#
# Prints one status line per tool. Exits non-zero if a required tool is
# missing or below its minimum version. The LaTeX toolchain (lualatex,
# xelatex) is still required for cover letters and for the legacy LaTeX CV
# baseline used in the template-parity test.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

MISSING=0

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

echo "== CV / cover-letter toolchain =="
check_cmd pandoc 3.5
check_cmd typst  0.12
check_cmd pdftoppm
check_cmd pdfinfo

echo "== LaTeX (cover letters + legacy CV baseline) =="
# lualatex/xelatex report the engine version, not their own; presence only.
check_cmd lualatex
check_cmd xelatex

echo "== Vendored assets =="
for f in \
  "$ROOT/md-typst-templates/cv.typ" \
  "$ROOT/md-typst-templates/template.md" \
  "$ROOT/md-typst-templates/modern-cv/0.10.0/lib.typ" \
  "$ROOT/cv/main_example.md"
do
  if [[ -f "$f" ]]; then
    echo "OK       ${f#"$ROOT"/}"
  else
    echo "MISSING  ${f#"$ROOT"/}"
    MISSING=$((MISSING + 1))
  fi
done

if [[ "$MISSING" -gt 0 ]]; then
  echo
  echo "FAIL: $MISSING problem(s) — install/fix the items above."
  exit 1
fi
echo
echo "PASS: toolchain ready."
