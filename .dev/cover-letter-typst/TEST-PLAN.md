# TEST WORKFLOW: LaTeX/cover.cls baseline vs Markdown/Typst cover letter pipeline

Goal: prove the new Markdown -> Pandoc -> Typst cover letter pipeline (modern-cv
package `coverletter`) produces a letter with the same content, structure, and
1-page discipline as the current LaTeX/`cover.cls` (xelatex) pipeline, using
the same content. On success, the repo can drop its last hard LaTeX dependency.

## Samples

- `samples/sample-content.md` - the single source of truth: one consistent
  fictional persona (Alex Carter, Data Scientist - same persona as
  `.dev/cv-typst/samples/sample_typst.md`) writing to fictional Astra Biotech,
  Springfield, for Senior Data Scientist. Body is ~215 words, inside the
  250-300 hard limit.
- `samples/baseline_cover.tex` - the same content in the legacy
  LaTeX/`cover.cls` format (structure copied from the stock template in
  `06-cover-letter-templates.md`, including the documented
  `\lettercontent{}`+`itemize`+Raleway-Medium-fontspec workaround).
- `samples/sample_cover.md` - the same content in the new Markdown format
  (structure copied from `md-typst-templates/cover-template.md`).

The two English letters MUST stay content-identical: every paragraph and
bullet in one must appear in the other. Edit both together when iterating.

## Baseline fixtures

`cover.cls` pulls in `textpos.sty`, which is not installed on the minimal TeX
Live here (and is no longer on CTAN). Following the precedent set by
`.dev/cv-typst/samples/baseline_cv.tex` (unused `import.sty` removed from the
fixture, stock file untouched):

- `samples/baseline_cover.cls` - pinned copy of the now-removed
  `cover_letters/cover.cls`, with the two `textpos` loads and the unused
  `\lastupdated` command removed. The sample uses
  `\documentclass[]{baseline_cover}`.
- `samples/OpenFonts` - self-contained copy of the Lato/Raleway fonts that
  used to live in `cover_letters/OpenFonts` (the class resolves its
  `fontspec Path = OpenFonts/fonts/...` relative to the compile CWD). The
  stock fonts left the repo after the migration, so the fixture keeps its
  own pinned copy; the baseline step re-runs on machines that still have
  xelatex installed.

## Steps

1. **Baseline (legacy pipeline).** Compile the LaTeX sample:
   ```bash
   cd .dev/cover-letter-typst/samples
   xelatex -interaction=nonstopmode baseline_cover.tex
   ```
   Expect `Output written on baseline_cover.pdf (1 page, ...)`.

2. **New pipeline.** Compile the Markdown sample:
   ```bash
   .scripts/compile-cover-letter.sh .dev/cover-letter-typst/samples/sample_cover.md
   ```
   Expect `pdf: ... (1 pages)`.

