# Markdown + Pandoc + Typst Templates

Stock CV and cover-letter template assets for the application workflow. CVs and cover letters are written in
Markdown, converted by Pandoc, and typeset by Typst using the
[modern-cv](https://typst.app/universe/package/modern-cv) package (an
Awesome-CV port). This replaces the former LaTeX/moderncv (banking style)
CV pipeline and the former LaTeX/`cover.cls` cover letter pipeline: the
whole application workflow runs on Pandoc + Typst, no LaTeX needed.

## Layout

```
md-typst-templates/
├── README.md              # this file
├── cv.typ                 # Pandoc template for CVs: imports modern-cv, maps
│                          #   frontmatter -> resume header, emits the body
├── cover.typ              # Pandoc template for cover letters: imports
│                          #   modern-cv, maps frontmatter -> coverletter /
│                          #   hiring-entity-info / letter-heading, emits body
├── pandoc.typ             # reference dump of Pandoc's stock Typst template
│                          #   (shows the template-variable syntax)
├── template.md            # profile-agnostic Markdown CV skeleton
│                          #   ([PLACEHOLDER] tokens, safe to commit)
├── cover-template.md      # profile-agnostic Markdown cover letter skeleton
├── fonts/                 # bundled fonts (see below)
├── modern-cv/0.10.0/      # vendored package source (pinned, for offline use)
│   ├── lib.typ            #   the template: resume, resume-entry, resume-item,
│   │                      #   resume-skill-item, ...
│   └── template/          #   the package's own example templates (reference)
├── fontawesome/0.6.0/     # vendored transitive dependency (icons)
└── linguify/0.5.0/        # vendored transitive dependency (localized strings)
```

The Markdown master reference (the role-agnostic source of all competencies,
the equivalent of the old `cv/main_example.tex`) lives at `cv/main_example.md`.

## Compile chain

```
cv/<YYMMDD>_<company>_<position-slug>.md
        |  pandoc --template=md-typst-templates/cv.typ
        v
cv/build/<YYMMDD>_<company>_<position-slug>.typ
        |  typst compile --font-path md-typst-templates/fonts
        v
cv/<YYMMDD>_<company>_<position-slug>.pdf
```

Cover letters follow the same chain with `cover.typ`:

```
cover_letters/cover_<company>_<role>.md
        |  pandoc --template=md-typst-templates/cover.typ
        v
cover_letters/build/cover_<company>_<role>.typ
        |  typst compile --font-path md-typst-templates/fonts
        v
cover_letters/cover_<company>_<role>.pdf
```

Use `.scripts/compile-cv.sh <cv.md>` and
`.scripts/compile-cover-letter.sh <letter.md>` (see `.scripts/README.md`)
instead of running the two commands by hand. Both scripts undo Pandoc's
over-escaping of frontmatter values and run ATS text-layer checks
(soft hyphens, stray backslashes).

**Output naming.** `YYMMDD` is the date the CV is drafted; the position slug
is the role title lowercased and hyphenated (e.g.
`250714_braun_applied-data-scientist.md`). `cv/main_example.md` is the only
CV exempt from the scheme.

## How the Markdown maps to the Typst template

| CV element | In the Markdown | In the output |
|---|---|---|
| Name, address, phone, email, LinkedIn, GitHub, headline titles | YAML frontmatter (`firstname`, `lastname`, `address`, `phone`, `email`, `linkedin`, `github`, `positions`, ...) | `cv.typ` builds the `resume(author: ...)` header from them |
| Profile statement | first raw `typst` block: `#resume-item[ ... ]` | CV body lead paragraph |
| Section headings | `# Section name` | modern-cv level-1 headings (accent color, underline rule) |
| Experience / Education entries | one raw `typst` block per entry: `#resume-entry(...)` + `#resume-item[ - ... ]` | sticky entry blocks (title cannot orphan from bullets) |
| Core Competencies | raw `typst` blocks: `#resume-skill-item("Category", ("a", "b"))` | two-column category/value rows |
| Languages, Publications, Awards, References | plain Markdown lists | default Typst lists under the section heading |

