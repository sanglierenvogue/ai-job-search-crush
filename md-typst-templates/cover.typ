// cover.typ — Pandoc -> Typst template for the cover letter pipeline.
//
// Usage:
//   pandoc job-applications/<company>/<YYMMDD>_<position-slug>/<YYMM>_<initials>_cover-letter_<position-slug>.md \
//     --template=md-typst-templates/cover.typ \
//     -o job-applications/<company>/<YYMMDD>_<position-slug>/build/<YYMM>_<initials>_cover-letter_<position-slug>.typ
//
// The Markdown source carries the identity and target data in its YAML
// frontmatter (firstname, lastname, company, target, addressee,
// job-position, ...) and the body as plain Markdown paragraphs and lists.
// Pandoc converts the body to Typst (emitted via the body template variable
// below) and interpolates the frontmatter keys as template variables. The
// modern-cv package does the typesetting: the coverletter header, the
// hiring-entity block, the letter heading, and the signature/closing.
//
// Note: do not write any dollar-sign-delimited sequence inside this header
// comment - Pandoc would treat it as a template variable.
//
// pandoc.typ (the stock Pandoc Typst template) is kept in this directory as a
// structural reference for the template-variable syntax.

#import "@preview/modern-cv:0.10.0": *

// ATS text-layer safety: the template justifies body text (set par(justify: true)
// inside modern-cv), and with hyphenation on, Typst breaks compound words at
// their hyphens across lines and writes the break hyphen into the PDF text
// layer as U+00AD (soft hyphen). Extractors (Tika/PDFBox/pypdf) then see
// "end-<U+00AD>to-end" split across lines, which breaks keyword matching.
#set text(hyphenate: false)

#show: coverletter.with(
  author: (
    firstname: "$firstname/nowrap$",
    lastname: "$lastname/nowrap$",
$if(address)$
    address: "$address/nowrap$",
$endif$
$if(phone)$
    phone: "$phone/nowrap$",
$endif$
$if(email)$
    email: "$email/nowrap$",
$endif$
$if(linkedin)$
    linkedin: "$linkedin/nowrap$",
$endif$
$if(github)$
    github: "$github/nowrap$",
$endif$
    positions: ($for(positions)$"$positions/nowrap$"$sep$,$endfor$),
  ),
  profile-picture: none,
  // #3873B3 = moderncv's "blue" accent, matching the CV pipeline so the
  // application package is visually consistent. Override per letter via the
  // accent-color frontmatter key.
  accent-color: "$if(accent-color)$$accent-color/nowrap$$else$#3873B3$endif$",
  font: ("Lato",),
  header-font: "Raleway",
  paper-size: "$if(paper-size)$$paper-size/nowrap$$else$us-letter$endif$",
  language: "$if(language)$$language/nowrap$$else$en$endif$",
  show-footer: false,
  signature-alignment: right,
  // Tighten to 1em (via the par-spacing frontmatter key) when a letter is
  // close to the 1-page limit.
  par-spacing: $if(par-spacing)$$par-spacing/nowrap$$else$1.5em$endif$,
// Optional custom closing line (e.g. a closing for a language the package
// lang.toml does not localize, or "Kind regards," for English
// letters following the former stock template). Rendered right-aligned with
// the bold name below, matching the package's default signature layout.
$if(signature-line)$
  signature: align(right)[#text(weight: "light")[#"$signature-line/nowrap$"] \ #text(weight: "bold")[#"$firstname/nowrap$ $lastname/nowrap$"]],
$endif$
)

#hiring-entity-info(
  entity-info: (
    target: "$target/nowrap$",
    name: "$company/nowrap$",
    street-address: "$if(company-street)$$company-street/nowrap$$endif$",
    city: "$if(company-city)$$company-city/nowrap$$endif$",
  ),
)

#letter-heading(job-position: "$job-position/nowrap$", addressee: "$addressee/nowrap$"$if(dear)$, dear: "$dear/nowrap$"$endif$)

$body$
