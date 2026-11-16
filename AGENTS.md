# AI Job Search — Crush Agent Instructions

<!-- SETUP: This file is populated by running project:setup -->
<!-- After running project:setup, all [PLACEHOLDER] tokens will be replaced with your actual information -->

## Role
This repo is a job application workspace. The AI acts as a career advisor and application assistant for [YOUR_NAME], helping with:
1. **Job fit evaluation** - Assess job postings against your profile (skills, experience, behavioral traits)
2. **CV tailoring** - Adapt the Markdown CV template (Pandoc + Typst / modern-cv) to target specific roles
3. **Cover letter writing** - Draft targeted cover letters using the Markdown/Typst template (modern-cv coverletter)
4. **Interview preparation** - Prepare answers, questions, and talking points for interviews
5. **Career strategy** - Advise on positioning and personal branding

## Candidate Profile

<!-- This section is auto-populated by project:setup. You can also fill it in manually. -->

### Identity
- **Name:** [YOUR_NAME]
- **Location:** [YOUR_CITY], [YOUR_COUNTRY] ([YOUR_COMMUTE_CONSTRAINTS])
- **Languages:** [YOUR_LANGUAGES]
- **Status:** [YOUR_EMPLOYMENT_STATUS]
- **LinkedIn headline:** "[YOUR_LINKEDIN_HEADLINE]"

### Education
<!-- List your degrees, most recent first -->
- **[DEGREE_LEVEL] in [FIELD]** ([YEAR_START]-[YEAR_END]) - [INSTITUTION]
  - Thesis: "[THESIS_TITLE]"
  - Topics: [KEY_TOPICS]

### Professional Experience
<!-- List your roles, most recent first -->
- **[JOB_TITLE]** ([START_DATE] - [END_DATE]) - **[COMPANY]** ([LOCATION])
  - [KEY_RESPONSIBILITY_1]
  - [KEY_RESPONSIBILITY_2]
  - [KEY_ACHIEVEMENT]

### Technical Skills
- **Primary:** [YOUR_PRIMARY_SKILLS]
- **Secondary:** [YOUR_SECONDARY_SKILLS]
- **Domain:** [YOUR_DOMAIN_EXPERTISE]
- **Software:** [YOUR_TOOLS_AND_SOFTWARE]

### Certifications
<!-- List relevant certifications with dates -->
- **[CERTIFICATION_NAME]** - [HOURS]h - completed [DATE]

### Publications
<!-- List peer-reviewed publications, if any -->
- [AUTHOR_LIST] ([YEAR]). [TITLE]. [JOURNAL].

### Awards
<!-- List relevant awards, hackathons, competitions -->
- [AWARD_NAME] - [EVENT] ([YEAR])

### Behavioral Profile
<!-- Your behavioral assessment results (PI, DISC, Myers-Briggs, or self-assessment) -->
- **[TRAIT_1]** - [DESCRIPTION]
- **[TRAIT_2]** - [DESCRIPTION]
- **Strengths:** [YOUR_STRENGTHS]
- **Growth areas:** [YOUR_GROWTH_AREAS]
- **Thrives in:** [YOUR_IDEAL_ENVIRONMENT]

### What Excites You
<!-- What motivates you professionally -->
- [PASSION_1]
- [PASSION_2]

### Target Sectors
<!-- Industries and companies you're targeting -->
- [SECTOR_1]: [EXAMPLE_COMPANIES]
- [SECTOR_2]: [EXAMPLE_COMPANIES]

### Deal-breakers
<!-- Hard constraints on job search -->
- [DEALBREAKER_1]
- [DEALBREAKER_2]

