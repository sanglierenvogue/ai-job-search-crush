// report.typ — Pandoc -> Typst template for generic multi-section documents
// (company research reports, job fit evaluations).
//
// Usage:
//   pandoc job-applications/<company>/<company>_research_<YYMMDD>.md \
//     --template=md-typst-templates/report.typ \
//     -o job-applications/<company>/build/<company>_research_<YYMMDD>.typ
//
// Plain document body with the same look and feel as the CV pipeline:
// Lato 11pt body, Raleway level-1 headings with a #3873B3 accent and bottom
// rule, 12pt bold level-2 headings, 15/15/10/10mm margins, us-letter default
// (override with the `paper-size` frontmatter key). No letterhead, no
// frontmatter block: any Markdown (headings, tables, bullets) compiles as-is.
//
// The heading style mirrors the modern-cv resume template's level-1/2 rules,
// so these documents read as part of the same application package.
//
// Note: do not write any dollar-sign-delimited sequence inside this header
// comment - Pandoc would treat it as a template variable.

// ATS text-layer safety: body text is justified, and with hyphenation on,
// Typst breaks compound words at their hyphens across lines and writes the
// break hyphen into the PDF text layer as U+00AD (soft hyphen).
#set text(hyphenate: false)

#set text(
  font: ("Lato",),
  size: 11pt,
  fill: rgb("#333333"),
  lang: "en",
  fallback: true,
)

#set page(
  paper: "$if(paper-size)$$paper-size/nowrap$$else$us-letter$endif$",
  margin: (left: 15mm, right: 15mm, top: 10mm, bottom: 10mm),
)

#set par(spacing: 0.75em, justify: true)
#set heading(numbering: none, outlined: false)

#show heading.where(level: 1): it => block(sticky: true)[
  #set text(font: ("Raleway",), size: 16pt, weight: "regular")
  #set align(left)
  #set block(above: 1em)
  #text[#strong[#text(rgb("#3873B3"))[#it.body]]]
  #box(width: 1fr, line(length: 100%))
]

#show heading.where(level: 2): it => {
  set text(font: ("Raleway",), rgb("#333333"), size: 12pt, weight: "bold")
  it.body
}

#show heading.where(level: 3): it => {
  set text(font: ("Raleway",), rgb("#333333"), size: 10pt, weight: "regular")
  it.body
}

$body$
