---
name: apply
description: >
  Full job application workflow: evaluate fit, draft a tailored CV and cover letter in
  Markdown (Pandoc + Typst), company research plus fresh-context reviewer subagent
  critique, revise, compile, and visually verify the PDFs. User-invocable as project:apply
  followed by a job posting URL or pasted posting text.
user-invocable: true
---

# Apply: Drafter-Reviewer Job Application Workflow

You are orchestrating a two-agent job application workflow. The job posting is provided in the user's invocation message (either a URL or pasted text).

Follow these steps **exactly in order**. Do not skip steps.

**Token-efficiency rules for this workflow:**
- Never re-read a file whose contents are already in your context from an earlier step. If you read it in Step 1, it is still available in Step 2.
- When dispatching the reviewer subagent, pass the drafts and the company research brief **inline in the agent prompt** rather than asking the subagent to read files you already have in memory.
- Run the full verification checklist exactly once, at the end (Step 6). The reviewer focuses on content critique, not verification.
- Step 5 (compile and inspect PDFs) is mandatory and non-skippable — page-break decisions are unpredictable, and `.md` files that look fine often produce broken PDFs (CV content spilling to a third page, cover letters spilling to page 2 with a clipped signature).

---

## Step 0: Parse Input

- If the provided input looks like a URL, use `fetch` (markdown format) to retrieve the job posting content.
- If it is pasted text, use it directly.
- Extract: **company name**, **role title**, **department** (if mentioned), **location**, and **language** of the posting.
- Store these for use throughout the workflow.

---

## Step 1: DRAFTER - Evaluate Fit

Read the evaluation framework with `view`:
- `.claude/skills/job-application-assistant/04-job-evaluation.md`
- `.claude/skills/job-application-assistant/01-candidate-profile.md`

Using the framework from `04-job-evaluation.md`, evaluate the job posting against the candidate's profile. If the salary lookup tool is configured, run:

```bash
python salary_lookup.py "<Company Name>" --json
```

If the posting specifies a city, add `--city "<City>"` to narrow results. Parse the JSON output and include the salary benchmark in the evaluation. If the tool is not configured or returns an error, skip the salary benchmark.

Present the evaluation to the user with:

1. **Skills match** - which required/preferred skills match vs. gaps
2. **Experience match** - how work history maps to the role
3. **Behavioral/culture match** - how behavioral profile fits the role/company culture
4. **Salary benchmark** - salary index for the company (if available)
5. **Overall fit score** and recommendation (strong fit / moderate fit / weak fit)

After presenting the evaluation, ask the user:
> "Should I proceed with drafting the CV and cover letter for this role?"

**If the user says no, stop here.** If yes, continue to Step 2.

---

## Step 2: DRAFTER - Draft CV + Cover Letter

You already have `01-candidate-profile.md` and `04-job-evaluation.md` in context from Step 1. **Do not re-read them.**

Read with `view` only the reference files you do not yet have:
- `.claude/skills/job-application-assistant/03-writing-style.md`
- `.claude/skills/job-application-assistant/05-cv-templates.md`
- `.claude/skills/job-application-assistant/06-cover-letter-templates.md`

Also read with `view` the structural references:
- `cv/main_example.md` - the master Markdown CV (role-agnostic source of all competencies)
- Any existing `cv/[0-9][0-9][0-9][0-9][0-9][0-9]_*.md` file as a concrete per-application example (one is enough)
- Any existing `cover_letters/cover_*.md` file as a template reference

### CV (`cv/<YYMMDD>_<company>_<position-slug>.md`)
- Always in **English**
- Follow the Markdown structure (modern-cv Typst template) from `05-cv-templates.md`
- Tailor the profile statement and experience bullets to the specific role
- Reframe skills and achievements to match job requirements
- Keep to 2 pages