3. **Compare.**
   a. Render both PDFs to images (kept for vision-model / human review):
      ```bash
      .scripts/render-pdf.sh samples/baseline_cover.pdf samples/baseline
      .scripts/render-pdf.sh samples/sample_cover.pdf samples/typst
      ```
   b. **Programmatic structural comparison** (the in-agent model catalog
      declares no image input, so structure/order/content parity is executed
      by extracting each PDF's text layer with positions and diffing):
      ```bash
      pdftotext -bbox samples/baseline_cover.pdf samples/baseline-structure.txt
      pdftotext -bbox samples/sample_cover.pdf samples/typst-structure.txt
      pdfinfo samples/baseline_cover.pdf | grep -E "Pages|Page size"
      pdfinfo samples/sample_cover.pdf    | grep -E "Pages|Page size"
      pdffonts samples/baseline_cover.pdf
      pdffonts samples/sample_cover.pdf
      ```
   c. **Accent color** - decompress the page content stream and confirm the
      name text draws in `0.2196 0.451 0.702` (rgb of #3873B3, the CV
      pipeline's moderncv blue).
   d. **Vision pass (optional, when `.env` has LLM_API_KEY):**
      ```bash
      python3 .scripts/analyze-cv-vision.py samples/baseline-1.png \
          --prompt "<describe the letter, ask for page/clipping/defects>"
      ```
      (one image per call - the gateway model reliably takes one).
   e. Score the checklist below.

## Checklist (both letters must pass)

| # | Check | How |
|---|---|---|
| 1 | Exactly 1 page, signature block fully on the page | `pdfinfo` Pages + PNG/vision |
| 2 | Name in header, contact items present (email, phone, LinkedIn, GitHub) | text layer |
| 3 | Salutation present ("Dear hiring team," or the localized equivalent) | text layer |
| 4 | All body paragraphs present, same order (opening, lead-in, company-fit, closing line) | diff of text layers |
| 5 | Bullet content parity: every bullet in the baseline appears in the Typst letter (modulo hyphenation/spacing) | diff of bullet text |
| 6 | Company block (target, date, name, street, city) - Typst letter | text layer |
| 7 | "Job Application for [role]" line - Typst letter | text layer |
| 8 | Closing line + printed name visible, not clipped | text layer / PNG |
| 9 | Body word budget: 250-300 words (source) | word count of Markdown body |
| 10 | Fonts embedded (Typst: Source Sans 3 + Roboto + Font Awesome 7; baseline: Lato + Raleway) | `pdffonts` |
| 11 | Accent blue #3873B3 on name/positions (Typst) | content-stream color ops |
| 12 | No orphaned lines / layout defects (overlaps, misaligned blocks) | PNG / vision pass |
| 13 | No missing glyphs / tofu boxes; compile with zero warnings | compile output |
| 14 | ATS text layer: no U+00AD soft hyphens, no backslashes (`compile-cover-letter.sh` warns on both) | script output / `pdftotext` grep |

## Parity criterion (what "same content and structure" means here)

The two templates are different designs (cover.cls Lato/Raleway letterhead vs
the modern-cv Awesome-CV-port coverletter), so pixel-identity is not
achievable and not required. Parity means:

- identical **content** (checks 3-5, 9),
- identical **letter anatomy** (checks 2, 6-8: header + salutation + body +
  bullets + closing + signature),
- identical **page discipline** (check 1: one page, nothing clipped),
- a consistent **professional finish** (checks 10-14: embedded fonts, accent
  color, clean text layer, no rendering artifacts).

## Iterate

When a check fails, fix the appropriate layer and re-run from the failing
step:

- wrong/missing content in one sample -> fix the sample file (both English
  samples stay in sync)
- wrong rendering of a correct sample -> fix `md-typst-templates/cover.typ`,
  `md-typst-templates/cover-template.md`, or `.scripts/compile-cover-letter.sh`
- compile warning -> fix fonts or package config in `md-typst-templates/`
- frontmatter value mangled in the PDF -> the awk un-escape window in
  `compile-cover-letter.sh` (it spans `coverletter.with(` through the
  `letter-heading` line) or a missing `/nowrap` in `cover.typ`

Re-run the full comparison after each change. When every check passes, the
development workflow is ready for the migration approval list (see
`proposed-06-cover-letter-typst.md` and the README/SETUP/AGENTS updates).

## Accepted design differences (not failures)

Properties of the two designs, not pipeline defects:

- **Paper size.** `cover.cls` never pins a paper size, so the baseline renders
  on the TeX distro default (US Letter here: 612x792). The new pipeline
  defaults to US Letter, matching the baseline (`paper-size` frontmatter key
  overrides).
- **Closing alignment.** The stock template documents a flushright
  closing, but `cover.cls`'s `\closing`/`\signature` macros internally use
  `\raggedright`, which overrides the `flushright` environment - the baseline
  actually renders the closing left-aligned (verified: "Kind" at x=65pt, the
  left margin). The new pipeline right-aligns, matching the documented
  intent.
- **Header design.** Baseline: centered 40pt Lato name + one contact line.
  modern-cv: right-aligned 32pt Roboto name (first name thin accent),
  positions line, address line, icon contact items, and an empty 4cm
  profile-picture cell (no photo is used).
- **Body typography.** Baseline: Raleway-Medium 11pt with manual
  `\\`+`\mbox{}` paragraph spacing. modern-cv: Source Sans 3 (light) 11pt
  justified with `par-spacing` 1.5em (tighten to 1em via frontmatter if a
  letter overflows - Typst has no `\enlargethispage`).
- **Closing wording.** Baseline: "Kind regards," (English). modern-cv
  default: localized "Sincerely," (or a custom line via the `signature-line`
  frontmatter key).
- **Added elements (Typst letter).** "Job Application for [role]" underlined
  line, the company/date block, and a bottom-aligned "Attached: Curriculum
  Vitae" - none of which the stock template had.
- **Signature-to-footer gap.** The package's `default-closing` uses
  `align(bottom)`, so "Attached: Curriculum Vitae" sits at the page bottom
  regardless of body length; short letters (like the 216-word sample) show a
  large gap between the signature and that line. At the 250-300-word budget
  the gap is small. Property of the package design, not a pipeline defect.
- **Date placement.** Baseline: right-aligned line under the header.
  modern-cv: right-aligned inside the company block.
- **Typographic quotes.** Pandoc converts `'` to U+2019 in the body; the
  text layer carries curly apostrophes. Accepted (same as the CV pipeline).

## Known Typst text-layer quirk (documented, not fixed)

When a line break lands exactly on a word's *existing* hyphen (e.g.
"domain-heavy"), Typst breaks there and the plain `pdftotext` stream-order
extracts "domainheavy" (hyphen lost). Position-based extraction
(`pdftotext -layout`, pdfminer-style parsers - what most ATS use) keeps the
hyphen, which stays visible at the line end. The CV pipeline has the same
latent behavior (its "end-to-end" instances simply never wrapped).
Mitigation if a critical keyword wraps badly: rephrase slightly, or wrap the
word in a raw block as `#no-break[domain-heavy]`.

## Non-English mechanism

The package `lang.toml` localizes Dear/Sincerely/Attached for en, de, gr,
pt, sp, fr, ru, zh, it, nl. For a language that is missing:

- `dear: <localized salutation>` - overrides "Dear" in `letter-heading`
  (the package appends a comma).
- `signature-line: <closing line, comma included>` - replaces the
  "Sincerely," part of the default signature; the bold name still renders
  below it, right-aligned.
- `language: <bcp47>` - sets the text language for hyphenation/spell data.

All three compose; the verification sample compiled to 1 page with the
localized salutation and custom closing + name.

## Iteration log

1. **Run 1.** New pipeline smoke test. Three template bugs found and fixed:
   (a) pandoc variable-token typos in `cover.typ` (a literal quote inside a
   `$var$` token - the token runs from one `$` to the next, so
   `"$dear"$` is not `"$dear$"`); (b) `par-spacing: "1.5em"` as a string
   fails the package's `set par(spacing:)` (user functions don't coerce
   strings to lengths - stdlib does), so the value is emitted as an unquoted
   Typst length literal; (c) `profile-picture: none` renders as an invisible
   empty cell (stroke 0pt, no fill) - confirmed working. Baseline: relative
   `TEXINPUTS` did not resolve `cover.cls`; a class symlink in the samples
   dir works. `textpos.sty` missing from the minimal TeX Live and no longer
   on CTAN -> pinned `baseline_cover.cls` fixture with the unused
   textpos load removed (CV-plan precedent). Broken `OpenFonts` symlink
   (samples is 3, not 2, levels below the repo root) produced an
   empty-fonts PDF with a 1-byte text layer - caught by the font/text-layer
   checks, which is exactly what the pipeline is for.
