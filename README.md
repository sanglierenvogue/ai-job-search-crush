<p align="center">
  <img src="claude_animation.gif" alt="AI Job Search Assistant" width="200">
</p>

# AI Job Search

> ## Crush Edition
>
> This fork adapts the original [ai-job-search](https://github.com/MadsLorentzen/ai-job-search) framework for [Crush](https://github.com/charmbracelet/crush) (Charm's agentic coding CLI).
>
> **How it works with Crush:**
> - `AGENTS.md` — project context file (candidate profile + workflow rules), auto-discovered by Crush
> - `.crush/skills/` — 6 workflow skills (setup, apply, expand, reset, add-template, add-portal), user-invocable as `project:<name>`
> - `.claude/skills/` and `.agents/skills/` — application and job-portal skills, auto-discovered by Crush
> - `crushrc` — project-local tool permissions so the workflows run without prompts
>
> ```bash
> crush
> project:setup   # configure your profile
> project:job-scraper   # search jobs
> project:apply   # generate tailored CV + cover letter
> ```

An AI-powered job application framework built for [Crush](https://github.com/charmbracelet/crush). Fork it, fill in your profile, and let the AI evaluate job postings, tailor your CV, write cover letters, and prepare you for interviews.

<p align="center">
  <a href="https://ko-fi.com/madslorentzen">
    <img src="https://storage.ko-fi.com/cdn/kofi3.png?v=6" alt="Buy me a coffee at ko-fi.com" height="40">
  </a>
</p>

## What this is

A structured workflow that turns an AI coding agent into a full-stack job application assistant, built for [Crush](https://github.com/charmbracelet/crush). The core workflow (self-profiling, fit evaluation, and the drafter-reviewer application pipeline) is **language- and country-agnostic**. The job portal search skills are built for the Danish market (Jobindex, Jobnet, Akademikernes Jobbank, etc.), but the pattern is designed to be swapped for your local job boards.

```
project:setup      project:job-scraper       project:apply <url>
  |                     |                          |
  v                     v                          v
Fill in             Search job                 Evaluate fit
your profile        portals                    Score & recommend
  |                     |                          |
  v                     v                          v
Profile files       Present matches            Draft CV + Cover Letter
ready               with fit ratings           (LaTeX, tailored)
                        |                          |
                        v                          v
                    Pick a match               Main session researches
                    -> project:apply           the company, then a fresh-context
                                               reviewer subagent critiques
                                               -> Revise -> Final output
```

The framework encodes career guidance best practices, including structured evaluation criteria, forward-looking cover letter framing, and optional salary benchmarking.

## Prerequisites

- [Crush](https://github.com/charmbracelet/crush) (CLI)
- Python 3.10+
- [Bun](https://bun.sh) (for Danish job search CLI tools)
- LaTeX distribution with `lualatex` and `xelatex`: [TeX Live](https://tug.org/texlive/) or [MiKTeX](https://miktex.org/). The CV compiles with `lualatex` (pdflatex often fails on modern MiKTeX installs with `fontawesome5` font-expansion errors); the cover letter compiles with `xelatex` because `cover.cls` requires `fontspec`.
- `poppler-utils` (provides `pdftoppm`, used to render PDFs for visual verification)

## Quick start

### 1. Fork and clone

```bash
gh repo fork MadsLorentzen/ai-job-search --clone
cd ai-job-search
```

### 2. Install job search tools

```bash
cd .agents/skills/jobbank-search/cli && bun install && cd ../../../..
cd .agents/skills/jobdanmark-search/cli && bun install && cd ../../../..
cd .agents/skills/jobindex-search/cli && bun install && cd ../../../..
cd .agents/skills/jobnet-search/cli && bun install && cd ../../../..
cd .agents/skills/linkedin-search/cli && bun install && cd ../../../..
```

For `linkedin-search` the install is optional: it has zero runtime dependencies and runs with plain `bun`; `bun install` only pulls TypeScript dev types.

### 3. Set up your profile

```bash
crush
# Then inside Crush:
project:setup
```

`project:setup` offers three paths: read your `documents/` folder if you have one populated (CV PDF, LinkedIn export, diplomas, reference letters, past applications), import a single CV (paste the text or give a file path), or walk through an interview. It auto-detects what you have and asks. Documents-folder mode is idempotent and safe to re-run as you add more material; see `documents/README.md` for the layout.

### 4. Search for jobs

```
project:job-scraper
```

This searches multiple job portals for positions matching your profile, deduplicates results, and presents them sorted by fit. Pick a match to run `project:apply` on it directly.

### 5. Apply to a job

```
project:apply https://jobindex.dk/job/1234567
```

If the URL can't be fetched (some job portals block automated access), you can paste the job description directly instead:

```
project:apply <paste the full job description here>
```

This runs the full workflow: evaluate fit, draft CV + cover letter, research the company, review with a fresh-context subagent, revise, and present the final output.

## Other skills

`project:setup`, `project:job-scraper`, and `project:apply` form the core workflow. More skills extend it once your profile is in place:

- **`project:expand`** enriches your profile by scanning public sources you've already linked in it (GitHub repos, portfolio site, Kaggle, Google Scholar) and looking up syllabi for named courses and certifications. Discovered competencies are added to your profile with a source tag. Useful right after `project:setup` to surface skills that documents alone don't make explicit.
- **`project:upskill`** analyzes the gap between your profile and your tracked job postings (or a single posting via `project:upskill <URL>`). Produces a prioritized heatmap of skill gaps and a learning plan with web-searched study resources and time estimates. Useful for career planning between applications.
- **`project:add-template`** registers your own LaTeX CV or cover letter template in place of the stock ones. It captures the template's instructions (compile engine, fonts, style rules, page limit), runs a mandatory test compile, and wires the template into `project:apply`. See [LaTeX templates](#latex-templates) below.
- **`project:add-portal`** generates a job-portal search skill for a job board in your market. It investigates the portal (search URL pattern, result structure, access rules), scaffolds the CLI skill from the same structure as the shipped ones, and test-runs a live query before registering. See [Job search tools](#job-search-tools) below.
- **`project:job-application-assistant`** runs individual steps of the application workflow (evaluation, CV, cover letter, interview prep) without the full `project:apply` pipeline.

`project:reset` is also available, see [Starting over](#starting-over) below.

## File structure

```
ai-job-search/
├── AGENTS.md                          # Candidate profile + workflow rules (Crush project context)
├── crushrc                            # Project-local Crush config (tool permissions)
├── .crush/skills/                     # Workflow skills (user-invocable)
│   ├── apply/SKILL.md                 # project:apply (drafter-reviewer pipeline)
│   ├── setup/SKILL.md                 # project:setup onboarding
│   ├── expand/SKILL.md                # project:expand competency enrichment
│   ├── add-template/SKILL.md          # project:add-template register custom LaTeX templates
│   ├── add-portal/SKILL.md            # project:add-portal generate job-portal skill
│   └── reset/SKILL.md                 # project:reset wipe profile data
├── .claude/skills/                    # Application skills (auto-discovered by Crush)
│   ├── job-application-assistant/     # Core application skill
│   │   ├── SKILL.md                   # Skill definition
│   │   ├── 01-candidate-profile.md    # Your education, experience, skills
│   │   ├── 02-behavioral-profile.md   # PI/DISC/personality assessment
│   │   ├── 03-writing-style.md        # Tone, structure, do's and don'ts
│   │   ├── 04-job-evaluation.md       # Scoring framework for job fit
│   │   ├── 05-cv-templates.md         # LaTeX CV structure + tailoring rules
│   │   ├── 06-cover-letter-templates.md # LaTeX cover letter templates
│   │   └── 07-interview-prep.md       # STAR examples + interview framework
│   ├── job-scraper/                   # project:job-scraper job search orchestration
│   └── upskill/                       # project:upskill skill gap analysis and learning plan
├── .agents/skills/                    # Job portal CLI tools (auto-discovered by Crush)
│   ├── jobbank-search/                # Akademikernes Jobbank (Denmark)
│   ├── jobdanmark-search/             # Jobdanmark.dk (Denmark)
│   ├── jobindex-search/               # Jobindex.dk (Denmark)
│   ├── jobnet-search/                 # Jobnet.dk (Denmark, government portal)
│   └── linkedin-search/               # LinkedIn public job listings (country-agnostic)
├── cv/
│   └── main_example.tex               # moderncv LaTeX template
├── cover_letters/
│   ├── cover.cls                      # Custom cover letter LaTeX class
│   └── OpenFonts/                     # Lato + Raleway fonts
├── templates/                         # Custom templates registered via project:add-template
│   └── README.md                      # Folder layout instructions
├── documents/                         # Career source materials for setup Path A and expand
│   ├── README.md                      # Folder layout instructions
│   ├── cv/                            # Master CV (PDF or .tex)
│   ├── linkedin/                      # LinkedIn profile export (PDF)
│   ├── diplomas/                      # Degree certificates and transcripts
│   ├── references/                    # Reference letters
│   └── applications/                  # Past application records (<company>_<role>/)
├── salary_lookup.py                   # Salary benchmarking tool (BYO data)
├── tools/
│   ├── convert_salary_excel.py        # Convert salary Excel to JSON
│   └── README_SALARY_TOOL.md          # Salary tool setup instructions
├── job_scraper/                       # Scraper state (seen jobs, results)
├── upskill/                           # project:upskill report output (markdown reports per run)
├── job_search_tracker.csv             # Application tracking spreadsheet
└── SETUP.md                           # Detailed setup guide
```

## How `project:apply` works

The `project:apply` skill runs a **drafter-reviewer workflow** with mandatory PDF compilation:

1. **Parse** the job posting (URL or text)
2. **Evaluate fit** against your profile (skills, experience, culture, location, career alignment)
3. **Draft** a tailored CV and cover letter in LaTeX
4. **Research the company** in the main session (web search + page fetches), then **dispatch a reviewer subagent** with a fresh context that critiques the drafts inline against the research
5. **Revise** based on the reviewer's feedback
6. **Compile and inspect** both PDFs: lualatex for the CV, xelatex for the cover letter. The rendered pages are converted to images and inspected with the `view` tool, iterating on the LaTeX until the CV is exactly 2 pages with no orphaned entry titles, and the cover letter is exactly 1 page with the signature visible and fonts consistent.
7. **Present** the final output with a verification checklist

All claims in the CV and cover letter are verified against your actual profile. The system never fabricates skills or experience.

### What makes this workflow different

- **PDF verification loop.** Most LaTeX-resume templates produce "looks fine in the .tex" output that breaks in the PDF: job titles orphan to the next page, cover letters spill onto page 2, bullet fonts silently fall back to the body font. `project:apply` compiles, renders the pages to images, and visually inspects every PDF, applying targeted fixes (`\needspace`, `\enlargethispage`, font-matching wrappers for list items) until the layout is clean. This runs automatically on every application.
- **Relevance-weighted CV cutting.** When a CV overflows 2 pages, the workflow does not cut mechanically from the "oldest" section. It scores each candidate line by (a) relevance to the target posting, (b) uniqueness in the document, and (c) whether the cover letter depends on it, and cuts the lowest-total-score line first. An older-role bullet that hits posting keywords survives ahead of a recent-role bullet that does not.
- **Drafter-reviewer separation.** The drafter writes; company research happens in the main session; a reviewer subagent with a fresh context critiques the drafts (research and drafts passed inline, since Crush subagents are read-only). The drafter then revises. This catches missed keywords, weak framing, and generic language that a single pass often leaves in.
- **Token-efficient reviewer dispatch.** The reviewer subagent receives drafts and research inline rather than re-reading them, and the verification checklist runs once at the end of the workflow rather than being duplicated by both agents. Note: the compile-and-inspect step spends some of those savings on PDF rendering and layout iteration — the workflow trades some end-to-end token cost for a real reduction in broken PDFs reaching the user.

## Customization

### Which files to edit manually

If you prefer editing files directly instead of using `project:setup`:

| File | What to change |
|------|---------------|
| `AGENTS.md` | Your full profile (name, education, experience, skills, goals) |
| `01-candidate-profile.md` | Structured version of your CV data |
| `02-behavioral-profile.md` | Your behavioral assessment or self-assessment |
| `04-job-evaluation.md` | Skill match areas, career goals, motivation filters |
| `05-cv-templates.md` | Profile statement templates for different role types |
| `07-interview-prep.md` | Your STAR examples from actual experience |
| `search-queries.md` | Job search queries for your skills and location |

### Updating your search queries

As your priorities evolve, you can reconfigure just the job search without re-running the full profile setup:

```
project:setup --section search
```

This re-runs the search configuration interview: which roles to target, which skills to search for, which locations, and which portals. It also suggests role types you may not have considered based on your profile.

### LaTeX templates

The CV uses [moderncv](https://ctan.org/pkg/moderncv) (banking style). The cover letter uses a custom `cover.cls` with Lato/Raleway fonts.

To use your own template instead, run:

```
project:add-template
```

Point it at your `.tex` file (plus any `.cls`/`.sty` files or bundled fonts). The skill interviews you for the template's instructions — compile engine, fonts and where they live, style rules to preserve, hard page limit — stores everything under `templates/`, runs a mandatory test compile, and activates the template so `project:apply` drafts from it. Templates are stored with `[PLACEHOLDER]` tokens instead of personal data, so they're safe to commit and share.

- `project:add-template --list` shows registered templates
- `project:add-template --use <name>` switches between them
- `project:add-template --use default` reverts to the stock moderncv / cover.cls templates

If you prefer doing it by hand, the manual route still works: update the guidance in `05-cv-templates.md` and `06-cover-letter-templates.md`.

### Job search tools

The four Danish CLI tools in `.agents/skills/` (Jobbank, Jobdanmark, Jobindex, Jobnet) demonstrate the pattern for building a job-portal integration for a specific market. If you're in a different country, run:

```
project:add-portal
```

Give it your local job board's URL. The skill investigates the portal (search-URL pattern, result-page structure, robots.txt/access rules), scaffolds a CLI skill with the same structure, commands, and output contract as the shipped ones, and test-runs a live query before registering anything. Auth-walled portals are declined, and portals with restrictive terms get a prominent personal-use-only warning in the generated skill. The generated skill is market-specific and lives in your fork; the generator itself is the universal part.

For a **country-agnostic** starting point, the repo also includes **`linkedin-search`** — a job-search skill built on LinkedIn's public, unauthenticated `jobs-guest` endpoints. It is field-agnostic, has **zero runtime dependencies** (runs with just `bun`), and takes the search location as an explicit flag, so it works for any market out of the box (`-l "Berlin, Germany"`, `-l "Mumbai, Maharashtra, India"`, `-l "Remote"`, …). It is intended for **personal use only** — automated access is against LinkedIn's Terms of Service, so keep volume low. See `.agents/skills/linkedin-search/SKILL.md`.

### Salary benchmarking

The salary tool works with any salary data you provide (union statistics, Glassdoor exports, personal research, etc.). See `tools/README_SALARY_TOOL.md` for the expected format and setup. If you don't have salary data, the salary step is simply skipped.

### Starting over

To wipe your profile data and start fresh:

```
project:reset profile    # clears skill files, preserves framework rules
project:reset documents  # deletes files from documents/ folder
project:reset all        # both
```

`project:reset` shows exactly what will be deleted and requires you to type `RESET` to confirm. Nothing is deleted until you do.

## Tips for better results

### Profile depth matters

The single biggest factor in output quality is how much detail you put into your profile. A thin profile produces generic applications; a detailed one enables genuinely tailored results.

- **Role descriptions:** Don't just list job titles. Describe what you actually did in each position: specific projects, tools used, responsibilities, and measurable achievements. The more material you provide, the more precisely the system can reframe your experience for different roles.
- **Skills in context:** Instead of listing "Python" or "project management," describe how and where you applied them. "Built ML pipelines for customer churn prediction in Python using scikit-learn" gives the system far more to work with than "Python, machine learning."
- **All onboarding paths work:** Whether you point `project:setup` at your `documents/` folder, paste a single CV, or walk through the interview, the principle is the same: richer input produces sharper output.

### Career path discovery

The framework supports two distinct modes of job searching:

- **Explicit targeting:** You know which roles or sectors you want. The system helps refine and prioritize based on fit.
- **Latent opportunity discovery:** By analyzing your full history (not just job titles, but the actual work you did), the system can surface career paths you haven't considered. Transferable skills that map to unexpected industries, patterns in what you enjoyed or excelled at, or emerging roles that combine your domain expertise with new technology.

To get the most from this, invest time during `project:setup` in describing not just your experience, but what energized you, what drained you, and what you'd want more of. This context directly shapes how the system evaluates fit and which roles it surfaces during `project:job-scraper`.

## Acknowledgements

- [MadsLorentzen](https://github.com/MadsLorentzen) for the original ai-job-search framework
- [Mikkel Krogholm](https://github.com/mikkelkrogsholm) ([skills repo](https://github.com/mikkelkrogsholm/skills)) for the job search CLI skills
- Built for [Crush](https://github.com/charmbracelet/crush) by [Charm](https://charm.sh)

## License

MIT
