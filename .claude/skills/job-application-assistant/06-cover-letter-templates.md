# Cover Letter Templates and Tailoring Guide

## Template: Markdown + Pandoc + Typst (modern-cv coverletter)

All cover letters are written in **Markdown**, converted by **Pandoc**, and
typeset by **Typst** with the [modern-cv](https://typst.app/universe/package/modern-cv)
package (`coverletter` template - the same package and bundled fonts as the
CV). This replaces the former LaTeX/`cover.cls` (Lato/Raleway) + xelatex
pipeline. No LaTeX is needed.

**Output files:** `cover_letters/cover_<company>_<role>.md` ->
`cover_letters/cover_<company>_<role>.pdf`
**Compile with:** `.scripts/compile-cover-letter.sh` (Pandoc -> Typst, bundled fonts).
**Template assets:** `md-typst-templates/` (`cover.typ`, `cover-template.md`).

### Compile command

```bash
.scripts/compile-cover-letter.sh cover_letters/cover_<company>_<role>.md
```

Expected output: `pdf: cover_letters/cover_<company>_<role>.pdf (1 pages)`.
Any page count other than 1 is a failure that must be fixed before presenting
to the user.

## Compile-and-Inspect Loop (MANDATORY)

After writing the cover letter and before presenting to the user, always
compile and visually inspect the PDF. Iterate until the layout is clean:

1. Run `.scripts/compile-cover-letter.sh cover_letters/cover_<company>_<role>.md`
2. Confirm page count is exactly 1 and the compile printed no warnings
3. Read the PDF via the Read tool (or render with `.scripts/render-pdf.sh` and
   inspect the PNGs) and visually check: the signature block fits at the
   bottom, nothing is cut off, no overlapping blocks

## Document Structure

Each letter is a single Markdown file. The YAML frontmatter feeds the
modern-cv header, the company block, and the letter heading; the body is the
letter text (plain paragraphs and Markdown lists). The closing line and the
printed name are rendered by the template - do **not** write them in the body.

````markdown
---
firstname: [FIRST_NAME]
lastname: [LAST_NAME]
address: Your Address, City, Country
phone: [+XX XXXXXXXXXX]
email: [your.email@example.com]
linkedin: [your-profile-path]
github: [your-username]
positions:
  - [Primary Role Title]
  - [Secondary Role Title]
company: [Company Name]
target: [Hiring contact or team, e.g. "Jane Smith, Head of Data" or "Hiring Team"]
company-street: [Street and number]
company-city: [Postal Code, City]
addressee: [Name or "hiring team"]
job-position: [Role Title]
---

[Opening paragraph - the role, the connection to your background, 2-3 sentences.]

[Body paragraph - your most relevant experience, then a bullet list:]

- [Concrete achievement/skill 1 - be specific, use numbers where possible]
- [Concrete achievement/skill 2]
- [Concrete achievement/skill 3]

[Connection to company - why this role, why this company specifically.]

[Personal fit paragraph - behavioral strengths, team contribution, 2-3 sentences.]

I look forward to hearing from you.
````

### How the mapping works

| Letter element | In the Markdown |
|---|---|
| Name, address, phone, email, LinkedIn, GitHub, headline titles | YAML frontmatter (the modern-cv header) |
| Company block (attention line, date, name, street, city) | `company`, `target`, `company-street`, `company-city` |
| "Job Application for [role]" line + salutation | `job-position`, `addressee` (plus optional `dear`) |
| Body paragraphs and bullets | plain Markdown (paragraphs, `-` lists) |
| Closing line + printed name | rendered by the template (localized "Sincerely," + bold name, right-aligned); override the closing with `signature-line` |
| "Attached: Curriculum Vitae" | rendered by the template (package default) |

Frontmatter value rules:
- `positions`: required by the package - always include it (the headline role titles).
- `linkedin`: profile path only, e.g. `jane-doe` (not the full URL); `github`: username only.
- `company-street` / `company-city`: optional (the block renders without them).
- `accent-color` (e.g. `#3873B3`, the stock default), `paper-size` (default `us-letter`;
  use the **Paper size** value from the Document Preferences section of `AGENTS.md`),
  `par-spacing` (e.g. `1em` to tighten), `language` (default `en`), `dear`,
  `signature-line`: optional overrides.

### If the letter overflows one page

Typst has no `\enlargethispage`: there is no page-stretch rescue. In order:
1. trim body content (relevance-weighted, as for the CV),
2. set `par-spacing: 1em` in the frontmatter,
3. cut a bullet or merge two paragraphs.

### Non-English letters

Same structure, write the body in the posting's language. The package
localizes salutation/closing for en, de, gr, pt, sp, fr, ru, zh, it, nl via
the `language` key. For a language the package does not localize:

- `dear: <local salutation>` - the template appends a comma.
- `signature-line: <local closing line, comma included>`.
- `language: <locale>` for correct text language data.

## Tailoring Guidelines

### Salutation
- If you know the hiring manager's name: `addressee: Jane Smith` -> "Dear Jane Smith,"
- If you know the team: `addressee: the Astra Biotech data team`
- Generic: `addressee: hiring team` (avoid "To whom it may concern")

### Length - Hard 1-Page Limit
- Target: 1 page including the signature block
- Maximum: **never exceed 1 page**
- **Word budget: 250-300 words** of body text. This is the safe maximum.
- **Always count**: opening paragraph + bullet list paragraph + closing
  paragraph = 3 blocks. Add a 4th only if the others are short.
- When adding company-specific content, trim other content to compensate
  rather than adding net length

### Bullet Lists
- Plain Markdown `-` lists in the body (3-5 bullets is ideal)
- Start each bullet with a bold label or action verb (`**Label:** ...`)
- Bullets render in the same font/size as the body - no special handling

### Writing rules (from 03-writing-style.md)
- No em-dashes (use commas or periods instead)
- No cliches or empty filler
- Every claim backed by a specific example
- Forward-looking framing: focus on tasks you'll solve, not just past duties

## Checklist Before Finalizing
- [ ] No em-dashes (use commas or periods instead)
- [ ] No cliches or empty filler
- [ ] Every claim backed by specific example
- [ ] Forward-looking framing: focuses on tasks you'll solve, not just past duties
- [ ] Motivation section references this specific company's mission/values
- [ ] Company name and role are correct throughout
- [ ] Date is current (the template renders today's date automatically)
- [ ] Fits on one page (compile output says `(1 pages)`)
- [ ] Language matches the job posting language
- [ ] Salutation is appropriate (named person if possible)
- [ ] No syntax errors (clean compile, zero warnings)
- [ ] ATS text layer clean (script prints no soft-hyphen/backslash warnings)

## Submission Guidelines (Best Practice)
- Submit only the documents the employer requests
- Export as PDF to preserve formatting
- Name files clearly: "[Your Name] CV" and "[Your Name] Cover Letter"
- Follow all employer instructions regarding anonymity or specific materials
