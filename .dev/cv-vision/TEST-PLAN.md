# TEST PLAN: Vision analysis of rendered CV pages

Goal: prove the configured vision model (default `qwen3.8-27b`) accepts
rendered CV PNGs through the OpenAI-compatible chat-completions gateway
and returns a useful layout/content analysis, using a **direct API call**.
The in-agent call path cannot send images to this model (its model
catalog entry declares no image input), so the gateway is queried
directly via `.scripts/analyze-vision.py` (the script's `--kind` default,
`cv`, is used throughout this plan).

## Background

The `.dev/cv-typst` parity workflow currently verifies rendered CVs
only programmatically (text layer, page count, fonts, color streams)
because image input through the agent is rejected for this model.
This plan tests the gateway API directly. If it passes, the rendered
PNGs can be checked by a real vision pass, and the "no vision model in
this environment" note in `.dev/cv-typst/TEST-PLAN.md` is superseded.

## Prerequisites

1. `.env` at the repo root (copy from `.env.example`, fill in from your
   provider console):
   ```bash
   cp .env.example .env   # then set LLM_API_KEY (and LLM_BASE_URL if
                          # the gateway is not the OpenAI default)
   ```
2. Python 3.10+ (script is stdlib-only; no packages to install).
3. Fixtures: the rendered sample CV pages
   `.dev/cv-typst/samples/typst-1.png` and `typst-2.png`. If missing,
   regenerate them (gitignored, regenerable):
   ```bash
   .scripts/compile-cv.sh .dev/cv-typst/samples/sample_typst.md \
       .dev/cv-typst/samples/sample_typst.pdf
   .scripts/render-pdf.sh .dev/cv-typst/samples/sample_typst.pdf \
       .dev/cv-typst/samples/typst
   ```

## Steps

Run from the repo root.

1. **Secrets hygiene.**
   - `git check-ignore .env` must print the path (it is ignored).
   - `git status --porcelain` shows no secret file as untracked/new.
   - Neutrality check: committed files must not name the gateway's
     provider. Using the host from the untracked `.env`:
     ```bash
     git grep -in "$(echo "${LLM_BASE_URL:-$(grep '^LLM_BASE_URL=' .env | cut -d= -f2-)}" | sed 's#https\?://##; s#/.*##')" || echo "clean"
     ```
     Expect `clean`.

2. **Text-only smoke test** (validates key, base URL, and model id
   before spending on image tokens):
   ```bash
   .scripts/analyze-vision.py
   ```
   Expect exit 0 and the single word `ok`. Any HTTP error here is an
   auth/endpoint/model-id problem, not a vision problem.

3. **Single-page vision test.**
   ```bash
   .scripts/analyze-vision.py .dev/cv-typst/samples/typst-1.png
   ```
   Expect exit 0 and an answer that names **Alex Carter**, both
   position titles (Data Scientist, Machine Learning Engineer), the
   contact details, and the page-1 section headings in order.

4. **Two-page single-request test** (both pages, one call).
   ```bash
   .scripts/analyze-vision.py \
       .dev/cv-typst/samples/typst-1.png .dev/cv-typst/samples/typst-2.png
   ```
   Expect exit 0 and content from **both** pages, including page-2
   items such as the References section and "Available upon request."

5. **Failure modes.**
   - Missing file: `.scripts/analyze-vision.py no-such.png` → exit 66.
   - No key: temporarily move `.env` aside, unset `LLM_API_KEY` → exit 69.
   - Bad key: set a wrong `LLM_API_KEY` (env var overrides `.env`) →
     exit 75 with the gateway's error body, and the wrong key must not
     appear anywhere in the output.

