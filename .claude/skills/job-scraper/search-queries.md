# Search Queries for Job Scraper

<!-- SETUP: Customize these queries based on your skills, target roles, and location -->

## Search Sites

Primary (your local job market - fill in with your main job boards):
- **[YOUR_LOCAL_JOB_BOARD_1]** - your primary local job board
- **linkedin.com/jobs** - LinkedIn job listings (filter: your country / your city)
- **[YOUR_LOCAL_JOB_BOARD_2]** - another job board in your market

Secondary (company career pages via Google):
- Direct Google searches with `site:` filters for known target companies

Tip: for any local job board you search often, run `project:add-portal` to generate a CLI skill for it.

## Query Categories

Queries are grouped by priority. Each query should be combined with your location terms (e.g. `[YOUR_CITY]`, `[YOUR_REGION]`) where the site supports it.

### Priority 1: [YOUR_PRIMARY_ROLE_TYPE]

These match your strongest and most desired career direction.

```
site:[YOUR_LOCAL_JOB_BOARD_1] "[YOUR_PRIMARY_JOB_TITLE]" [YOUR_CITY]
site:[YOUR_LOCAL_JOB_BOARD_1] "[YOUR_KEY_SKILL]" [YOUR_CITY]
site:linkedin.com/jobs "[YOUR_PRIMARY_JOB_TITLE]" [YOUR_COUNTRY]
```

### Priority 2: [YOUR_DOMAIN_EXPERTISE]

These match your domain expertise.

```
site:[YOUR_LOCAL_JOB_BOARD_1] [YOUR_DOMAIN_KEYWORD_1] [YOUR_CITY] OR [YOUR_REGION]
site:[YOUR_LOCAL_JOB_BOARD_1] [YOUR_DOMAIN_KEYWORD_2] [YOUR_COUNTRY]
site:linkedin.com/jobs [YOUR_DOMAIN_KEYWORD_1] [YOUR_CITY] [YOUR_COUNTRY]
```

### Priority 3: [YOUR_ADJACENT_ROLE_TYPE]

Adjacent roles you could pivot into.

```
site:[YOUR_LOCAL_JOB_BOARD_1] "[YOUR_ADJACENT_TITLE_1]" [YOUR_KEY_SKILL] [YOUR_CITY]
site:[YOUR_LOCAL_JOB_BOARD_1] "[YOUR_ADJACENT_TITLE_2]" [YOUR_KEY_SKILL] [YOUR_CITY]
```

### Priority 4: Broader Technical / Consulting

Wider net for general technical roles.

```
site:[YOUR_LOCAL_JOB_BOARD_1] [YOUR_KEY_SKILL] developer [YOUR_CITY]
site:linkedin.com/jobs "[YOUR_KEY_SKILL] developer" [YOUR_CITY]
site:[YOUR_LOCAL_JOB_BOARD_1] "technical consultant" [YOUR_DOMAIN] [YOUR_CITY]
```

## Location Filter

When evaluating results, verify the job location is within reasonable commute distance from your home. Define acceptable areas:
- [YOUR_CITY] and surrounding areas
- [ACCEPTABLE_AREA_1]
- [ACCEPTABLE_AREA_2]
- [BORDERLINE_AREA] (borderline - ~X min by transit)
- [TOO_FAR_AREA] (too far)

## Date Filter

Only include jobs posted within the last 14 days, or with an application deadline that has not yet passed. If a posting date cannot be determined, include it but flag as "date unknown".

## Adapting Queries

If the user specifies a focus area, select queries from the matching category and also generate 2-3 custom queries for that focus. For example:
- "project:job-scraper [focus_area]" -> relevant category queries + custom focus-specific queries
