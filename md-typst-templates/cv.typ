// cv.typ — Pandoc -> Typst template for the CV pipeline.
//
// Usage:
//   pandoc job-applications/<company>/<YYMMDD>_<position-slug>/<YYMM>_<initials>_CV_<position-slug>.md \
//     --template=md-typst-templates/cv.typ \
//     -o job-applications/<company>/<YYMMDD>_<position-slug>/build/<YYMM>_<initials>_CV_<position-slug>.typ
//
// The Markdown source carries the identity data in its YAML frontmatter
// (firstname, lastname, address, phone, email, linkedin, github, positions)
// and the content as headings, lists, and raw typst blocks (```{=typst}).
// Pandoc converts the Markdown body to Typst (emitted via the body template
// variable at the bottom of this file) and interpolates the frontmatter keys
// as template variables (firstname, lastname, ...). The modern-cv package
// does the typesetting: header block, section headings, entry layout.
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

// Local font overrides for the modern-cv package, defined in this template
// (the vendored package is not modified). Each override changes only the
// requested values and keeps the package's fonts, sizes, and colors.
// Name header: first name in Regular instead of Thin (Raleway 32pt, accent
// color, and the bold last name are kept). The rule matches the only text
// element in the document with an own weight "thin", so the replacement is
// safe; the first name is re-rendered from the frontmatter. (Must be defined
// before the resume show rule below: rules defined after it do not apply
// inside the wrapped document content.)
#show text.where(weight: "thin"): it => text(
  fill: rgb("$if(accent-color)$$accent-color/nowrap$$else$#3873B3$endif$"),
  weight: "regular",
)[#"$firstname/nowrap$"]

#show: resume.with(
  author: (
    firstname: "$firstname$",
    lastname: "$lastname$",
$if(address)$
    address: "$address$",
$endif$
$if(phone)$
    phone: "$phone$",
$endif$
$if(email)$
    email: "$email$",
$endif$
$if(linkedin)$
    linkedin: "$linkedin$",
$endif$
$if(github)$
    github: "$github$",
$endif$
$if(homepage)$
    homepage: "$homepage$",
$endif$
    positions: ($for(positions)$"$positions/nowrap$",$endfor$),
  ),
  profile-picture: none,
  // #3873B3 = moderncv's "blue" accent (rgb 0.22/0.45/0.70), matching the
  // legacy banking CVs. Override per CV via the accent-color frontmatter key.
  accent-color: "$if(accent-color)$$accent-color/nowrap$$else$#3873B3$endif$",
  font: ("Lato",),
  header-font: "Raleway",
  paper-size: "$if(paper-size)$$paper-size/nowrap$$else$us-letter$endif$",
  show-footer: false,
)

// Skill category: Medium instead of Bold; skill values keep the package's
// Light weight. resume-skill-item is shadowed too because its internal
// call to resume-skill-category resolves inside the package module.
#let resume-skill-category(category) = {
  set text(size: 11pt, style: "normal", weight: "medium", hyphenate: false)
  set par(justify: false)
  category
}

#let resume-skill-item(category, items) = {
  set block(below: 0.65em)
  set pad(top: 2pt)

  pad[
    #grid(
      columns: (3fr, 8fr),
      gutter: 10pt,
      align: left + top,
      resume-skill-category(category), resume-skill-values(items),
    )
  ]
}

// Body default: 10pt instead of the package's 11pt. The set runs inside the
// package's resume evaluation (after its own set text(size: 11pt)), so it
// wins for the body text; entries, bullets, and skills carry their own
// sizes and are unaffected.
// Section headings (H1): 14pt instead of the package's 16pt. The show rule
// is defined after the package's own level-1 rule (inside cv-body), so it
// wins; the styling is the package's H1 rule with only the size changed.
#let cv-body() = {
  set text(size: 10pt)
  show heading.where(level: 1): it => block(sticky: true)[
    #set text(size: 14pt, weight: "regular")
    #set align(left)
    #set block(above: 1em)
    #text[#strong[#text(rgb("$if(accent-color)$$accent-color/nowrap$$else$#3873B3$endif$"))[#it.body]]]
    #box(width: 1fr, line(length: 100%))
  ]
  [
    // Space above the professional summary (first body block). Combined
    // with the summary's own 0.5em block spacing this reproduces the gap
    // between consecutive H1 sections (previous block's below + the
    // heading's 1em above).
    #v(1.5em)
    $body$
  ]
}

#cv-body()
