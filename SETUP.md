# Setup Guide

Step-by-step instructions for getting the AI Job Search framework running with [Crush](https://github.com/charmbracelet/crush).

## 1. Prerequisites

### Crush

Install Crush (Charm's agentic coding CLI):

```bash
# Homebrew
brew install charmbracelet/tap/crush

# or NPM
npm install -g @charmland/crush

# or Go
go install github.com/charmbracelet/crush@latest
```

Check with `crush --version`. Crush is configured with your model providers via `crushrc`/`crush.json` (see the [Crush docs](https://github.com/charmbracelet/crush)).

### Python

Python 3.10+ is required for the salary lookup tool. Check with:

```bash
python --version
```

### Bun (for job search tools)

The job portal CLIs (four Danish portals plus the country-agnostic LinkedIn tool) are written in TypeScript and run with Bun:

```bash
curl -fsSL https://bun.sh/install | bash
```

### Pandoc + Typst (for compiling CVs)

CVs are written in Markdown and compiled to PDF through Pandoc and Typst. Install:

- **Pandoc 3.5+** — [pandoc.org](https://pandoc.org/installing.html) (Windows: `winget install JohnMacFarlane.Pandoc`; macOS: `brew install pandoc`; Linux: package manager)
- **Typst 0.12+** — [typst.app/docs/installation](https://typst.app/docs/installation/) (Windows: `winget install Typst.Typst`; macOS: `brew install typst`; Linux: package manager or GitHub releases)

On first compile, Typst downloads the `modern-cv` package (and its dependencies) from the Typst registry and caches them. On a machine without network access at compile time, run `.scripts/sync-package.sh` once to install the pinned package sources that ship in `md-typst-templates/`.

### LaTeX (for compiling cover letters)

Install a LaTeX distribution to compile the cover letter `.tex` files to PDF:

- **Windows:** [MiKTeX](https://miktex.org/download)
- **macOS:** [MacTeX](https://tug.org/mactex/)
- **Linux:** `sudo apt install texlive-full` or `sudo dnf install texlive-scheme-full`

The cover letter compiles with `xelatex` because `cover.cls` requires `fontspec` for its custom Lato/Raleway fonts. (A full LaTeX install with `lualatex` is only needed if you keep using custom LaTeX CV templates via `project:add-template`.)

### poppler-utils (for PDF verification)

The `project:apply` workflow renders compiled PDFs to images for visual layout verification, which uses `pdftoppm`:

- **macOS:** `brew install poppler`
- **Linux:** `sudo apt install poppler-utils` or `sudo dnf install poppler-utils`

## 2. Fork and clone

```bash
gh repo fork MadsLorentzen/ai-job-search --clone
cd ai-job-search
```

Or manually: fork on GitHub, then clone your fork.

## 3. Install job search CLI dependencies

```bash
for tool in jobbank-search jobdanmark-search jobindex-search jobnet-search linkedin-search; do
  cd .agents/skills/$tool/cli && bun install && cd ../../../..
done
```

For `linkedin-search` the install is optional: it has zero runtime dependencies and runs with plain `bun`; `bun install` only pulls TypeScript dev types.

If you're outside Denmark, you can generate an equivalent search skill for your local job board with `project:add-portal` — it scaffolds the same CLI structure for any public portal and test-runs a live query before registering. See the "Job search tools" section in the README.

## 4. Run the setup interview

Start Crush in the repository:

```bash
crush
```

Then run the onboarding:

```
project:setup
```

Crush will offer three paths:

- **Path A (documents folder):** Add your CV, LinkedIn export, diplomas, references, or past applications under `documents/`. Crush reads and cross-references them before proposing profile updates. This is best when you have several source files.
- **Path B (single CV import):** Share one CV/resume by pasting the text or giving a file path. Crush extracts it and asks follow-up questions for anything missing.
- **Path C (interview mode):** Answer structured interview questions section by section.

All three paths produce the same result: fully populated profile files.

### What gets populated

| File | Content |
|------|---------|
| `AGENTS.md` | Your full candidate profile |
| `01-candidate-profile.md` | Structured education, experience, skills |
| `02-behavioral-profile.md` | Behavioral assessment |
| `04-job-evaluation.md` | Personalized skill match areas and career goals |
| `05-cv-templates.md` | Profile statement templates for your background |
| `07-interview-prep.md` | STAR examples from your experience |
| `cv/main_example.tex` | Your LaTeX CV with actual details |
| `search-queries.md` | Job search queries for `project:job-scraper` |

### Re-running setup

You can update specific sections later:

```
project:setup --section skills
project:setup --section experience
project:setup --section search
```

The `--section search` option is especially useful as your priorities evolve. It re-runs the search configuration interview and suggests role types you may not have considered based on your full profile.

## 5. Optional: Set up salary benchmarking

If you have salary data (from a union, salary survey, Glassdoor, or personal research):

1. **Option A:** Create `salary_data.json` manually in the repo root (see `tools/README_SALARY_TOOL.md` for the format)
2. **Option B:** Convert from Excel:
   ```bash
   pip install openpyxl
   python tools/convert_salary_excel.py path/to/salary-data.xlsx --source "My Salary Data 2025"
   ```

This creates `salary_data.json` which the `project:apply` workflow uses for salary benchmarking. If you skip this step, salary lookup is simply omitted.

## 6. Test the workflow

Find a job posting you're interested in, then:

```
project:apply https://jobindex.dk/job/1234567
```

Or paste the job description directly:

```
project:apply [paste job posting text here]
```

Crush will:
1. Evaluate the fit against your profile
2. Ask if you want to proceed
3. Draft a tailored CV and cover letter
4. Research the company, then have a reviewer subagent (fresh context) critique the drafts
5. Revise, compile both PDFs, inspect the rendered pages, and present the final output

## 7. Compile your documents

After `project:apply` creates the documents (the workflow already compiles and verifies both PDFs):

```bash
# Compile CV (Markdown -> Pandoc -> Typst -> PDF)
.scripts/compile-cv.sh cv/<YYMMDD>_<company>_<position-slug>.md

# Compile cover letter
cd cover_letters && xelatex cover_<company>_<role>.tex && cd ..
```

These commands apply to the stock templates (modern-cv Typst CV, `cover.cls` cover letter). If you'd rather use your own template, run `project:add-template` — it captures the template's compile engine, fonts, style rules, and page limit, test-compiles it, and wires it into `project:apply`. See the "CV and cover-letter templates" section in the README.

## Permissions

The project ships a `crushrc` in the repo root that pre-approves the tools the workflows need (`view`, `edit`, `write`, `bash`, `fetch`, `agentic_fetch`, `agent`, ...) so `project:apply` and friends run without permission prompts. If you'd rather be prompted, remove or trim the `permissions allow` line.

## Troubleshooting

### "salary_data.json not found"
This is expected if you haven't set up salary benchmarking. The `project:apply` workflow skips this step automatically.

### Skills not appearing
Crush auto-discovers skills from `.crush/skills/`, `.claude/skills/`, and `.agents/skills/`. If a workflow skill doesn't show up, check that its `SKILL.md` has valid YAML frontmatter with `name` and `description`, and that `user-invocable: true` is set for the ones you invoke manually.

### User-invocable skills
Invoke them as `project:<skill-name>` (e.g. `project:apply`, `project:job-scraper`). Model-invoked skills (like the job-portal CLIs) also trigger automatically from their descriptions when relevant.

### Job search CLI tools not working
Make sure Bun is installed and you ran `bun install` in each CLI directory. The tools require network access to fetch job listings.

### CV compilation errors (Pandoc / Typst)
- Run `.scripts/check-env.sh` to verify pandoc >= 3.5, typst >= 0.12, and the vendored template assets.
- The CV compile is `pandoc` (template `md-typst-templates/cv.typ`) followed by `typst compile` with the bundled fonts; warnings about unknown font families mean the `--font-path` to `md-typst-templates/fonts` was dropped.
- On an offline machine, run `.scripts/sync-package.sh` once so the `@preview/modern-cv` import resolves locally.

### Cover letter compilation errors (LaTeX)
- Cover letter: uses `xelatex` (for custom fonts in `OpenFonts/fonts/`)
- Make sure your LaTeX distribution includes the `fontspec` package

### Fonts not found in cover letter
The cover letter template expects fonts in `cover_letters/OpenFonts/fonts/`. Make sure this directory exists and contains the Lato and Raleway font files.

### PDFs can't be inspected
The `project:apply` workflow renders PDF pages to images with `pdftoppm` before inspecting them. If the command is missing, install `poppler-utils` (see Prerequisites).
