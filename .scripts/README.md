# .scripts — shared command library

Parameterized shell scripts the workflows (and the user) call for CV and
cover-letter compilation. Every script resolves the repo root from its own
location, so it works from any working directory.

| Script | Purpose | Parameters |
|---|---|---|
| `check-env.sh` | Verify the toolchain (pandoc >= 3.5, typst >= 0.12, lualatex, xelatex, pdftoppm/pdfinfo) and the vendored template assets | none |
| `compile-cv.sh` | Markdown CV -> PDF via `pandoc` (template `md-typst-templates/cv.typ`) then `typst compile` (bundled fonts). Prints the page count; warns if it is not 2 | `<cv.md> [out.pdf]` |
| `render-pdf.sh` | Render a PDF's pages to PNG (for visual inspection). Prints the produced files | `<in.pdf> [out-prefix] [dpi=100]` |
| `analyze-cv-vision.py` | Analyze rendered CV page images with a vision-capable LLM via an OpenAI-compatible chat-completions gateway; prints the model's analysis (text-only smoke mode when given no images) | `[image.png ...] [--prompt P] [--model M] [--base-url U] [--detail D] [--max-tokens N] [--reasoning-effort E] [--save FILE] [--json]` |
| `sync-package.sh` | Install the vendored Typst packages into `cv/system-package/` for offline compiles | none |

## Examples

```bash
.scripts/check-env.sh
.scripts/compile-cv.sh cv/250714_braun_applied-data-scientist.md
.scripts/render-pdf.sh cv/250714_braun_applied-data-scientist.pdf
.scripts/sync-package.sh        # only needed on machines without network
```

## Conventions

- Exit codes: 64 bad usage, 66 missing input, 69 missing dependency.
- `compile-cv.sh` writes the Typst intermediate to `<src dir>/build/<name>.typ`
  and the PDF next to the Markdown (or to `out.pdf` when given).
- `render-pdf.sh` outputs `<prefix>-1.png`, `<prefix>-2.png`, ... The default
  prefix is the PDF basename without extension.
- `analyze-cv-vision.py` is stdlib-only Python (3.10+) and needs `LLM_API_KEY`
  (plus `LLM_BASE_URL`/`LLM_MODEL` when not using the defaults) in the
  repo-root `.env` — copy `.env.example` and fill it in; `.env` is
  gitignored. HTTP/network failures are exit code 75; the key is never
  printed.