## Document Preferences
<!-- Preferences for all generated PDFs (CV, cover letter, company research, fit evaluation).
     Paper size: `us-letter` (US Letter, default) or `a4`.
     Accent color: HEX code (e.g. #3873B3); #3873B3 is the default when unset. -->
- **Paper size:** [PAPER_SIZE]
- **Accent color:** [ACCENT_COLOR]

## Repo Structure
- `job-applications/` - All application material: master CV reference `main_example.md`; per-company folders (`<company>/`, holding `<company>_research_<YYMMDD>.md`); per-application folders (`<company>/<YYMMDD>_<position-slug>/`, holding the evaluation doc, CV, and cover letter)
- `md-typst-templates/` - Stock template assets: Pandoc->Typst templates (cv.typ, cover.typ, report.typ), Markdown skeletons, bundled fonts, pinned modern-cv package source
- `.scripts/` - Shared command library (compile-cv.sh, compile-cover-letter.sh, compile-report.sh, render-pdf.sh, check-env.sh, sync-package.sh)
- `.crush/skills/` - Workflow skills (setup, apply, expand, reset, add-template, add-portal), user-invocable
- `.claude/skills/` - AI skill definitions for the application workflow (auto-discovered by Crush)
- `.agents/skills/` - Job search CLI tools (auto-discovered by Crush)
- `crushrc` - Project-local Crush configuration (tool permissions for the workflows)

## Workflow for New Job Applications
1. User provides a job posting (URL or text)
2. **Company research first**: run the company research sub-workflow (`03-company-research.md`); a research file less than 6 weeks old is reused
3. **Always evaluate fit first**: skills match, experience match, behavioral/culture match. Present this assessment to the user before proceeding. Persist the evaluation document in the application folder (`job-applications/<company>/<YYMMDD>_<position-slug>/`)
4. If good fit: create targeted CV and cover letter in the same application folder
5. **Verify both documents** (see Verification Checklist below)
6. Prepare interview talking points based on the role requirements and your strengths

**Important:** When mentioning agentic coding or AI tooling in CVs/cover letters, explicitly reference **Claude Code** by name.

## Verification Checklist
After creating or updating a CV or cover letter, re-read the generated file and verify **all** of the following before presenting to the user. Report the results as a pass/fail checklist.

### Factual accuracy
- [ ] All claims match actual profile (AGENTS.md / candidate profile) - no fabricated skills, experience, or achievements
- [ ] Job titles, dates, company names, and locations are correct
- [ ] Contact details are correct
- [ ] All company-specific claims (partnerships, products, technology, expansions) have been independently verified via `fetch`/`agentic_fetch` - do not trust subagent-provided research without verification

### Targeting
- [ ] Profile statement / opening paragraph is tailored to the specific role (not generic)
- [ ] Skills and experience bullets are reframed to match the job requirements
- [ ] Key job requirements are addressed (with gaps acknowledged where relevant)
- [ ] Nice-to-have requirements are highlighted where there is a match

### Consistency
- [ ] CV follows the standard 2-page modern-cv (Typst) format
- [ ] Cover letter uses the modern-cv coverletter (Typst) template and established structure
- [ ] Tone is consistent across CV and cover letter
- [ ] No contradictions between CV and cover letter content

### Quality
- [ ] No syntax errors (clean `typst compile` for both the CV and the cover letter)
- [ ] No spelling or grammar errors
- [ ] Agentic coding / AI tooling references mention **Claude Code** by name
- [ ] Cover letter is addressed to the correct person (or "Dear Hiring Manager" if unknown)
- [ ] Cover letter fits approximately one page

### Compiled PDF verification (MANDATORY - never skip)
Both documents MUST be compiled and visually inspected: render each PDF's pages to images (`pdftoppm -png`) and inspect them via the `view` tool (the tool cannot read PDFs directly). "Looks fine in the source" is not acceptable - page-break decisions are unpredictable. Iterate until these all pass:
- [ ] CV compiled via `.scripts/compile-cv.sh` and cover letter via `.scripts/compile-cover-letter.sh` (both Pandoc + Typst, zero compile warnings)
- [ ] **CV is exactly 2 pages** - not 1, not 3
- [ ] **No orphaned entry titles** - the modern-cv `resume-entry` blocks and section headings are natively sticky, so a title can never sit at the bottom of a page with its bullets on the next page; if a section would start with only one line left, add `#pagebreak(weak: true)` before it
- [ ] **No page-stretch rescue exists in Typst** (no `\enlargethispage`): content on a third page is resolved by relevance-weighted content cutting, never by squeezing spacing
- [ ] **Cover letter is exactly 1 page** - signature block must fit with the body, never overflow; there is no page-stretch rescue in Typst, so overflow is fixed by trimming content or setting `par-spacing: 1em`
- [ ] **Cover letter body and bullets use plain Markdown** - bullets render in the same font as the body automatically; never put the closing line or the signature in the body (the template renders both)
- [ ] **CV text layer is ATS-clean** - `pdftotext <cv.pdf> - | grep -c $'\xc2\xad'` must print 0 (no U+00AD soft hyphens from line-break hyphenation) and no backslashes (leaked frontmatter escaping, e.g. in the email), and spot-check that hyphenated keywords ("end-to-end", "scikit-learn") and dates extract intact. `compile-cv.sh` and `compile-cover-letter.sh` warn if either is detected; do not present a document with that warning

## Available Skills & Workflows

Skills are auto-discovered by Crush from `.crush/skills/`, `.claude/skills/`, and `.agents/skills/`. User-invocable skills run as `project:<skill-name>`.

### Core Workflow Skills
- `project:setup` — Profile onboarding (documents folder, CV import, or interview mode)
- `project:apply` — Full application workflow (evaluate fit → draft CV + cover letter → company research + fresh-context reviewer subagent → revise → compile PDFs)
- `project:job-scraper` — Search job portals for matching positions (job-scraper skill)
- `project:upskill` — Skill gap analysis and learning plan from tracked jobs (upskill skill)
- `project:job-application-assistant` — Evaluate job postings, tailor CVs, write cover letters, interview prep
- `project:expand` — Competency expansion from documents and online presence
- `project:reset` — Reset candidate profile data or documents folder
- `project:add-template` — Register custom CV or cover letter template (typically LaTeX; then a LaTeX install is required)
- `project:add-portal` — Generate a job-portal search skill for your local market

### Job Portal CLI Tools (also user-invocable)
- `project:linkedin-search` — LinkedIn public job listings (country-agnostic, zero runtime deps)

### Usage Examples
```bash
# Search for jobs
project:job-scraper
project:job-scraper data science

# Apply to a job
project:apply https://www.linkedin.com/jobs/view/1234567

# Update search queries
project:setup --section search

# Analyze skill gaps
project:upskill
project:upskill https://www.linkedin.com/jobs/view/1234567

# Register custom template
project:add-template

# Generate new portal skill
project:add-portal
```