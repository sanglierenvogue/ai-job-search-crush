// cv.typ — Pandoc -> Typst template for the CV pipeline.
//
// Usage:
//   pandoc cv/<YYMMDD>_<company>_<position-slug>.md \
//     --template=md-typst-templates/cv.typ \
//     -o cv/build/<YYMMDD>_<company>_<position-slug>.typ
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
    positions: ($for(positions)$"$positions/nowrap$"$sep$,$endfor$),
  ),
  profile-picture: none,
  // #3873B3 = moderncv's "blue" accent (rgb 0.22/0.45/0.70), matching the
  // legacy banking CVs. Override per CV via the accent-color frontmatter key.
  accent-color: $if(accent-color)$$accent-color$$else$"#3873B3"$endif$,
  font: ("Source Sans 3",),
  header-font: "Roboto",
  paper-size: "$if(paper-size)$$paper-size/nowrap$$else$us-letter$endif$",
  show-footer: false,
)

$body$
