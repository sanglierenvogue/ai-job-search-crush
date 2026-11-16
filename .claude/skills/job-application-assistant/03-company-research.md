# Company Research

<!-- SETUP: This file is the company research sub-workflow. It is invoked by the
application workflow (Step 1) and can be run standalone via "research <company>". -->

## Purpose

Research a company once and store the findings as a durable document, so that
every application to that company reuses the same verified facts instead of
re-researching. The research feeds the fit evaluation (behavioral/culture
dimension), the CV/cover letter tailoring (company-specific angles), and the
reviewer subagent's critique.

**Output:** `job-applications/<company>/<company>_research_<YYMMDD>.md`,
compiled to the same-named `.pdf`.
- `<company>` is the company name normalized to lowercase hyphenated form
  (e.g. `Example Corp` -> `example-corp`).
- `YYMMDD` is the date the research is done.

## Freshness Gate (6 weeks)

Before researching:

1. `glob job-applications/<company>/<company>_research_*.md`
2. Parse the `YYMMDD` date from each filename. If the most recent file's date
   is **less than 42 days (6 weeks) old**, do NOT research again: read that
   file with `view` and use it as the company knowledge base. Mention to the
   user that the research is N days old and can be refreshed with
   "refresh research for <company>".
3. If no file exists, the most recent is older than 42 days, or its date does
   not parse, run the research below and write a new file. (Refreshing an old
   research creates a new dated file; the old one is left in place.)

## Research Procedure

Use `agentic_fetch` (web search, no URL) and `fetch` (specific URLs). Verify
every fact against a real source; anything you cannot verify must be marked
`[unverified]` and never presented as fact.

1. **Company website:** overview, products/services, mission statement,
   values/culture pages, leadership team.
2. **LinkedIn company page:** employee count (current), headline, recent
   hiring activity, company size trajectory.
3. **Facts:** industry, main competitors, global presence (HQ, countries,
   key offices), number of employees, annual revenue (latest reported),
   founding year, ownership (public/private/funded), notable recent
   acquisitions or divestitures.
4. **Recent news (~6 months):** press releases, media coverage, strategic
   initiatives, product launches, funding, restructuring, expansion. For
   each item: date, one-line summary, source URL.
5. **Culture signal:** tone of the website/careers page, DEI or community
   programs, notable leadership statements. Keep this factual and brief.

Prefer primary sources (company website, filings) over aggregators for
mission, values, and numbers.

## Output Document Structure

````markdown
# Company Research: <Company Name>

**Researched:** YYYY-MM-DD
**Sources:** [primary source URLs used]

## Summary

2-4 sentences: what the company does, scale, and current strategic
direction.

## Mission & Values

- **Mission:** [short quote or paraphrase + source]
- **Values:** [bullet list, paraphrased + source]

## Facts

| Item | Value | Source |
|------|-------|--------|
| Industry | ... | ... |
| Main competitors | ... | ... |
| HQ / global presence | ... | ... |
| Employees | ... | ... |
| Annual revenue | ... | ... |
| Founded | ... | ... |
| Ownership | ... | ... |

## Recent News

- **<YYYY-MM-DD> - <headline>:** one-line summary. (<source URL>)
- **<YYYY-MM-DD> - <headline>:** one-line summary. (<source URL>)

## Culture & Network Notes

- Culture observations relevant to the behavioral fit assessment.
- [ ] Network contacts identified who may know the team/manager.
````

## Compile

```bash
.scripts/compile-report.sh job-applications/<company>/<company>_research_<YYMMDD>.md
```

Expected output: `pdf: ... (<company>_research_<YYMMDD>.pdf (N pages))`.
A multi-page PDF is normal for this document.

## Rules

1. **Never fabricate facts.** Every claim needs a source URL; unverifiable
   claims are marked `[unverified]`.
2. **Keep it current.** The document is trusted for 6 weeks only; the
   freshness gate above is the only thing that decides when to re-research.
3. **Keep news summaries short.** One line per item; link, do not quote.
4. **No company-specific opinions** (e.g. "great place to work") unless
   sourced; the research feeds fit scoring and cover letter angles.
