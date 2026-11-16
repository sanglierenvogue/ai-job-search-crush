# .scripts — shared command library

Parameterized shell scripts the workflows (and the user) call for CV and
cover-letter compilation. Every script resolves the repo root from its own
location, so it works from any working directory.

| Script | Purpose | Parameters |
|---|---|---|
| `check-env.sh` | Verify the toolchain (pandoc >= 3.5, typst >= 0.12, pdftoppm/pdfinfo) and the vendored template assets. lualatex/xelatex are reported as optional (only needed for user-registered LaTeX templates under `templates/`) | none |
| `compile-cv.sh` | Markdown CV -> PDF via `pandoc` (template `md-typst-templates/cv.typ`) then `typst compile` (bundled fonts). Prints the page count; warns if it is not 2 | `<cv.md> [out.pdf]` |
| `compile-cover-letter.sh` | Markdown cover letter -> PDF via `pandoc` (template `md-typst-templates/cover.typ`, modern-cv `coverletter`) then `typst compile` (bundled fonts). Prints the page count; warns if it is not 1 | `<letter.md> [out.pdf]` |
| `compile-report.sh` | Generic multi-section Markdown (company research, job fit evaluation) -> PDF via `pandoc` (template `md-typst-templates/report.typ`) then `typst compile` (bundled fonts). Prints the page count; no fixed page expectation | `<report.md> [out.pdf]` |
| `render-pdf.sh` | Render a PDF's pages to PNG (for visual inspection). Prints the produced files | `<in.pdf> [out-prefix] [dpi=100]` |
| `analyze-cv-vision.py` | Analyze rendered CV page images with a vision-capable LLM via an OpenAI-compatible chat-completions gateway; prints the model's analysis (text-only smoke mode when given no images) | `[image.png ...] [--prompt P] [--model M] [--base-url U] [--detail D] [--max-tokens N] [--reasoning-effort E] [--save FILE] [--json]` |
| `sync-package.sh` | Install the vendored Typst packages into the repo-root `system-package/` for offline compiles | none |

## Examples

```bash
.scripts/check-env.sh
.scripts/compile-cv.sh job-applications/braun/260515_applied-data-scientist/2605_jh_CV_applied-data-scientist.md
.scripts/compile-cover-letter.sh job-applications/braun/260515_applied-data-scientist/2605_jh_cover-letter_applied-data-scientist.md
.scripts/compile-report.sh job-applications/braun/braun_research_260515.md
.scripts/render-pdf.sh job-applications/braun/260515_applied-data-scientist/2605_jh_CV_applied-data-scientist.pdf
.scripts/sync-package.sh        # only needed on machines without network
```

## Conventions

- Exit codes: 64 bad usage, 66 missing input, 69 missing dependency.
- `compile-cv.sh` and `compile-cover-letter.sh` write the Typst intermediate to
  `<src dir>/build/<name>.typ` and the PDF next to the Markdown (or to
  `out.pdf` when given). Both run ATS text-layer checks on the result (U+00AD
  soft hyphens, stray backslashes) and warn on findings. `compile-report.sh`
  does the same chain without the frontmatter de-escaping pass (the report
  template interpolates no frontmatter values) and without the ATS soft-hyphen
  check.
- `render-pdf.sh` outputs `<prefix>-1.png`, `<prefix>-2.png`, ... The default
  prefix is the PDF basename without extension.
- `analyze-cv-vision.py` is stdlib-only Python (3.10+) and needs `LLM_API_KEY`
  (plus `LLM_BASE_URL`/`LLM_MODEL` when not using the defaults) in the
  repo-root `.env` — copy `.env.example` and fill it in; `.env` is
  gitignored. HTTP/network failures are exit code 75; the key is never
  printed.
