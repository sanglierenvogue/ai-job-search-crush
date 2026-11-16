---
name: job-application-assistant
description: >
  Assists with job applications: company research, evaluating job postings,
  tailoring CVs, writing cover letters, and preparing for interviews.
  Triggers on keywords like: job posting, job application, CV, cover letter,
  resume, interview prep, job fit, career, application, apply.
  User-invocable as project:job-application-assistant.
user-invocable: true
---

# Job Application Assistant

---

## Application Folder

All artifacts for an application are stored together:

```
job-applications/<company>/<YYMMDD>_<position-slug>/
```

- `<company>` is the company name normalized to lowercase hyphenated form
  (e.g. `Example Corp` -> `example-corp`).
- `<YYMMDD>` is the date the application is started.
- `<position-slug>` is the role title lowercased and hyphenated
  (e.g. `260515_applied-data-scientist`).
- `<user-initials>` in file names is the lowercase first+last initial of the
  candidate (e.g. `jh`), derived from the identity frontmatter
  (`firstname`/`lastname`).

Create the folder when starting Step 2. The master CV reference lives at
`job-applications/main_example.md`.

---

## Workflow

When the user provides a job posting (URL or text), follow this workflow:

### Step 1: Company Research
- Run the sub-workflow in `03-company-research.md` for the posting's company.
- Its 6-week freshness gate decides whether research runs or an existing
  `job-applications/<company>/<company>_research_*.md` is reused.
- The resulting research file is the company knowledge base for all later
  steps.

### Step 2: Position Research & Fit Evaluation
- Fetch the job posting content (use `fetch` for URLs) and keep the **full
  posting text** for the evaluation document.
- If the job came from the job-scraper workflow, look it up in
  `job_scraper/seen_jobs.json` (by URL or company+title) and take its
  `fit_reason`; otherwise record "n/a (manually provided)".
- Analyze the posting for required competencies, keywords, and priorities.
- Score the posting against the candidate's profile using the framework in
  `04-job-evaluation.md` (use the company research from Step 1 for the
  behavioral/culture dimension).
- Create the application folder `job-applications/<company>/<YYMMDD>_<position-slug>/`
  and persist the evaluation: write `<position-slug>.md` (structure in
  `04-job-evaluation.md` → "Persisting the evaluation") and compile it to
  `<position-slug>.pdf` with `.scripts/compile-report.sh`.
- Present the evaluation table and verdict.
- Suggest whether the candidate should call the employer before applying
  (see `04-job-evaluation.md` for guidance).
- Ask the user if they want to proceed with an application.

### Step 3: Tailor CV
- Read the most relevant existing CV variant from `job-applications/` with
  `view` as a starting point (master reference: `job-applications/main_example.md`).
- Follow the guidelines in `06-cv-templates.md`
- Create `job-applications/<company>/<YYMMDD>_<position-slug>/<YYMM>_<user-initials>_CV_<position-slug>.md`
  with tailored content
- Adjust: profile statement, skills section, experience bullet emphasis, section order
- Compile with `.scripts/compile-cv.sh` on that file and run the compile-and-inspect loop until it is exactly 2 pages

### Step 4: Write Cover Letter
- Follow the writing style rules in `05-writing-style.md` (critical: no em-dashes, no cliches)
- Follow the template structure in `07-cover-letter-templates.md`
- Create `job-applications/<company>/<YYMMDD>_<position-slug>/<YYMM>_<user-initials>_cover-letter_<position-slug>.md` (Markdown with identity + target frontmatter; the closing and signature are rendered by the template)
- Compile with `.scripts/compile-cover-letter.sh` on that file and run the compile-and-inspect loop until it is exactly 1 page
- Ensure the letter connects specific experience to the role requirements

### Step 5: Interview Preparation
- Follow the framework in `08-interview-prep.md`
- Prepare STAR-format answers for likely questions
- Identify role-specific talking points
- Draft questions the candidate should ask the interviewer

---

## Reference Files

| File | Purpose |
|------|---------|
| `01-candidate-profile.md` | Education, experience, skills, publications, awards |
| `02-behavioral-profile.md` | Behavioral assessment, strengths, ideal environments |
| `03-company-research.md` | Company research sub-workflow (durable research file, 6-week freshness) |
| `04-job-evaluation.md` | Scoring framework for job fit + evaluation document format |
| `05-writing-style.md` | Tone, structure, do's and don'ts |
| `06-cv-templates.md` | Markdown CV structure and tailoring rules (Pandoc + Typst / modern-cv) |
| `07-cover-letter-templates.md` | Markdown cover letter structure and tailoring rules (Pandoc + Typst / modern-cv coverletter) |
| `08-interview-prep.md` | STAR examples, tough questions, roleplay guidelines |

---

## Quick Commands

The user may also ask for individual steps without the full workflow:
- "Research <company>" - Step 1 only (company research sub-workflow)
- "Evaluate this job posting" - Step 2 only
- "Write a CV for [company]" - Step 3 only
- "Write a cover letter for [role] at [company]" - Step 4 only
- "Help me prepare for an interview at [company]" - Step 5 only
- "What jobs should I look for?" - Career strategy discussion using profile + evaluation framework