Notes on the frontmatter values (the package prefixes URLs itself):
- `linkedin`: the profile path only, e.g. `jane-doe` (renders as a link to
  `https://www.linkedin.com/in/jane-doe`, displayed as the author's name).
- `github`: the username only, e.g. `janedoe`.
- `positions`: headline role titles, joined with dots in the header.

## Package provenance and pinning

- `modern-cv` 0.10.0: source of the [Typst universe package]
  (https://typst.app/universe/package/modern-cv), pinned to the release
  commit `a2d6b17` of https://github.com/ptsouchlos/modern-cv. MIT license.
- `fontawesome` 0.6.0 and `linguify` 0.5.0: transitive dependencies, source
  from https://github.com/typst/packages (`packages/preview/...`). MIT.
- The compiled import is `@preview/modern-cv:0.10.0`. Typst resolves it from
  its package registry on first use and then serves it from the local cache
  (`~/.cache/typst`). The vendored copy in `modern-cv/0.10.0/` is the pinned
  reference and the source for offline installs.

### Local patch to the vendored modern-cv (do not revert)

`modern-cv/0.10.0/lib.typ` carries one local modification, marked in the
source with `// LOCAL PATCH (ATS)`: `resume-entry` prints the entry date
**inline after the description/company name** (e.g. "Novo Analytics A/S
2021 - Present") instead of in a right-aligned box, as stock 0.10.0 does.

Why: the stock `secondary-justified-header(description, date)` puts the date
in a separate right-aligned text region. Position-based text extractors
(pdfminer/xpdf family, used by several ATS resume parsers) treat a
consistent right-hand region as its own column and emit every entry's date
as a detached block after all entries, so the parser cannot associate a
date with the job it belongs to (verified against this repo's own PDFs).
Inline dates keep date and company on one stream-order line.

Because Typst resolves `@preview/modern-cv:0.10.0` from two places, the
patched `lib.typ` must exist in both:
- `cv/system-package/preview/modern-cv/0.10.0/lib.typ` - regenerated by
  `.scripts/sync-package.sh` (copies from this directory);
- `~/.cache/typst/packages/preview/modern-cv/0.10.0/lib.typ` - the registry
  cache used for documents outside `cv/` (e.g. `.dev/` samples). If the
  cache is cleared or re-fetched, restore it with
  `cp md-typst-templates/modern-cv/0.10.0/lib.typ ~/.cache/typst/packages/preview/modern-cv/0.10.0/lib.typ`.

To upgrade the package, re-apply this patch to the new version and update
both copies. The stock behavior is restored by reverting `resume-entry`'s
second line to `#secondary-justified-header(description, date)`.

### Offline mode (optional)

If the machine has no network at compile time, install the vendored packages
as a Typst *system package* next to the generated `.typ` files:

```bash
.scripts/sync-package.sh     # copies the three vendored packages into cv/system-package/
                             # and writes cv/system-package.toml
```

`@preview/modern-cv:0.10.0` (and the two dependencies) then resolve locally.
Verified layout: `cv/system-package.toml` with one
`[packages."preview/<name>"] version = "<version>"` entry per package, and
the package sources under `cv/system-package/preview/<name>/<version>/`.

## Fonts

The package asks for "Source Sans 3" (body), "Roboto" (name/header), and
Font Awesome 7 (contact icons). None are guaranteed to be installed, so they
are bundled in `fonts/` and every compile passes `--font-path
md-typst-templates/fonts`:

| Font | Source | License |
|---|---|---|
| Source Sans 3 (variable, regular + italic) | google/fonts, `ofl/sourcesans3/` | SIL OFL |
| Roboto (Regular, Medium, Bold, Light, Italic) | googlefonts/roboto-2 release v2.138 (unhinted) | Apache 2.0 |
| Font Awesome 7 Free (Regular, Solid) + Brands | FortAwesome/Font-Awesome release 7.3.1 (desktop OTF) | SIL OFL |

If you add a font family, put its license file next to it.

## Regenerating `pandoc.typ`

```bash
pandoc --print-default-template=typst > md-typst-templates/pandoc.typ
```

Record the pandoc version used (at the time of this writing: pandoc 3.12.1,
typst 0.15.1).

## Cover letters

`cover.typ` emits `coverletter(...)` (modern-cv's Awesome-CV-port cover
letter) plus `hiring-entity-info(...)` and `letter-heading(...)` from the
frontmatter, then the Markdown body. The template renders the closing line
and the printed name itself (localized "Sincerely," + bold name,
right-aligned; "Attached: Curriculum Vitae" at the bottom) - the letter body
never writes them. Frontmatter keys: the identity keys shared with the CV
(`firstname`, `lastname`, `address`, `phone`, `email`, `linkedin`, `github`,
`positions` - `positions` is required by the package), plus `company`,
`target`, `company-street`, `company-city`, `addressee`, `job-position`, and
optional `dear`, `signature-line`, `language`, `accent-color`, `paper-size`,
`par-spacing`. The full structure and tailoring rules live in
`.claude/skills/job-application-assistant/06-cover-letter-templates.md`.

Non-English letters: the package `lang.toml` localizes salutation/closing for
en, de, gr, pt, sp, fr, ru, zh, it, nl. For languages without an entry (e.g.
Danish), set `dear:` (salutation override), `signature-line:` (closing line,
comma included), and `language:`.

## Gotchas

- **Never write a `$...$` sequence in a `cv.typ`/`cover.typ` comment.** Pandoc treats it
  as a template variable and will splice content into the file.
- **Pandoc variable tokens run from one `$` to the next.** A literal quote
  must never sit between the variable name and its closing `$` (the pattern
  is `"$var/nowrap$"`, quote *after* the closing `$`). A quoted value with a
  default must put the quotes outside the block: `"$if(key)$$key/nowrap$$else$default$endif$"`.
- **Long frontmatter values are re-wrapped by Pandoc** to the column width
  when the generated line is long, which would split a Typst string literal.
  All string variables in the templates use the `/nowrap` modifier.
- **A bare string literal inside Typst content renders with smart quotes.**
  Interpolated values that land in content (e.g. the custom signature) need
  `#` string conversion: `[#"$signature-line/nowrap$"]`.
- Executable Typst in the Markdown uses Pandoc raw blocks: the fence is
  ```` ```{=typst} ```` (not a plain ` ```typ ` fence, which Typst would
  render as a displayed code block instead of executing).
- The package's `author` dictionary requires `positions` (no default);
  `cv.typ` always emits it (empty list is fine).
- `resume-entry` blocks and level-1 headings are `sticky` in the package:
  an entry title or section heading can never be stranded at the bottom of a
  page with its content on the next page. No `\needspace` equivalent needed.
- Typst has no `\enlargethispage` equivalent: if content spills onto a third
  page, cut content (see the relevance-weighted cutting rules in the CV
  skill) or tighten a raw block's spacing. There is no page-stretch rescue.
- `modern-cv/0.10.0/` is **not** a pristine copy of the upstream package:
  it carries the local ATS patch described above. Never overwrite it with a
  fresh download of 0.10.0 without re-applying the patch (and re-running
  `.scripts/sync-package.sh`).
