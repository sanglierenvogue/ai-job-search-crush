# CV Templates and Tailoring Guide

<!-- SETUP: Profile statements and section ordering are personalized by running project:setup -->

## Template: Markdown + Pandoc + Typst (modern-cv)

All CVs are written in **Markdown**, converted by **Pandoc**, and typeset by
**Typst** with the [modern-cv](https://typst.app/universe/package/modern-cv)
package (an Awesome-CV port, blue accent). This replaces the former
LaTeX/moderncv (banking style) + lualatex pipeline.

**Output files:** `cv/<YYMMDD>_<company>_<position-slug>.md` ->
`cv/<YYMMDD>_<company>_<position-slug>.pdf`
- `YYMMDD` is the date the CV is drafted.
- The position slug is the role title lowercased and hyphenated
  (e.g. `250714_braun_applied-data-scientist`).
- `cv/main_example.md` is the only CV exempt from the scheme.

**Compile with:** `.scripts/compile-cv.sh` (Pandoc -> Typst, bundled fonts).
**Master reference:** `cv/main_example.md` (comprehensive CV with all
competencies, experience, and achievements - use as source when building
targeted CVs).
**Template assets:** `md-typst-templates/` (see its README for the mapping
table, package provenance, and gotchas).

### Compile command

```bash
.scripts/compile-cv.sh cv/<YYMMDD>_<company>_<position-slug>.md
```

Expected output: `pdf: cv/<...>.pdf (2 pages)`. Any page count other than 2
is a failure that must be fixed before presenting to the user.

## Document Structure

Each CV is a single Markdown file with YAML frontmatter plus body sections.
The frontmatter feeds the modern-cv header; the body is the CV content.

````markdown
---
firstname: [FIRST_NAME]
lastname: [LAST_NAME]
address: [Your Address, City, Country]
phone: [+XX XXXXXXXXXX]
email: [your.email@example.com]
linkedin: [your-profile-path]
github: [your-username]
positions:
  - [Primary Role Title]
  - [Secondary Role Title]
---

```{=typst}
#resume-item[
[3-5 line profile statement tailored to the role]
]
```

# Core Competencies

```{=typst}
#resume-skill-item("[Skill Category 1]", ("[Tool]", "[Framework]", strong("[Key differentiator]")))
```

# Professional Experience

```{=typst}
#resume-entry(title: "[Job Title]", location: "[City, Country]", date: "[YYYY] - Present", description: "[Company]")
#resume-item[
  - [Achievement - specific, use numbers where possible]
  - [Achievement 2]
]
```

# Education

```{=typst}
#resume-entry(title: "[Degree] in [Field]", location: "[City, Country]", date: "[YYYY] - [YYYY]", description: "[Institution]")
#resume-item[
  Thesis: "[Thesis Title]. [Brief description.]"
]
```

# Languages

- [Language 1] (native), [Language 2] (fluent).

# Publications

- [Author(s)] ([Year]). [Title]. [Journal]. [DOI](https://doi.org/[DOI])

# Honors and Awards

- **[Award Name]** - [Event/Organization] ([Year]).

# References

- Available upon request.
````

### How the mapping works

| CV element | In the Markdown |
|---|---|
| Name, address, phone, email, LinkedIn, GitHub, headline titles | YAML frontmatter |
| Profile statement | first raw `typst` block: `#resume-item[ ... ]` |
| Section headings | `# Section name` |
| Experience / Education entries | one raw `typst` block per entry: `#resume-entry(...)` + `#resume-item[ - ... ]` |
| Core Competencies | raw `typst` blocks: `#resume-skill-item("Category", ("a", "b"))` |
| Languages, Publications, Awards, References | plain Markdown lists |

Frontmatter value rules (the package prefixes URLs itself):
- `linkedin`: profile path only, e.g. `jane-doe` (not the full URL).
- `github`: username only, e.g. `janedoe`.
- `positions`: headline role titles, joined with dots in the header.

### Entry layout

Each job or education entry is a `resume-entry` (title on the left, location
on the right, date under the location, description/company under the title)
followed by a `resume-item` bullet list. Write the whole entry - header plus
bullets - inside a single raw `typst` block (fenced with ```` ```{=typst} ````
- a plain ` ```typ ` fence would be rendered as displayed code) so it renders
as one sticky unit.

## Section-by-Section Tailoring

### Profile Statement / Elevator Pitch (Best Practice)
This is the most important section to customize. It appears right after the
header block.

Write 5-7 lines that function as an "elevator pitch": a concise, compelling
introduction explaining why you're qualified for *this specific role*. Focus
on what the employer gains from hiring you.

**Create 2-3 profile statement templates for your main role types:**

<!-- SETUP: These are populated based on your background -->
**For [YOUR_PRIMARY_ROLE_TYPE] roles:**
> [YOUR_PROFILE_STATEMENT_TEMPLATE_1]

**For [YOUR_SECONDARY_ROLE_TYPE] roles:**
> [YOUR_PROFILE_STATEMENT_TEMPLATE_2]

### Core Competencies / Skills Section (Best Practice)
Reorder and emphasize based on the role. Use `resume-skill-item` rows: a bold
category label on the left, the skills on the right.

List **5-7 key competencies**, tailored to the specific job. Emphasize a key
differentiator in each row with `strong("...")`.

### Education
- Always include your highest degrees
- For senior roles, keep education brief (dates and titles only)
- Include thesis topics when relevant to the target role

### Professional Experience
- Rewrite bullet points to emphasize aspects most relevant to the target role
- Use 4-6 bullets for most recent role, 3-4 for previous, 2-3 for older
- **Emphasize measurable results** where possible: "Reduced processing time by X%", "Model adopted by the team"

### Handling Employment Gaps (Best Practice)
If there is a gap in your employment history:
- The gap should be explained matter-of-factly if needed
- Describe how professional development continued during the gap
- Frame as deliberate skill-building and career repositioning

### Publications
- Include Google Scholar link if applicable
- Select 3-4 most relevant publications (not always all of them)
- For non-academic roles, keep brief

### Honors and Awards
- Keep format brief, one line each

### References
- List 2-4 references with name, title, company, and contact
- End with: "More references are available upon request."
- **Do not attach reference letters** - employers typically contact references directly

## Compile-and-Inspect Loop (MANDATORY)

After writing the CV and before presenting to the user, always compile and
visually inspect the PDF. Iterate until the layout is clean. Workflow:

1. Run `.scripts/compile-cv.sh cv/<YYMMDD>_<company>_<position-slug>.md`
2. Check the output page count: must be exactly 2
3. Render the pages: `.scripts/render-pdf.sh cv/<YYMMDD>_<company>_<position-slug>.pdf`
4. View every produced PNG and check for layout problems (orphaned entries,
   cramped spacing, content spill)

### Page-break behavior in Typst (differs from LaTeX)

- **No orphaned entries or headings.** `resume-entry` blocks and level-1
  section headings are `sticky` in the modern-cv package, so an entry title
  or section heading can never sit alone at the bottom of a page with its
  bullets on the next page. There is no `\needspace` equivalent to add.
- **No page-stretch rescue.** Typst has no `\enlargethispage`. If a few lines
  spill onto a third page, you must cut content (see Relevance-weighted
  cutting) or tighten spacing inside a raw block. Do not shrink fonts or
  margins to force-fit.
- **Forcing a section to the next page.** If a section would start with only
  one line left on a page, add `#pagebreak(weak: true)` before the heading in
  the Markdown. A weak break only takes effect where a page break is already
  happening, so it cannot create a mostly-empty page on its own.

## Page Budget - Hard 2-Page Limit

The CV **must** fit on exactly 2 pages when compiled. Use these content limits
as a guide:

| Section | Max budget |
|---------|-----------|
| Profile statement | 3-4 lines |
| Skills | 5 items, each 1-2 lines |
| Most recent role | 4-5 bullets |
| Previous role | 2-3 bullets |
| Older roles | 2 bullets (1 line each) |
| Education | 2-3 entries |
| Publications | 2-3 entries |
| Awards | 3 entries, single line each |
| References | "Available upon request." (single line) |

**If in doubt, cut rather than squeeze.** Reducing spacing or margins to
force-fit content makes the CV look cramped.

## Relevance-weighted cutting (the right way to shrink a CV)

**Cut by signal, not by section.** Static priority lists ("remove oldest
education first, then shorten the earliest role...") are wrong when a relevant
"lower-priority" item is competing with an irrelevant "higher-priority" item.
An older-role bullet that speaks directly to the posting is worth more than a
recent-role bullet that does not.

For every candidate line, score three things:

1. **Relevance to THIS posting** - does the line hit a named tool, keyword, or
   stated responsibility in the job ad?
2. **Uniqueness** - is it the only place this claim appears, or is it
   duplicated elsewhere in the CV?
3. **Narrative load** - does the cover letter depend on it? If cutting the
   line would force you to rewrite a cover-letter paragraph, it is
   load-bearing.

Cut the lowest-total-score line first, regardless of which section it sits in.

### Practical order of cuts (easiest - last resort)

1. **Redundancy.** If an achievement appears in both Core Competencies AND a
   role bullet, the Core Competencies version is usually the cleaner cut (the
   experience bullet is more concrete evidence).
2. **Profile-statement fluff.** A sentence that just restates what
   Publications or Skills will show. ("Peer-reviewed publications on X..." is
   already a Publications entry - profile can claim it once and stop.)
3. **Low-relevance experience bullets.** A bullet about work that does not
   touch posting keywords, wherever it sits. This cuts across sections before
   touching the structural list.
4. **Low-relevance supporting content.** An older-role bullet that does not
   speak to the target role. A certification that does not touch the posting's
   stack. A language entry that can be condensed to one line.
5. **Low-relevance publications.** Keep 1-2 publications that best match the
   posting. Cut the rest before touching experience bullets.
6. **Last-resort structural cuts.** Oldest education entry, tightening an
   older role to 2 bullets, collapsing Certifications into a single line.
   These only happen if the relevance-weighted cuts above have already been
   exhausted.

### Pitfalls to avoid

- Do not mechanically cut from the bottom of a static section list without
  checking relevance. "Cut the oldest role first" is wrong if that role is
  literally about the skill the posting asks for.
- Do not cut the one concrete example the cover letter leans on. Relevance is
  measured against the cover letter you wrote, not just the job posting -
  interviewers will have read both.
- Do not cut to fit if the fit is borderline. Because Typst has no
  page-stretch rescue, a near-miss (a few lines onto page 3) is resolved by
  cutting the single lowest-score line, not by squeezing spacing.

## Recommended Section Order

The section order varies by role type:

**For technical / data science / ML roles:**
1. Profile statement / elevator pitch
2. Core competencies / Skills
3. Professional Experience (reverse chronological)
4. Education (reverse chronological)
5. Languages
6. Publications & Awards
7. References

**For domain-specific / specialist roles:**
1. Profile statement / elevator pitch
2. Core competencies / Skills
3. Education (reverse chronological) - credentials are a key qualifier
4. Professional Experience (reverse chronological)
5. Publications & Awards
6. References
