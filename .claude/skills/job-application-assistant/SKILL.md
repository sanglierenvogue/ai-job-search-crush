---
name: job-application-assistant
description: >
  Assists with job applications: evaluating job postings, tailoring CVs, writing cover letters,
  and preparing for interviews. Triggers on keywords like: job posting, job application, CV,
  cover letter, resume, interview prep, job fit, career, application, apply, ansøgning, stilling.
  User-invocable as project:job-application-assistant.
user-invocable: true
---

# Job Application Assistant

---

## Workflow

When the user provides a job posting (URL or text), follow this workflow:

### Step 1: Research & Evaluate Fit
- Fetch the job posting content (use `fetch` for URLs)
- Analyze the posting for required competencies, keywords, and priorities
- Research the company (website, LinkedIn, mission, recent news) using `agentic_fetch` and `fetch`
- Score the posting against the candidate's profile using the framework in `04-job-evaluation.md`
- Present the evaluation table and verdict
- Suggest whether the candidate should call the employer before applying (see `04-job-evaluation.md` for guidance)
- Ask the user if they want to proceed with an application

### Step 2: Tailor CV
- Read the most relevant existing CV variant from `cv/` with `view` as a starting point (master reference: `cv/main_example.md`)
- Follow the guidelines in `05-cv-templates.md`
- Create `cv/<YYMMDD>_<company>_<position-slug>.md` (date + role slug, see the skill guide) with tailored content
- Adjust: profile statement, skills section, experience bullet emphasis, section order
- Compile with `.scripts/compile-cv.sh cv/<YYMMDD>_<company>_<position-slug>.md` and run the compile-and-inspect loop until it is exactly 2 pages

### Step 3: Write Cover Letter
- Follow the writing style rules in `03-writing-style.md` (critical: no em-dashes, no cliches)
- Follow the template structure in `06-cover-letter-templates.md`
- Create `cover_letters/cover_<company>_<role>.md` (Markdown with identity + target frontmatter; the closing and signature are rendered by the template)
- Compile with `.scripts/compile-cover-letter.sh cover_letters/cover_<company>_<role>.md` and run the compile-and-inspect loop until it is exactly 1 page
- Ensure the letter connects specific experience to the role requirements

### Step 4: Interview Preparation
- Follow the framework in `07-interview-prep.md`
- Prepare STAR-format answers for likely questions
- Identify role-specific talking points
- Draft questions the candidate should ask the interviewer

---

## Reference Files

| File | Purpose |
|------|---------|
| `01-candidate-profile.md` | Education, experience, skills, publications, awards |
| `02-behavioral-profile.md` | Behavioral assessment, strengths, ideal environments |
| `03-writing-style.md` | Tone, structure, do's and don'ts |
| `04-job-evaluation.md` | Scoring framework for job fit |
| `05-cv-templates.md` | Markdown CV structure and tailoring rules (Pandoc + Typst / modern-cv) |
| `06-cover-letter-templates.md` | Markdown cover letter structure and tailoring rules (Pandoc + Typst / modern-cv coverletter) |
| `07-interview-prep.md` | STAR examples, tough questions, roleplay guidelines |

---

## Quick Commands

The user may also ask for individual steps without the full workflow:
- "Evaluate this job posting" - Step 1 only
- "Write a CV for [company]" - Step 2 only
- "Write a cover letter for [role] at [company]" - Step 3 only
- "Help me prepare for an interview at [company]" - Step 4 only
- "What jobs should I look for?" - Career strategy discussion using profile + evaluation framework
