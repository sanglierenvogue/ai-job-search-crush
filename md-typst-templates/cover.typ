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
#import "@preview/linguify:0.5.0": linguify

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
// before the coverletter show rule below: rules defined after it do not
// apply inside the wrapped document content.)
#show text.where(weight: "thin"): it => text(
  fill: rgb("$if(accent-color)$$accent-color/nowrap$$else$#3873B3$endif$"),
  weight: "regular",
)[#"$firstname/nowrap$"]
// Addressee (target): 11pt Regular instead of 12pt Bold. The shadow is a
// copy of the package's hiring-entity-info with only the target's weight and
// size changed; the date and company block are kept.
#let hiring-entity-info(
  entity-info: (:),
  date: datetime.today().display("[month repr:long] [day], [year]"),
  use-smallcaps: true,
) = {
  set par(leading: 1em, ..default-par)
  pad(top: 1.5em, bottom: 1.5em)[
    #__justify_align[
      #text(weight: "regular", size: 11pt)[#entity-info.target]
    ][
      #text(weight: "light", style: "italic", size: 9pt)[#date]
    ]

    #pad(top: 0.65em, bottom: 0.65em)[
      #text(weight: "regular", fill: color-gray, size: 9pt)[
        #__apply_smallcaps(entity-info.name, use-smallcaps) \
        #entity-info.street-address \
        #entity-info.city \
      ]
    ]
  ]
}
// Position line: 10pt Medium instead of 12pt Bold; salutation ("Dear X,"):
// 10pt (weight and fill kept). The shadow is a copy of the package's
// letter-heading with only those values changed. lang.toml sits next to the
// generated .typ file (compile-cover-letter.sh copies it there).
#let letter-heading(
  job-position: "",
  addressee: "",
  dear: "",
  padding: (top: 1em, bottom: 1em),
) = {
  set par(..default-par)
  let lang_data = toml("lang.toml")

  underline(evade: false, stroke: 0.5pt, offset: 0.3em)[
    #text(weight: "medium", size: 10pt)[#linguify(
        "letter-position-pretext",
        from: lang_data,
      ) #job-position]
  ]
  pad(..padding)[
    #text(weight: "light", fill: color-gray, size: 10pt)[
      #if dear == "" [
        #linguify("dear", from: lang_data)
      ] else [
        #dear
      ]
      #addressee,
    ]
  ]
}

#let __letter-lang-data = toml("lang.toml")
// Signature: the name in Medium instead of the package's Bold (the size and
// the light closing line are kept). The closing line is the signature-line
// frontmatter key, or the package-localized "Sincerely" (comma except for
// German) when unset - mirroring the package's default-signature.
#let __letter-signature() = {
  align(right)[
    #text(weight: "light")[
$if(signature-line)$#"$signature-line/nowrap$"$else$#linguify("sincerely", from: __letter-lang-data)#if("$if(language)$$language/nowrap$$else$en$endif$" != "de") [#sym.comma]$endif$
    ] \
    #text(weight: "medium")[#"$firstname/nowrap$ $lastname/nowrap$"]
  ]
}

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
    positions: ($for(positions)$"$positions/nowrap$",$endfor$),
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
  signature: __letter-signature(),
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

// Body: 10pt instead of the package's 11pt. The set runs inside the
// package's coverletter evaluation (after its own set text(size: 11pt)), so
// it wins for the letter body; the weight stays Light (set by the package)
// and the signature/closing, rendered after the body, are unaffected.
#let letter-body() = {
  set text(size: 10pt)
  [
    $body$
  ]
}

#letter-body()
