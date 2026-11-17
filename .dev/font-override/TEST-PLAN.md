# TEST PLAN: Typography overrides in cv.typ / cover.typ

Goal: prove the local font overrides in `md-typst-templates/cv.typ` and
`md-typst-templates/cover.typ` change **only the requested properties**
(face/size/weight per element) while the vendored modern-cv 0.10.0 package
stays unmodified, using **programmatic assertions** on the PDF text layer
and font streams, plus a **vision pass** as a layout sanity check.

## Background

The modern-cv `resume`/`coverletter` functions set their own `set text(...)`
and show rules **during body evaluation**, so plain top-level `set`/`show`
in the template does not win. The overrides therefore use three mechanisms
(verified in the session spike, see "Verified mechanics"):

1. A show rule on element properties the package never touches (the name
   header's `weight: "thin"`) — must be defined **before** the
   `#show: resume.with(...)` / `#show: coverletter.with(...)` line.
2. Function shadowing via `#let` (`hiring-entity-info`, `letter-heading`,
   `resume-skill-category`, `resume-skill-item`) — verbatim copies of the
   package functions with only the target values changed.
3. A `#let` wrapper around `$body$` whose `set text` runs after the
   package's own sets (CV: `cv-body`, cover: `letter-body`).

Requested overrides:

| Document | Element | Before | After |
|---|---|---|---|
| CV | first name | Raleway Thin 32pt | Raleway Regular 32pt |
| CV | body default | Lato 11pt | Lato 10pt |
| CV | section headings (H1) | Lato Bold 16pt | Lato Bold 14pt |
| CV | skill category | Lato Bold 11pt | Lato Medium 11pt |
| Cover | first name | Raleway Thin 32pt | Raleway Regular 32pt |
| Cover | body | Lato Light 11pt | Lato Light 10pt |
| Cover | addressee (target) | Lato Bold 12pt | Lato Regular 11pt |
| Cover | position line | Lato Bold 12pt | Lato Medium 10pt |
| Cover | salutation | Lato Light 11pt | Lato Light 10pt |
| Cover | signature name | Lato Bold 11pt | Lato Medium 11pt |

**Lato has no Medium face**, so `weight: "medium"` renders as
`Lato-Regular` (not Bold). The assertions below use `Lato-Regular` as the
proxy for the requested Medium; this is an accepted consequence, not a
failure.

## Prerequisites

1. Toolchain: `.scripts/check-env.sh` (pandoc, typst, pdftoppm, pdfinfo).
2. `pdfminer.six` (for `fontdump.py`): `pip install pdfminer.six`.
3. Vision pass (optional step 4): `.env` at the repo root with
   `LLM_API_KEY` (copy `.env.example`).

## Samples (regenerable, gitignored)

Shared fixtures (fictional persona):
`.dev/cv-typst/samples/sample_typst.md` (CV) and
`.dev/cover-letter-typst/samples/sample_cover.md` (cover).

Artifacts in `samples/`: `before-{cv,cover}.pdf`, `after-{cv,cover}.pdf`,
page PNGs (`-1.png`, `-2.png`), per-line font dumps (`*.txt`), and
vision outputs (`vision-*.txt`).

## Steps

Run from the repo root.

1. **Regenerate the after artifacts** (current templates):
   ```bash
   .scripts/compile-cv.sh .dev/cv-typst/samples/sample_typst.md \
       .dev/font-override/samples/after-cv.pdf
   .scripts/compile-cover-letter.sh \
       .dev/cover-letter-typst/samples/sample_cover.md \
       .dev/font-override/samples/after-cover.pdf
   ```
   Expect zero compile warnings; after-cv = 2 pages, after-cover = 1 page.

2. **Regenerate the before artifacts** (pre-override templates at HEAD).
   The overrides are the only diff, so a detached worktree of HEAD gives a
   clean before-build without touching the working tree. The sample
   Markdown is read from the current repo (`samples/` is gitignored, so
   the worktree has none):
   ```bash
   git worktree add /tmp/fo-before HEAD
   /tmp/fo-before/.scripts/compile-cv.sh \
       .dev/cv-typst/samples/sample_typst.md \
       .dev/font-override/samples/before-cv.pdf
   /tmp/fo-before/.scripts/compile-cover-letter.sh \
       .dev/cover-letter-typst/samples/sample_cover.md \
       .dev/font-override/samples/before-cover.pdf
   git worktree remove --force /tmp/fo-before
   ```
   The worktree's compile scripts resolve their own repo root, so the
   templates and `lang.toml` come from HEAD while the build dir is the
   current repo's `build/` (gitignored scratch).

3. **Render + font-dump** (both before and after):
   ```bash
   cd .dev/font-override/samples
   for f in before-cv after-cv before-cover after-cover; do
     pdftoppm -png -r 100 "$f.pdf" "$f"
     python3 ../fontdump.py "$f.pdf" > "$f.txt"
   done
   ```

4. **Programmatic assertions** (diff of the font dumps + text layer):

   CV (`before-cv.txt` vs `after-cv.txt`):
   - Page count 2 in both (`pdfinfo`).
   - Header name line `'Alex Carter'`: before contains `Raleway-Thin 32.0`;
     after contains `Raleway-Regular 32.0` + `Raleway-Bold 32.0` (last name
     unchanged) and **no `Raleway-Thin` anywhere** in after-cv.txt.
   - Section headings (Education, Professional Experience, Core Competencies,
     Publications, Honors and Awards, References, Languages):
     before `Lato-Bold 16.0` → after `Lato-Bold 14.0`.
   - Body lines (summary, bullets, publications, references):
     before 11.0 → after 10.0, same face (Light where Light, Regular where
     Regular, Bold where Bold).
   - Skill categories (Tools, Domain, NLP, Data Engineering, Machine
     Learning): before `Lato-Bold 11.0` → after `Lato-Regular 11.0`
     (Medium proxy).
   - **Unchanged:** skill values (`Lato-Light 11.0`), entry titles
     (`Lato-Bold 12.0`), entry meta/organizations (`Lato-Regular 11.0`),
     dates (`Lato-Light 9.0`), contact line (`9.0`).
   - ATS: `pdftotext after-cv.pdf - | grep -c $'\xc2\xad'` = 0 and
     `grep -c '\\'` = 0.

   Cover (`before-cover.txt` vs `after-cover.txt`):
   - Page count 1 in both.
   - Header name: before `Raleway-Thin 32.0` → after `Raleway-Regular 32.0`
     + `Raleway-Bold 32.0`; no `Raleway-Thin` in after.
   - Addressee target `'Hiring Team'`: before `Lato-Bold 12.0` → after
     `Lato-Regular 11.0`.
   - Position line: before `Lato-Bold 12.0` → after `Lato-Regular 10.0`
     (Medium proxy).
   - Salutation `'Dear hiring team,'`: before `Lato-Light 11.0` → after
     `Lato-Light 10.0`.
   - Body lines: before `Lato-Light 11.0` → after `Lato-Light 10.0`.
   - Signature: name before `Lato-Bold 11.0` → after `Lato-Regular 11.0`
     (Medium proxy); closing `'Sincerely,'` `Lato-Light 11.0` in **both**.
   - **Unchanged:** date (`Lato-LightItalic 9.0`), company/address/city
     (`Lato-Regular 9.0`), header contact line (`8.0`).
   - ATS: same two grep checks on after-cover.pdf.

5. **Vision pass** (optional, when `.env` has `LLM_API_KEY`):
   ```bash
   .scripts/analyze-vision.py samples/before-cv-1.png samples/before-cv-2.png \
       --kind cv --save samples/vision-before-cv.txt
   .scripts/analyze-vision.py samples/after-cv-1.png samples/after-cv-2.png \
       --kind cv --save samples/vision-after-cv.txt
   .scripts/analyze-vision.py samples/before-cover-1.png \
       --kind cover --save samples/vision-before-cover.txt
   .scripts/analyze-vision.py samples/after-cover-1.png \
       --kind cover --save samples/vision-after-cover.txt
   ```
   Expect exit 0, correct name/sections/addressee/signature in each answer,
   and no new rendering defects in the after documents (clipping, overlaps,
   orphaned headings). The vision model is **not** reliable for weight
   discrimination (Regular vs Thin/Medium at 100 DPI) — the font dumps are
   ground truth for step 4; the vision pass only confirms layout sanity.

6. Score the checklist below.

## Checklist

| # | Check | How |
|---|---|---|
| 1 | Zero compile warnings; page counts 2 (CV) / 1 (cover) | step 1 output |
| 2 | First name Thin → Regular in both documents; no Thin remains | step 4, name line |
| 3 | CV H1 16pt → 14pt, all seven headings | step 4 |
| 4 | CV body 11pt → 10pt, faces unchanged | step 4 diff |
| 5 | Skill category Bold → Regular (Medium proxy) | step 4 |
| 6 | Skill values + entry anatomy unchanged | step 4 |
| 7 | Cover target 12 Bold → 11 Regular | step 4 |
| 8 | Cover position line 12 Bold → 10 Regular (Medium proxy) | step 4 |
| 9 | Cover salutation + body 11 → 10, face Light | step 4 |
| 10 | Cover signature name Bold → Regular (Medium proxy); closing stays Light 11 | step 4 |
| 11 | ATS-clean text layers (0 U+00AD, 0 backslashes) | step 4 greps |
| 12 | Vision pass: content correct, no new layout defects | step 5 outputs |

## Verified mechanics (spike notes)

- typst 0.15.1 resolves `@preview/modern-cv:0.10.0` from the **registry
  cache** (`~/.cache/typst/packages/`), not the repo's `system-package/` —
  patching the vendored package does nothing; overrides must live in the
  template.
- Show rules defined **after** the `resume.with(` / `coverletter.with(`
  line do not apply inside the wrapped content (caused a name-still-thin
  bug; fixed by moving the rule before it).
- The `text` element is opaque (no `.with`, no field accessors) → the name
  rule reconstructs the first name from frontmatter.
- `toml()` rejects package paths → the `letter-heading` shadow's
  `lang.toml` must sit next to the generated .typ (the compile script
  copies it).
- The CV H1 override uses an in-wrapper `show heading.where(level: 1)`,
  which beats the package's own rule; no awk transform needed.
- Pandoc's `$...$` template tokens: the signature line in cover.typ must
  balance `if`/`endif` exactly (an extra `$endif$` is a pandoc parse
  error, not a Typst error).

## Iterate

- Name still Thin after a template edit → the thin-rule is below the
  `resume.with(` / `coverletter.with(` line; move it above.
- Skill categories still Bold → the `resume-skill-item` shadow is missing
  (its internal call resolves inside the package module).
- Cover position line falls back to bold 12 → `lang.toml` missing from the
  build dir (compile script step 70) or the `letter-heading` shadow
  dropped.
- Vision reports an orphaned heading → verify against the text layer
  (`pdftotext -f N -l N`) before acting; at 100 DPI the model has
  mislocated page-boundary content before (Run 1).

## Iteration log

1. **Run 1 (2026-11-17, all assertions pass).**
   - Step 1: both after PDFs compiled with zero warnings (2 / 1 pages).
   - Step 3/4: full `diff` of the four font dumps shows **only** the
     requested changes — no element outside the table above changed face
     or size; ATS greps 0 / 0 on both after PDFs.
   - Step 5 (live): all four calls exit 0. CV pass names Alex Carter, both
     position titles, all contacts and sections in order
     (before 1981 in / 817 out, after 1981 in / 698 out). Cover pass
     names the applicant, addressee, position line, salutation, closing
     and signature (before 1069 in / 397 out, after 1069 in / 374 out).
   - **Known minor weakness (not a failure):** the after-CV vision pass
     reported the "Languages" heading as orphaned at the bottom of page 1;
     the text layer shows the heading **and** its bullet on page 1, and
     page 2 starts with the complete "Publications" heading. Weight and
     page-boundary discrimination are the vision model's weak spots — the
     font dumps remain ground truth.