### Cover Letter (`cover_letters/cover_<company>_<role>.md`)
- **Match the language of the job posting** (write the cover letter in the posting's language)
- Follow the frontmatter + body structure from `06-cover-letter-templates.md` (the modern-cv `coverletter` template)
- Tailor the opening paragraph to the specific role and company
- Set `addressee:` to a named person if available in the posting, otherwise "hiring team" (or the equivalent in the posting language)
- Body word budget 250-300 words; the letter must fit exactly one page
- Do not write the closing line or signature in the body (the template renders both)
- Any mention of agentic coding or AI tooling must reference **Claude Code** by name

Write both files to disk. Keep the exact text of both drafts in working memory — you will pass them inline to the reviewer in Step 3 and revise them in Step 4 without re-reading.

---

## Step 3: Research (Main Session) + REVIEWER Subagent

The reviewer subagent runs in a **fresh, read-only context**: it can only `glob`, `grep`, `ls`, and `view` files — it has no web access. So do all company research yourself in the main session first (3a), then dispatch the reviewer with the research brief and both drafts **inline in the prompt** (3b).

### 3a. Research the Company (main session)

Use `agentic_fetch` (web search, no URL) and `fetch` (specific URLs) to research:
- The company's website, mission, and recent news
- The specific department or team (if mentioned in the posting)
- Any recent projects, press releases, or strategic initiatives relevant to the role
- Company culture and values

Distill the findings into a concise **research brief**: bullets of verified facts (each with its source URL) plus a closing line on culture/values. Keep it under ~30 lines. Mark anything unverified as unverified; do not present it as fact.

### 3b. Dispatch the Reviewer Subagent

Use the `agent` tool to spawn a reviewer with a fresh context. Pass the research brief and both drafts **inline in the prompt** below (do not make the reviewer view the draft files). Scope the reviewer's file reads to content-critique essentials only — the reviewer does not need the template files (`05`, `06`) to critique content, since those govern document structure the drafter already applied.

Replace `<COMPANY>`, `<ROLE>`, `<INSERT_JOB_POSTING_TEXT_HERE>`, `<INSERT_RESEARCH_BRIEF_HERE>`, `<INSERT_CV_DRAFT_HERE>`, and `<INSERT_COVER_LETTER_DRAFT_HERE>` with actual values before dispatching.

```
You are a hiring manager proxy reviewing a job application. Your job is to make the application as targeted and compelling as possible. You have no web access — the company research is provided inline below; do not attempt to fetch or search anything.

## Your Tasks

### 1. Company Research (provided — use as ground truth)
<RESEARCH_BRIEF>
<INSERT_RESEARCH_BRIEF_HERE>
</RESEARCH_BRIEF>

### 2. Read Reference Materials (content-critique only)
Use `view` to read these four files — and only these — to ground your critique:
- `.claude/skills/job-application-assistant/01-candidate-profile.md`
- `.claude/skills/job-application-assistant/02-behavioral-profile.md` — use this specifically to check whether the cover letter's voice matches the candidate's natural register. A "Collaborator" PI profile, for example, should not be given a combative, solo-hero tone; a "Persuader" profile should not be given over-hedged, apologetic phrasing.
- `.claude/skills/job-application-assistant/03-writing-style.md`
- `.claude/skills/job-application-assistant/04-job-evaluation.md`

Do NOT read `05-cv-templates.md` or `06-cover-letter-templates.md` — those govern document structure the drafter already applied and are not needed for content critique.

### 3. Drafts to Review
Both drafts are provided inline below. Do NOT use the view tool on the draft files — use these exact texts.

<CV_DRAFT file="cv/<YYMMDD>_<COMPANY>_<SLUG>.md">
<INSERT_CV_DRAFT_HERE>
</CV_DRAFT>

<COVER_LETTER_DRAFT file="cover_letters/cover_<COMPANY>_<ROLE>.md">
<INSERT_COVER_LETTER_DRAFT_HERE>
</COVER_LETTER_DRAFT>

### 4. Job Posting
<JOB_POSTING>
<INSERT_JOB_POSTING_TEXT_HERE>
</JOB_POSTING>

### 5. Produce Feedback

Return your feedback in **two parts**:

**Part A — Structured edits (preferred format whenever possible):**
A JSON array of concrete edits the drafter can apply directly without re-reading the files. Each edit is an object:
```json
{
  "file": "cv/<YYMMDD>_<COMPANY>_<SLUG>.md" | "cover_letters/cover_<COMPANY>_<ROLE>.md",
  "old_string": "<exact text currently in the draft>",
  "new_string": "<replacement text>",
  "reason": "<one-line rationale: keyword match / company angle / reframing / style>"
}
```
Only use this format when you can quote the exact `old_string` from the drafts above. Make `old_string` unique — include enough surrounding context so it matches exactly once per file.

**Part B — Narrative suggestions (for judgment calls that are not mechanical edits):**
Prose suggestions grouped by category. Produce each category even if your finding is "no issues" — silence on a category can be mistaken for skipping it.
- **Missed keywords/requirements** — what to add and roughly where, if it cannot be expressed as a clean string replacement
- **Company/department-specific angles** — connections between experience and the company's strategic priorities, based on the research brief above
- **Action-oriented reframing** — identify passive, generic, or low-energy statements and suggest action-oriented rewrites. Use this category especially for structural weakness that doesn't fit a single-sentence swap (e.g., "the whole opening paragraph reads as passive — restructure around your single strongest match to the posting").
- **Tone and style issues** — check against `03-writing-style.md` AND `02-behavioral-profile.md`. Flag any issues with tone, formality, or voice (cliches, hedging, over-humility, inconsistent register), and specifically flag any mismatch between the letter's voice and the candidate's natural register as described in the behavioral profile.

**CRITICAL RULE:** All suggestions must be grounded in actual profile data. Do NOT suggest fabricating skills, experience, or achievements. If a requirement is a gap, say so honestly and suggest how to frame adjacent experience instead.

Do **not** run a verification checklist — the drafter will do that in the final step. Focus on content critique.

Return Part A and Part B together as a single structured message.
```

---

## Step 4: DRAFTER - Revise Based on Feedback

Once the reviewer agent returns its feedback:

1. **Apply Part A (structured edits) directly with the `edit` tool.** Do NOT re-read the draft files — you already have them in context from Step 2, and the reviewer's `old_string` values were quoted from that same text. For each edit in the JSON array, call `edit` with the given `file_path`, `old_string`, and `new_string`. Skip any whose rationale would require fabricating content.
2. **Apply Part B (narrative suggestions)** using judgment. These need interpretation, not mechanical replacement. Walk through every Part B category the reviewer returned and address it:
   - **Missed keywords/requirements:** add the keyword or capability where it fits naturally in the CV or cover letter. Prefer the experience bullets (concrete evidence) over the profile statement (abstract claim).
   - **Company/department-specific angles:** weave the reviewer's research into the cover letter opening or motivation paragraph. Verify every company claim via fetch/agentic_fetch before including it — do not trust reviewer research at face value.
   - **Action-oriented reframing:** rewrite passive or generic phrasing (CV profile statement, cover letter opening, bullet leads). Structural weakness that the reviewer flagged without a clean JSON edit lives here.
   - **Tone and style issues:** apply the writing-style-guide fixes (no em-dashes, no cliches, no apologetic hedging, consistent first-person active voice).
   Use Edit for targeted changes; only re-read a file if an edit fails because the surrounding text has shifted.
3. Do NOT incorporate any suggestion that would fabricate skills or experience. If a posting requirement is a genuine gap, acknowledge it honestly and frame adjacent experience instead.

After all edits are applied, the two files on disk are the final drafts.

---

## Step 5: DRAFTER - Compile & Inspect PDFs (MANDATORY)

**Never skip this step.** The `.md` files looking fine is not sufficient — page-break decisions are unpredictable and commonly produce broken layouts (CV content spilling to a third page, cover letters spilling to page 2 with a clipped signature). Compile both documents and visually verify the PDFs before presenting.

### 5a. Compile

```bash
/scripts/compile-cv.sh cv/<YYMMDD>_<company>_<position-slug>.md
/scripts/compile-cover-letter.sh cover_letters/cover_<company>_<role>.md
```

Both scripts run Pandoc + Typst with the bundled fonts, print the page count, and run ATS text-layer checks (soft hyphens, stray backslashes). A page count other than 2 (CV) / 1 (cover letter), or any ATS warning, is a failure to fix before presenting.

If either compile fails, fix the error and re-compile until clean.

### 5b. Inspect layout

`view` cannot read PDFs directly, so render each PDF's pages to images first: `pdftoppm -png -r 100 <file>.pdf page` (run in the folder containing the PDF). Then inspect every rendered page with `view` and verify:

**CV (`cv/<YYMMDD>_<company>_<position-slug>.pdf`):**
- [ ] Exactly 2 pages (not 1, not 3)
- [ ] No orphaned entry titles — a job/education title line must never sit alone at the bottom of page 1 with its bullets on page 2. (The modern-cv `resume-entry` blocks are sticky, so this usually cannot happen; if a section would start with only one line left on a page, add `#pagebreak(weak: true)` in a raw `typst` block before it.)
- [ ] Section headings are not isolated at the top of page 2 with only 1-2 lines below
- [ ] No awkward whitespace gaps

**Cover letter (`cover_letters/cover_<company>_<role>.pdf`):**
- [ ] Exactly 1 page
- [ ] Signature block visible, not cut off or pushed to a second page
- [ ] Closing line and printed name present (rendered by the template, right-aligned)

### 5c. Iterate until clean

If the layout has problems, edit the `.md` files and recompile. Common fixes (see `05-cv-templates.md` and `06-cover-letter-templates.md` for full details):

- **CV section would start with only one line left on a page:** add `#pagebreak(weak: true)` in a raw `typst` block before that section
- **CV spills to page 3:** there is no page-stretch rescue in Typst (no `\enlargethispage`). Cut content using **relevance-weighted cutting** (see `05-cv-templates.md` → "Relevance-weighted cutting"). Score each candidate line by (a) relevance to THIS posting's keywords and responsibilities, (b) uniqueness (is it duplicated elsewhere?), (c) narrative load (does the cover letter depend on it?). Cut the lowest-total-score line first, regardless of section. Do NOT mechanically apply a static section-based priority order — an older-role bullet that hits posting keywords is worth more than a recent-role bullet that does not.
- **Cover letter spills to 2 pages:** there is no page-stretch rescue in Typst. In order: (1) trim body content with the same relevance-weighted logic — first cut: sentences that restate what a bullet already said, second cut: a bullet that does not hit posting keywords, last resort: a bullet that does; (2) set `par-spacing: 1em` in the frontmatter; (3) cut a bullet or merge two paragraphs.
- **ATS warning from the compile script:** a backslash warning means a frontmatter value (email, company, address) leaked over-escaping — check the value for unusual characters and recompile. A soft-hyphen warning means a hyphenated keyword wrapped at its own hyphen — rephrase slightly, or wrap the word in a raw block as `#no-break[the-word]`.

Do not proceed to Step 6 until both PDFs pass inspection.

### 5d. Build artifacts

The generated Typst intermediate lives in `build/` next to each source (gitignored, regenerable) — leave it in place. Keep the `.md` and `.pdf` files.

---

## Step 6: Present Final Output

Run the full verification checklist from `AGENTS.md` now — this is the **only** verification pass in the workflow. Re-read both files once here to verify final state on disk matches your mental model after the Step 4 and Step 5 edits.

### Verification Checklist
Report pass/fail for each item in the AGENTS.md verification checklist (factual accuracy, targeting, consistency, quality).

### Key Tailoring Decisions
Summarize 3-5 key decisions made to tailor the application:
- What was emphasized and why
- What company-specific angles were incorporated
- What the reviewer suggested that was most impactful
- Any gaps that were acknowledged or reframed

### Files Created
List the files written:
- `cv/<YYMMDD>_<company>_<position-slug>.md` (+ compiled `.pdf`)
- `cover_letters/cover_<company>_<role>.md` (+ compiled `.pdf`)

Tell the user: "Both documents are drafted, compiled, and verified. Open the PDFs to review the final output before submitting."