6. **Manual cURL cross-check** (one page; confirms the failure, if
   any, is not specific to the script). Write the JSON body to a file
   first: an inline `-d` payload with the base64 image fails with
   "Argument list too long" (E2BIG) on some systems:
   ```bash
   python3 - <<'EOF'
   import base64, json
   env = {}
   for line in open(".env"):
       line = line.strip()
       if line and not line.startswith("#") and "=" in line:
           k, _, v = line.partition("=")
           env[k.strip()] = v.strip().strip('"').strip("'")
   b64 = base64.b64encode(open(".dev/cv-typst/samples/typst-1.png", "rb").read()).decode()
   body = {
       "model": env.get("LLM_MODEL") or "qwen3.8-27b",
       "max_tokens": 2048,
       "reasoning_effort": "none",
       "messages": [{"role": "user", "content": [
           {"type": "text", "text": "What is the candidate name on this CV?"},
           {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}", "detail": "high"}}]}],
   }
   json.dump(body, open("/tmp/body.json", "w"))
   EOF
   ( set -a; . ./.env; set +a
     curl -sS --max-time 180 -X POST "${LLM_BASE_URL}/chat/completions" \
       -H "Authorization: Bearer ${LLM_API_KEY}" \
       -H "Content-Type: application/json" \
       --data-binary @/tmp/body.json )
   ```
   Expect a 200 JSON response naming Alex Carter, with
   `usage.completion_tokens_details.reasoning_tokens == 0` and a
   non-zero `usage.prompt_tokens_details.multimodal_tokens.image`
   (proof the image was actually ingested).

## Checklist

| # | Check | How |
|---|---|---|
| 1 | `.env` is gitignored, no secret file tracked | `git check-ignore .env`; `git status` |
| 2 | Committed files stay provider-neutral | neutrality grep in step 1 |
| 3 | Auth + endpoint + model id work (text-only) | step 2, exit 0 |
| 4 | Gateway accepts `image_url` base64 input on this model | step 3, exit 0 with a real answer |
| 5 | Analysis names correct header content (name, positions, contact) | step 3 output |
| 6 | Multi-image request: page-2 content present | step 4 output |
| 7 | Error paths clean: 64/66/69/75 as specified, key never echoed | step 5 |
| 8 | cURL cross-check matches script behavior | step 6 |

## Manual CV analysis prompt (for ad-hoc runs)

```bash
.scripts/analyze-vision.py cv/<YYMMDD>_<company>_<position-slug>.pdf-page-1.png \
    --prompt "This is page 1 of a CV. List every rendering defect: \
clipped or overlapping text, missing glyphs, orphaned headings, misaligned \
columns. Say 'none found' if the page is clean."
```

(Run `.scripts/render-pdf.sh` on the CV PDF first to produce the page PNGs.)

## Iterate

- Step 2 fails with 401/403 → wrong `LLM_API_KEY`; with 404 → wrong
  `LLM_BASE_URL` or model id.
- Step 3/4 fails with 400 mentioning `image` / `modality` / `content` →
  the gateway's deployment of this model rejects vision input after all;
  record the exact error body in the iteration log and stop (the
  programmatic comparison in `.dev/cv-typst` remains the verification
  path).
- The answer reads text wrong → try `--detail high` (the default) and a
  higher-DPI render (`.scripts/render-pdf.sh <pdf> <prefix> 200`).
- Answer is truncated → raise `--max-tokens`.

## Iteration log

1. **Run 1 (initial).** Script, `.env.example`, and gitignore rules
   committed; all non-network paths verified locally (syntax, exit
   codes 64/66/69/75, dotenv precedence, gitignore, neutrality).
2. **Run 2 (live, all steps pass).**
   - Step 1: `.env` ignored, only `.env.example` tracked, neutrality
     grep clean.
   - Step 2: text-only smoke → `ok`, exit 0 (19 in / 2 out tokens).
   - Step 3: page 1 → exit 0; name, both position titles, all contact
     details, all five page-1 sections in order, full entry anatomy
     correct (1105 in / 755 out tokens). Flagged the GitHub contact
     icon as a possible missing glyph — matches the accepted
     modern-cv contact-item design difference documented in
     `.dev/cv-typst/TEST-PLAN.md`.
   - Step 4: two pages, one call → exit 0; page-2 content present
     (Publications, Honors and Awards, References; 2069 in / 675 out).
     Noted the sparse bottom of page 2 (expected for this sample).
   - Step 5: bad key → HTTP 403 "insufficient permissions", exit 75,
     zero occurrences of the key in output. 64/66/69 verified in Run 1.
   - Step 6: cURL cross-check → HTTP 200, correct name,
     `reasoning_tokens: 0`, `multimodal_tokens.image: 962`. The
     original inline `-d` variant failed with E2BIG on this machine;
     the step now uses the body-file approach.
   - **Known minor weakness (not a failure):** in Run 2's single-page
     pass the 2019-2021 employer was misread as "PHARMASIGHT"
     (source and PDF text layer both say "PharmaInsight"); the
     two-page pass read it correctly. Single-letter OCR slips on small
     uppercase text are possible; verify any fact the model reports
     against the Markdown source before acting on it.