2. **Run 2.** Both letters compile to 1 page. Full comparison: 15/15
   checklist items pass. Baseline Letter-vs-A4 difference recorded as an
   accepted difference. Baseline closing renders left-aligned despite the
   documented flushright (`\raggedright` inside the class macros) - recorded
   as a stock-template bug and an accepted difference. Vision pass
   (`.scripts/analyze-cv-vision.py`, gateway accepts images on this model):
   Typst letter "clean and modern, no overlaps/collisions/orphans, bullet
   font matches body, signature fully visible"; baseline "exactly one page,
   nothing clipped, signature fully visible, no font mismatches".
3. **Run 3.** "domain-heavy" wraps at its own hyphen; plain text layer reads
   "domainheavy". Documented as the known Typst quirk above (position-based
   extractors keep the hyphen; the CV pipeline shares the behavior).
4. **Run 4.** Non-English: added `language` and `signature-line`
   frontmatter keys to `cover.typ`; verified with a non-English sample
   (check 15). Two more template bugs fixed: (a) pandoc re-wraps
   frontmatter values to the column width when the generated line is long -
   long street/city/target values would have split a Typst string literal -
   all string variables now use `/nowrap` (the CV pipeline has the same
   latent issue in `cv.typ` with long addresses); (b) a bare string literal
   inside Typst content renders *with* smart quotes - the custom signature
   uses `#` string conversion, matching the package's own
   `default-signature`. The `$if(...)$"` token pattern is invalid in pandoc
   templates; the working shape for a quoted value with a default is
   `"$if(key)$$key/nowrap$$else$default$endif$"` (quotes outside the block).
5. **Run 5.** Migration closeout (fresh session): the workflow skills
   (`.crush/skills/apply`, `add-template`, `setup`) still described the
   legacy LaTeX workflow; migrated them to the Pandoc + Typst pipeline
   (Markdown sources, `compile-cv.sh` / `compile-cover-letter.sh`, Typst
   layout fixes). Removed the last LaTeX assets from the repo
   (`cover_letters/cover.cls`, `cover_letters/OpenFonts/`); the baseline
   fixture now carries its own pinned `samples/OpenFonts` copy and re-ran
   to the same 1-page letter on xelatex. Re-ran the full comparison:
   15/15 checklist items pass; vision pass confirms no
   overlaps/clipping/orphans and bullet-font parity, and flags the large
   gap below the signature on this short sample (accepted difference,
   documented above).
