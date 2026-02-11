// Chapter-based numbering for books with appendix support
#let equation-numbering = it => {
  let pattern = if state("appendix-state", none).get() != none { "(A.1)" } else { "(1.1)" }
  numbering(pattern, counter(heading).get().first(), it)
}
#let callout-numbering = it => {
  let pattern = if state("appendix-state", none).get() != none { "A.1" } else { "1.1" }
  numbering(pattern, counter(heading).get().first(), it)
}
#let subfloat-numbering(n-super, subfloat-idx) = {
  let chapter = counter(heading).get().first()
  let pattern = if state("appendix-state", none).get() != none { "A.1a" } else { "1.1a" }
  numbering(pattern, chapter, n-super, subfloat-idx)
}
// Theorem configuration for theorion
// Chapter-based numbering (H1 = chapters)
#let theorem-inherited-levels = 1

// Appendix-aware theorem numbering
#let theorem-numbering(loc) = {
  if state("appendix-state", none).at(loc) != none { "A.1" } else { "1.1" }
}

// Theorem render function
// Note: brand-color is not available at this point in template processing
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  block(
    width: 100%,
    inset: (left: 1em),
    stroke: (left: 2pt + black),
  )[
    #if full-title != "" and full-title != auto and full-title != none {
      strong[#full-title]
      linebreak()
    }
    #body
  ]
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

// Use nested show rule to preserve list structure for PDF/UA-1 accessibility
// See: https://github.com/quarto-dev/quarto-cli/pull/13249#discussion_r2678934509
#show terms: it => {
  show terms.item: item => {
    set text(weight: "bold")
    item.term
    block(inset: (left: 1.5em, top: -0.4em))[#item.description]
  }
  it
}

// Prevent breaking inside definition items, i.e., keep term and description together.
#show terms.item: set block(breakable: false)

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}


// syntax highlighting functions from skylighting:
/* Function definitions for syntax highlighting generated by skylighting: */
#let EndLine() = raw("\n")
#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
   let blocks = []
   let lnum = start - 1
   let bgcolor = rgb("#f1f3f5")
   for ln in sourcelines {
     if number {
       lnum = lnum + 1
       blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
     }
     blocks = blocks + ln + EndLine()
   }
   block(fill: bgcolor, blocks)
}
#let AlertTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let AnnotationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let AttributeTok(s) = text(fill: rgb("#657422"),raw(s))
#let BaseNTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let BuiltInTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let CharTok(s) = text(fill: rgb("#20794d"),raw(s))
#let CommentTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let CommentVarTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ConstantTok(s) = text(fill: rgb("#8f5902"),raw(s))
#let ControlFlowTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let DataTypeTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DecValTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DocumentationTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ErrorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let ExtensionTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let FloatTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let FunctionTok(s) = text(fill: rgb("#4758ab"),raw(s))
#let ImportTok(s) = text(fill: rgb("#00769e"),raw(s))
#let InformationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let KeywordTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let NormalTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let OperatorTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let OtherTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let PreprocessorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let RegionMarkerTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let SpecialCharTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let SpecialStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let StringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let VariableTok(s) = text(fill: rgb("#111111"),raw(s))
#let VerbatimStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let WarningTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))



#let article(
  title: none,
  subtitle: none,
  authors: none,
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: none,
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  // Set document metadata for PDF accessibility
  set document(title: title, keywords: keywords)
  set document(
    author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()
  set par(
    justify: true,
    leading: linestretch * 0.65em
  )
  set text(lang: lang,
           region: region,
           size: fontsize)
  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  set heading(numbering: sectionnumbering)

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      text(this)
    }
   }

  place(top, float: true, scope: "parent", clearance: 4mm)[
    #if title != none {
      align(center, block(inset: 2em)[
        #set par(leading: heading-line-height) if heading-line-height != none
        #set text(font: heading-family) if heading-family != none
        #set text(weight: heading-weight)
        #set text(style: heading-style) if heading-style != "normal"
        #set text(fill: heading-color) if heading-color != black

        #text(size: title-size)[#title #if thanks != none {
          footnote(thanks, numbering: "*")
          counter(footnote).update(n => n - 1)
        }]
        #(if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        })
      ])
    }

    #if authors != none and authors != () {
      let count = authors.len()
      let ncols = calc.min(count, 3)
      grid(
        columns: (1fr,) * ncols,
        row-gutter: 1.5em,
        ..authors.map(author =>
            align(center)[
              #author.name \
              #author.affiliation \
              #author.email
            ]
        )
      )
    }

    #if date != none {
      align(center)[#block(inset: 1em)[
        #date
      ]]
    }

    #if abstract != none {
      block(inset: 2em)[
      #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
      ]
    }
  ]

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  doc
}

#set table(
  inset: 6pt,
  stroke: none
)
#show heading: set text(font: ("Pretendard", "Helvetica", "IBM Plex Sans", "IBM Plex Sans KR"), weight: "bold")
#set text(font: ("IBM Plex Sans", "IBM Plex Sans KR"))
#show raw: it => {
  set text(
    font: ("Monoplex KR", "IBM Plex Mono"),
  )
  it
}
#set page(background: rotate(24deg,
  text(72pt, fill: gray)[
    *Seoncheol Park*
  ]
))
#import "@preview/theorion:0.4.1": make-frame

// Simple theorem render: bold title with period, italic body
#let simple-theorem-render(prefix: none, title: "", full-title: auto, body) = {
  if full-title != "" and full-title != auto and full-title != none {
    strong[#full-title.]
    h(0.5em)
  }
  emph(body)
  parbreak()
}
#let (definition-counter, definition-box, definition, show-definition) = make-frame(
  "definition",
  text(weight: "bold")[Definition],
  inherited-levels: theorem-inherited-levels,
  numbering: theorem-numbering,
  render: simple-theorem-render,
)
#show: show-definition
#let (exercise-counter, exercise-box, exercise, show-exercise) = make-frame(
  "exercise",
  text(weight: "bold")[Exercise],
  inherited-levels: theorem-inherited-levels,
  numbering: theorem-numbering,
  render: simple-theorem-render,
)
#show: show-exercise
#let (theorem-counter, theorem-box, theorem, show-theorem) = make-frame(
  "theorem",
  text(weight: "bold")[Theorem],
  inherited-levels: theorem-inherited-levels,
  numbering: theorem-numbering,
  render: simple-theorem-render,
)
#show: show-theorem
#import "@preview/fontawesome:0.5.0": *
#let (example-counter, example-box, example, show-example) = make-frame(
  "example",
  text(weight: "bold")[Example],
  inherited-levels: theorem-inherited-levels,
  numbering: theorem-numbering,
  render: simple-theorem-render,
)
#show: show-example
#let brand-color = (:)
#let brand-color-background = (:)
#let brand-logo = (:)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
  columns: 1,
)
// Logo is handled by orange-book's cover page, not as a page background
// NOTE: marginalia.setup is called in typst-show.typ AFTER book.with()
// to ensure marginalia's margins override the book format's default margins
#import "@preview/orange-book:0.7.1": book, part, chapter, appendices

#show: book.with(
  title: [A Beginner's Guide to Linear Models],
  author: "Seoncheol Park",
  date: "2026-02-11",
  main-color: brand-color.at("primary", default: blue),
  logo: {
    let logo-info = brand-logo.at("medium", default: none)
    if logo-info != none { image(logo-info.path, alt: logo-info.at("alt", default: none)) }
  },
  outline-depth: 3,
)


#import "@preview/thmbox:0.2.0": *
#show: thmbox-init(counter-level: 1)
#let default-color = rgb("#0E4A84")
#let supp-color = rgb("898C8E").lighten(75%)
#let h-color = default-color.lighten(75%)
#let b-color = default-color.lighten(85%)

/*colors for theorem*/
#let dark-red = rgb("#C5283D") // theorem
#let orange = rgb("#ff851b") // definition
#let lime = rgb("#8dc159") // example
#let green = rgb("#4a9952") // claim
#let light-turquoise = rgb("#90c6b7") // lemma
#let turquoise = rgb("#118d8d") // note
#let light-aqua = rgb("#68b3ff") // exercise
#let aqua = rgb("#3fa1d2") // axiom
#let blue = rgb("#3988d7") // (내가) proof
#let light-blue = rgb("#5f83d2") // proposition
#let dark-blue = rgb("#11388d") //(내가) solution
#let purple = rgb("#66118d") // algorithm
#let pink = rgb("#c34dd1") // corollary
#let gray = rgb("#797979") // remark
#let dark-gray = rgb("#575757") // conjecture

#let proof(
  title: translations.variant("proof"),
  separator: ".",
  body: [],
  ..args
) = {
  // set values
  let pa = args.pos()
  let num-pas = pa.len()
  let title = if num-pas == 2 [#translations.variant("proof") #pa.at(0)] else {title}
  let body = if num-pas > 0 and num-pas <= 3 {pa.at(num-pas - 1)} else {body}

  [
    #set text(style: "oblique", weight: "regular")
    #title;#separator
  ] 
  [#body #qed()]
}

#let remark(
  title: translations.variant("remark"),
  separator: ".",
  body: [],
  ..args
) = {
  // set values
  let pa = args.pos()
  let num-pas = pa.len()
  let title = if num-pas == 2 [#translations.variant("remark") #pa.at(0)] else {title}
  let body = if num-pas > 0 and num-pas <= 3 {pa.at(num-pas - 1)} else {body}

  [
    #set text(style: "oblique", weight: "regular")
    #title;#separator
  ] 
  [#body]
}

/// Used for theorems, uses a dark red color by default.
#let theorem = thmbox.with(
  color: colors.dark-red, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("theorem"))
/// Used for propositions, uses a light blue color by default.
#let proposition = thmbox.with(
  color: colors.light-blue, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("proposition"))
/// Used for lemmas, uses a light turquoise color by default.
#let lemma = thmbox.with(
  color: colors.light-turquoise, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("lemma"))
/// Used for corollaries, uses a pink color by default.
#let corollary = thmbox.with(
  color: colors.pink, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("corollary"))
/// Used for definitions, uses an orange color by default.
#let definition = thmbox.with(
  color: colors.orange, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("definition"))
/// Used for examples, uses a lime color and is not numbered by default.
#let example = thmbox.with(
  color: colors.lime, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("example"), 
  //numbering: none, 
  //sans: false,
)
/// Used for notes, uses a turquoise color and is not numbered by default.
#let note = thmbox.with(
  color: colors.turquoise, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("note"), 
  //numbering: none, 
  //sans: false,
)
/// Used for exercises, uses a blue color by default.
#let exercise = thmbox.with(
  color: colors.light-aqua, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("exercise"),
  //numbering: none,
  //sans: false,
)
/// Used for algorithms, uses a purple color by default.
#let algorithm = thmbox.with(
  color: colors.purple, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("algorithm"), 
  //sans: false,
)
/// Used for claims, uses a green color and is not numbered by default.
#let claim = thmbox.with(
  color: colors.green, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("claim"), 
  numbering: none,
)
/// Used for axioms, uses an aqua color by default.
#let axiom = thmbox.with(
  color: colors.aqua, 
  sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
  variant: translations.variant("axiom")
)
/// Used for remarks, uses a gray color and is not numbered by default.
#let remark = remark.with(
    color: colors.gray, 
    sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
    title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
    title: "Remark", 
    numbering: none, 
    //sans: false,
)
// derive from some predefined function
#let solution = proof.with(
    //fill: rgb("#ffdcdc"), 
    title: "Solution", 
    color: dark-blue,
    sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
    title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
    //title-fonts: "Noto Sans",
    numbering: none
)
#let proof = proof.with(
    //fill: rgb("#ffdcdc"), 
    variant: translations.variant("proof"), 
    color: blue,
    sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
    title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
    numbering: none,
    //bar-thickness: 3pt,
    //fill: yellow.lighten(100%),
    //title-font: "Noto Sans",
    inset: (x: 0pt, y: 0em)
)
#let assumption = thmbox.with(
    //fill: rgb("#ffdcdc"), 
    variant: "Assumption", 
    color: dark-gray,
    sans-fonts: ("IBM Plex Sans", "IBM Plex Sans KR"),
    title-fonts: ("IBM Plex Sans", "IBM Plex Sans KR")
)

#let code(
  code,
  lang: "py",
  font-size: 9pt,
  border-size: 0.13em,
  border-color: luma(170),
  line-color-1: luma(250),
  line-color-2: luma(240),
  lines: none,
  line-numbers: false,
  line-number-color: luma(130),
) = {

  // Filter code to only include specified lines
  let start-line = if lines != none { lines.at(0) } else { 1 }
  let code = if lines != none {
    let code-lines = code.split("\n")
    let start = lines.at(0) - 1  // Convert to 0-indexed
    let end = lines.at(1)
    code-lines.slice(start, end).join("\n")
  } else {
    code
  }

  // Change how raw.line looks
  show raw.line: line => {

    // Constants
    let first-line-num = 1
    let last-line-num = line.count

    let inset-y = font-size/4
    let line-height = 2*inset-y + font-size

    let stroke = border-color + border-size

    let get-stroke(line-num) = {
           if line-num == first-line-num { return (   top: stroke, x: stroke) }
      else if line-num == last-line-num  { return (bottom: stroke, x: stroke) }
      else { return (x: stroke) }
    }

    let get-radius(line-num) = {
           if line-num == first-line-num { return (   top: 1em) }
      else if line-num == last-line-num  { return (bottom: 1em) }
      else { return (0em) }
    }

    let get-fill(line-num) = {
      if calc.even(line-num) { return line-color-2 }
      else { return line-color-1 }
    }

    let display-line-num = line.number + start-line - 1
    let line-num-width = 2.5em

    block(
      breakable: false,
      height: line-height,
      width: 100%,
      inset: (x: inset-y*2, y: inset-y),
      fill: get-fill(line.number),
      radius: get-radius(line.number),
      stroke: get-stroke(line.number),
      spacing: -0.4em,
      if line-numbers {
        grid(
          columns: (line-num-width, 1fr),
          text(size: font-size, fill: line-number-color)[#display-line-num],
          text(size: font-size)[#line.body],
        )
      } else {
        text(size: font-size)[#line.body]
      }
    )
  }

  // Display raw content using custom design defined above
  v(2*0.4em) // Compensate for spacing: -0.4em
  raw(code, lang: lang)
  v(2*0.4em)
}

//https://github.com/typst/typst/discussions/4031
#let appendix(body) = {
  set heading(numbering: "A", supplement: [Appendix])
  body
}
// Reset Quarto's custom figure counters at each chapter (level-1 heading).
// Orange-book only resets kind:image and kind:table, but Quarto uses custom kinds.
// This list is generated dynamically from crossref.categories.
#show heading.where(level: 1): it => {
  counter(figure.where(kind: "quarto-float-fig")).update(0)
  counter(figure.where(kind: "quarto-float-tbl")).update(0)
  counter(figure.where(kind: "quarto-float-lst")).update(0)
  counter(figure.where(kind: "quarto-callout-Note")).update(0)
  counter(figure.where(kind: "quarto-callout-Warning")).update(0)
  counter(figure.where(kind: "quarto-callout-Caution")).update(0)
  counter(figure.where(kind: "quarto-callout-Tip")).update(0)
  counter(figure.where(kind: "quarto-callout-Important")).update(0)
  counter(math.equation).update(0)
  it
}

#heading(level: 1, numbering: none)[Preface]
<preface>
열심히 공부합시다.

#part[Intro]
= Introduction
<introduction>
- #strong[회귀분석(regression analysis)]: 설명변수와 반응변수 사이의 함수관계를 알아내는 통계적 방법

- 용어의 역사: Galton의 #link("https://en.wikipedia.org/wiki/Regression_toward_the_mean")[#NormalTok("Regression toward the mean");]란 말에서부터 유래함

== Galton's data
<galtons-data>
#strong[Q]. 아버지와 아들 사이의 키 상관관계?

#Skylighting(([#FunctionTok("library");#NormalTok("(HistData)");],
[#NormalTok("xx ");#OtherTok("=");#NormalTok(" GaltonFamilies");#SpecialCharTok("$");#NormalTok("midparentHeight");],
[#NormalTok("yy ");#OtherTok("=");#NormalTok(" GaltonFamilies");#SpecialCharTok("$");#NormalTok("childHeight");],
[],
[#FunctionTok("plot");#NormalTok("(xx, yy, ");#AttributeTok("xlab=");#StringTok("\"Father\"");#NormalTok(", ");#AttributeTok("ylab=");#StringTok("\"Child\"");#NormalTok(", ");#AttributeTok("main=");#StringTok("\"Galton's data\"");#NormalTok(")");],));
#figure([
#box(image("intro_files/figure-typst/unnamed-chunk-1-1.svg", alt: "Figure: Galton’s dataset", width: 70%))
], caption: figure.caption(
position: bottom, 
[
Figure: Galton's dataset
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#definition(title: "테스트용")[
테스트 정의이다.

] <def-test>
#part[Simple Linear Regression]
= Simple Linear Regression
<simple-linear-regression-1>
== Regression analysis
<regression-analysis>
- #strong[Goal]: Find a linear relationship between an explanatory variable ($X$) and a response variable $\( Y \)$

- #strong[Assumptions]

+ Linearity $ E \( Y \| X = x \) = beta_0 + beta_1 x $

+ $Y \| x$ follows a normal distribution

+ Constant variance $ upright("Var") \( Y \| X = x \) = sigma^2 < oo $

+ Explanatory variable $X$ is a fixed variable (not random)

+ Response variable $Y$ is a random variable with measurement error $epsilon tilde.op \( 0 \, sigma^2 \)$

- #strong[Simple linear regression model]

$ y_i = beta_0 + beta_1 x_i + epsilon_i quad  upright("or") quad  Y = beta_0 + beta_1 X + epsilon $

== Ordinary least squares (OLS)
<ordinary-least-squares-ols>
With $n$ data points $\( x_i \, y_i \)_(i = 1)^n$, our goal is to find the #strong[best] linear fit of the data $ \( x_i \, hat(y)_i = hat(beta)_0 + hat(beta)_1 x_i \)_(i = 1)^n $

#strong[Q]. What is the #strong[best] fit?

#link("https://en.wikipedia.org/wiki/Carl_Friedrich_Gauss")[Gauss]가 제안한 방식은 다음의 #strong[ordinary least squares (OLS)]이다. $ \( hat(beta)_0 \, hat(beta)_1 \) = arg min_(beta_0 \, beta_1) 1 / n sum_(i = 1)^n \( y_i - beta_0 - beta_1 x_i \)^2 $

#exercise(title: "Least absolute deviation (LAD)")[
#strong[Least absolute deviation (LAD)]에 대해 조사해보자.

] <exr-OLS01>
위의 식을 풀기 위해 각각을 $beta_0 \, beta_1$로 미분 후 $0$이 되는 $hat(beta)_0 \, hat(beta)_1$을 찾는 전략을 이용하게 되는데, 여기서 #strong[정규방정식(normal equation)]을 얻게 된다. $ cases(delim: "{", - 2 / n sum_(i = 1)^n \( y_i - hat(beta)_0 - hat(beta)_1 x_i \) & = 0, - 2 / n sum_(i = 1)^n x_i \( y_i - hat(beta)_0 - hat(beta)_1 x_i \) & = 0) $

#part[Nonlinear and Nonparametric Models]
= Boosting
<boosting>
== Boosting: 개요
<boosting-개요>
- Boosting의 가장 큰 특징: base learner를 sequentially하게 fitting함

- Base learner로는 weak learner를 사용: tree를 예로 들면 한 번 정도 split한 tree를 base learner로 사용

https:\/\/www.uio.no/studier/emner/matnat/math/STK-IN4300/h22/slides/lect10\_modified.pdf

== AdaBoost
<adaboost>
== Gradient boosting
<gradient-boosting>
부스팅 공부할 만한 자료: #link("https://mlcourse.ai/book/topic10/topic10_gradient_boosting.html")

=== $L^2$ boosting
<l2-boosting>
- Reference: #link("https://mdporter.github.io/DS6030/lectures/boosting.pdf")

#figure([
#box(image("boosting_files/figure-typst/unnamed-chunk-1-1.svg", alt: "L2 boosting", width: 70%))
], caption: figure.caption(
position: bottom, 
[
L2 boosting
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
#figure([
#box(image("boosting_files/figure-typst/unnamed-chunk-1-2.svg", alt: "L2 boosting", width: 70%))
], caption: figure.caption(
position: bottom, 
[
L2 boosting
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
#block[
#figure([
#box(image("boosting_files/figure-typst/unnamed-chunk-1-3.svg", alt: "L2 boosting", width: 70%))
], caption: figure.caption(
position: bottom, 
[
L2 boosting
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
=== Distributional gradient boosting
<distributional-gradient-boosting>
- #link("https://ar5iv.labs.arxiv.org/html/2204.00778")[Distirbutional gradient boosting]

= 커널회귀
<커널회귀>
== RKHS
<rkhs>
어떤 $n times p$ 행렬 $A$가 있을 때 이것의 column space를 $C \( A \)$라고 하자.

Ronald Christensen은 아래 $C \( X X^T \) = C \( X \)$의 결과를 #strong[the fundamental theorem of reproducing kernel Hilbert spaces]라고 부른다.

#definition(title: "Two column spaces are equiv")[
For any matrix $X$, $C \( X X^T \) = C \( X \)$.

] <def-equivcs>
#block[
#emph[Proof]. Clearly $C \( X X^T \) subset C \( X \)$, so we need to show that $C \( X \) subset C \( X X^T \)$. Let $x in C \( X \)$. Then $x = X b$ for some $b$. Write $b = b_0 + b_1$, where $b_0 in C \( X^T \)$ and $b 1 perp C \( X^T \)$. Clearly, $X b_1 = 0$, so we have $x = X b_0$. But $b_0 = X^T d$ for some $d$\; so $x = X b_0 = X X^T d$ and $x in C \( X X^T \)$.

]
#definition(title: "Equivalent Linear Models")[
If $Y = X_1 beta_1 + e_1$ and $Y = X_2 beta_2 + e_2$ are two models for the same dependent variable vector $Y$, the models are #strong[equivalent] if $C \( X_1 \) = C \( X_2 \)$.

Since $C \( X \) = C \( X X^T \)$, this implies that the linear models $Y = X beta_1 + e_1$ and $Y = X X^T beta_2 + e_2$ are equivalent.

] <def-equivlm>
RKHS는 $p$-벡터 $x_i$를 $s$-벡터 $phi.alt_i$로 $phi.alt_i = mat(delim: "[", phi.alt_0 \( x_i \) \, dots.h.c phi.alt_(s - 1) \( x_i \))^T$로 변환시킨다. $X$를 $x_i^T$들이 행으로 구성된 행렬로 보면 똑같은 논리로 $phi.alt_i^T$가 행으로 구성된 행렬 $Phi$를 생각할 수 있다. $X^X = \[ x_i^T x_j \]$를 $x_i$들의 inner products로 만드는 $n times n$ 행렬로 보면 RKHS는 #strong[reproducing kernel] $R \( dot.op \, dot.op \)$이 존재해 $ tilde(R) equiv \[ R \( x_i \, x_j \) \] = \[ phi.alt_i^T D \( eta \) phi.alt_j \] = Phi D \( eta \) Phi^T $ 가 $phi.alt_i$들의 $n times n$ inner product matrix이며 $D \( eta \)$가 positive definite diagonal matrix가 됨을 말해준다. $D \( eta \)$가 positive definite diagonal matrix이므로 PA책 Theorem B.22에 의해 $D \( eta \) = Q Q^T$인 정방행렬 $Q$가 존재할 것이고 the fundamental theorem of reproducing kernel Hilbert spaces에 따라 $s$가 유한하면 $C \[ Phi D \( eta \) Phi^T \] = C \( Phi \)$일 것이다. 따라서 rk 모형 $ Y = tilde(R) gamma + e $ 를 적합하는 것은 다음의 비모수모형 $ Y = Phi beta + e $ 를 적합하는 것과 같다. 즉 rk 모형은 $beta = D \( eta \) Phi^T gamma$로 reparametrization한 것이다. 특별히 rk 모형을 이요해 예측하는 것은 다음과 같이 하면 된다. $ hat(y) \( x \) = mat(delim: "[", R \( x \, x_1 \) \, dots.h \, R \( x \, x_n \)) hat(gamma) . $

$Phi$를 가지고 linear structure를 적합하는 것이나 $n times n$ 행렬 $tilde(R)$을 이용해 적합하는 것이나 같을 것이고 이를 #strong[kernel trick]이라 한다.

#theorem(title: "Hilbert space가 RKHS가 되기 위한 조건")[
A Hilbert space is a RKHS iff the evaluation functionals are continuous.

] <thm-hilbertRKHS>
== Kernel Trick
<kernel-trick>
Kernel trick의 가장 큰 장점은 알려진 함수 $R \( dot.op \, dot.op \)$을 쓰므로 $tilde(R)$을 만들어내기 쉽다는 것이다. 반대로 $phi.alt_j \( dot.op \)$ 함수들에서 $s$를 specify하는 것은 시간이 더 걸릴 것이다.

또한 $n times s$행렬 $Phi$는 $s$가 크면 이상해지는데, $tilde(R)$은 항상 $n times n$이 되어 $s$가 너무 커질때 이상해지거나 $s$가 너무 작을때 단순화되는 것을 막아준다.

$s gt.eq n$이고 $x_i$들이 distinct (같은 값을 갖는 $x$들이 없다는 뜻)라면 $tilde(R)$은 $n times n$ 이고 rank $n$인 행렬이며 이것은 saturated model (데이터 수 만큼 모수가 있는 모형)을 만든다. LS estimate는 fitted value가 obs와 같은 자료를 만들 것이며 d.f는 0이 될 것이다. 즉 overfitting이 있는 것인데, 그래서 보통 kernel trick은 penalized (regularized) estimation과 같이 사용하게 된다.

$s gt.eq n$일 때에는 다른 $R \( dot.op \, dot.op \)$을 선택한다 하더라도, 같은 $C \( tilde(R) \)$을 주어 같은 모형을 주는 셈이 된다. 즉 같은 least squares fits를 준다. 그러나 parametrization을 다르게 하고 거기에 penalty를 주는 방식 (ridge, LASSO 등)으로 다른 fitted value를 만들어낼 수 있다.

사용하려고 하는 $phi.alt_j$ 함수들을 다 알고 있을 경우, rk를 쓰는 이득이 었다. 그러나 $phi.alt_j$를 다루기 어렵거나 $s = oo$일 경우에는 rks가 도움이 될 것이다.

다음은 많이 쓰이는 rks들을 정리해 놓았다. $parallel u - v parallel$에만 의존하는 rk들을 #strong[radial basis function] rk라고 부른다.

#table(
  columns: (50%, 50%),
  align: (auto,auto,),
  table.header([Names], [$R \( u \, v \)$],),
  table.hline(),
  [Polynomial of degree $d$], [$\( 1 + u^T v \)^d$],
  [Polynomial of degree $d$], [$b \( c + u^T v \)^d$],
  [Gaussian (radial basis)], [$exp \( - b parallel u - v parallel^2 \)$],
  [Sigmoid (hyperbolic tangent)], [$upright("tanh") \( b u^T v + c \)$],
  [Linear spline ($u \, v$ scalars)], [$min \( u \, v \)$],
  [Cubic spline ($u \, v$ scalars)], [$max \( u \, v \) min^2 \( u \, v \) \/ 2 - min^3 \( u \, v \) \/ 6$],
  [Thin plate spline (2 dimensions)], [$parallel u - v parallel^2 log \( parallel u - v parallel \)$],
)
표에 있는 것들 중 hyperbolic tangent는 $tilde(R)$을 not nonnegatively definite한 것들로 줄 수도 있어 실제로 rk는 아니다. 그러나 $u$에 대해서 연속인 어떤 $R \( u \, v \)$든지 $ f \( x \) = sum_(j = 1)^n gamma_j R \( x \, x_j \) $ 와 같은 형태의 모형 적합을 유도해낼 수 있기 때문에 이러한 것들을 쓰는 것도 설득력이 있다.

Rk의 아이디어는 함수를 small support를 이용해 근사하는 방법들, 즉 1차원에서 $s_(*)$개의 집합으로 나누고 line의 partition을 만들어내는 wavelet, B-spline 등의 방법과 비교할 수 있다. 이러한 방법들은 당연히 $p$차원에서 $s_(*)^p$개의 dimension을 생각해야 하고 고차원에서 다루기 어렵게 된다. 그러나 kernel method에서는 각 data point에 커널을 적합하는 셈이므로 $p$가 크게 커져도 괜찮다.

== Kernel Trick과 SVM
<kernel-trick과-svm>
함수 안에 dot product가 있으면 kernel trick을 쓸 수 있다고 한다. 이러한 것들 중 대표적인 것이 SVM이다. SVM의 objective function은 다음과 같다. $ max_alpha sum_i alpha_i - 1 / 2 sum_i sum_j alpha_i alpha_j y_i y_j bold(x)_i^T bold(x)_j \, quad  upright("s.t. ") sum_i alpha_i y_i = 0 . $ 이 objective 함수 안에는 dot product $bold(x)_i^T bold(x)_j$가 들어 있고 kernel trick을 쓸 수 있어 SVM이 강력해진다.

#figure([
#box(image("images/kernel_ktrick01.png"))
], caption: figure.caption(
position: bottom, 
[
Figure: Example of a labeled data inseparable in 2-Dim is separable in 3-Dim.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-kernelreg01>


위 그림에서, 원래 자료 $bold(x) = { x_1 \, x_2 }$는 2차원에 있는데 이것은 inseparable 하지만 변환 $ Phi \( bold(x) \) arrow.r \( x_1^2 \, x_2^2 \, sqrt(2) x_1 x_2 \) $ 를 이용해 오른쪽 그림과 같이 바꾸면 분리가능하다.

앞선 $Phi$ 변환을 이용했을 때 3D 공간에서 decision boundary는 다음과 같다. $ beta_0 + beta_1 x_1^2 + beta_2 x_2^2 + beta_3 sqrt(2) x_1 x_2 = 0 . $ 만약 로지스틱과 같은 회귀를 이용한다면 위의 식과 같은 모형을 쓸 것이다. 그러나 SVM에서는 kernel trick을 이용해 decision boundary를 만들 수 있다. 이를 위해 $chevron.l Phi \( bold(x)_i \) \, Phi \( bold(x)_j \) chevron.r$의 dot product를 찾아야 한다.

일단 이것을 하려면

- $Phi$를 정의해야 하고
- $Phi$ 변환 계산시 $3 times 2$의 계산
- 그리고 dot product를 계산하는 데 3번 해서

총 9번의 계산이 필요하다. 그러나 만약 커널 $K \( bold(x)_i \, bold(x)_j \) = chevron.l bold(x)_i \, bold(x)_j chevron.r^2$을 이용한다면, 변환 $Phi$를 찾을 필요도 없고, 그냥 2차원 공간에서 바로 고차원의 similarity measure (dot product)를 만들어낼 수 있다.

로 만들어낼 수 있다. 이것을 하려면

- $K$는 정의해야 하나
- 두 번째 식까지 두 번의 operation
- 마지막 식에서 제곱을 위해 한 번의 operation

3번의 계산이 필요하다.

다른 예제를 보자. Decision boundary를 다음과 같이 정하였다. $ beta_0 + beta_1 x_1 + beta_2 x_2 + beta_3 x_1^2 + beta_4 x_2^2 + beta_5 sqrt(2) x_1 x_2 = 0 . $

$Phi \( bold(x) \) arrow.r \( 1 \, sqrt(2) x_1 \, sqrt(2) x_2 \, x_1^2 \, x_2^2 \, sqrt(2) x_1 x_2 \)$와 같이 5차원 변환 $Phi$를 이용해 구하는 방법은 총 16번의 계산을 필요로 한다.

그러나 커널 $K \( bold(x)_i \, bold(x)_j \) = chevron.l 1 + chevron.l bold(x)_i \, bold(x)_j chevron.r chevron.r^2$를 이용하면 세 번의 계산으로 된다고 한다.

=== 무한차원에서의 kernel trick
<무한차원에서의-kernel-trick>
앞선 논리를 그대로 적용하면, kernel trick은 infinite space에서도 유사도를 잴 수 있게 해준다. Gaussian Kernel (RBF), exponential kernel, Laplace kernel 등이 실제로 그러한 역할을 한다. Gaussian kernel은 다음과 같다. $ K \( bold(x)_i \, bold(x)_j \) = exp #scale(x: 180%, y: 180%)[\(] - frac(parallel bold(x)_i - bold(x)_j parallel^2, 2 sigma^2) #scale(x: 180%, y: 180%)[\)] $

$sigma = 1$로 두면 위의 Gaussian kernel은 $C = exp #scale(x: 180%, y: 180%)[\(] - 1 / 2 parallel bold(x)_i parallel^2 #scale(x: 180%, y: 180%)[\)] exp #scale(x: 180%, y: 180%)[\(] - 1 / 2 parallel bold(x)_j parallel^2 #scale(x: 180%, y: 180%)[\)]$으로 두었을 때 $ exp #scale(x: 180%, y: 180%)[\(] - 1 / 2 parallel bold(x)_i - bold(x)_j parallel^2 #scale(x: 180%, y: 180%)[\)] = C #scale(x: 180%, y: 180%)[{] 1 - underbrace(frac(chevron.l bold(x)_i \, bold(x)_j chevron.r, 1 !), upright("1st order")) + underbrace(frac(chevron.l bold(x)_i \, bold(x)_j chevron.r^2, 2 !), upright("2nd order")) - underbrace(frac(chevron.l bold(x)_i \, bold(x)_j chevron.r^3, 3 !), upright("3rd order")) + dots.h.c #scale(x: 180%, y: 180%)[}] $ 이러한 표현은 무한차원으로 확장 가능하며, Gaussian kernel이 무한차원에서의 유사도를 찾을 수 있게 해준다.

물론 커널 기반 방법도 커널을 먼저 정해줘야 하며, cross-validation 등을 이용해 커널 함수를 정하거나 또는 커널에 쓰이는 조율모수를 정하게 된다.

#part[Robust and Quantile Regression]
= Robust Regression
<robust-regression>
== Robust statistics
<robust-statistics>
#strong[Q]. $F$가 오염이 되었을 때 우리가 생각하는 추정량 $hat(theta)$가 얼마나 영향을 받을 것인가?

- Contaminated distribution function: $ F_epsilon = epsilon delta_y + \( 1 - epsilon \) F $

  where

  - $delta_y$: mass 1 to the point $y$

  - $F$: a distribution function

- Influence function of $hat(theta)$ at $F$:

  $ I F_(hat(theta)) \( y \, F \) = lim_(epsilon arrow.r 0) frac(hat(theta) \( F_epsilon \) - hat(theta) \( F \), epsilon) $

== Robust Regression
<robust-regression-1>
- #strong[Robust regression]: 잡음성이 많은 자료에 사용

= Quantile Regression
<quantile-regression>
== Check loss function
<check-loss-function>
- Check loss function #math.equation(block: true, numbering: equation-numbering, [ $ rho_tau \( u \) = u \( tau - I \( u < 0 \) \) $ ])<eq-qr-check>

#figure([
#box(image("quantreg_files/figure-typst/unnamed-chunk-1-1.svg", alt: "Figure: Check loss function.", width: 70%))
], caption: figure.caption(
position: bottom, 
[
Figure: Check loss function.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


- Loss function: 값이 클수록 손실이 많음
  - $tau < 0.5$: $rho_tau \( u \)$는 $u < 0$일 때 큰 가중치
  - $tau > 0.5$: $rho_tau \( u \)$는 $u > 0$일 때 큰 가중치
- $rho_tau \( u \)$는 $u = 0$에서 미분 불가능

== Estimation
<estimation>
- Objective function #math.equation(block: true, numbering: equation-numbering, [ $ R \( beta \) = sum_(i = 1)^n rho_tau \( y_i - x_i^T bold(beta) \) = sum_(i = 1)^n #scale(x: 120%, y: 120%)[{] tau \| epsilon_i \| I \[ epsilon_i gt.eq 0 \] + \( 1 - tau \) \| epsilon_i \| I \[ epsilon_i < 0 \] #scale(x: 120%, y: 120%)[}] $ ])<eq-qr-objective>

- Directional derivative of $R$ in direction $w$: $ nabla R \( bold(beta) \, w \) & = frac(d, d t) R \( bold(beta) + t w \) \|_(t = 0)\
   & = frac(d, d t) $

== Quantile regression as a linear programming
<quantile-regression-as-a-linear-programming>
- Linear program: solving $ min_(upright(bold(z))) upright(bold(c))^T upright(bold(z)) quad  upright("subject to ") A upright(bold(z)) = upright(bold(b)) \, upright(bold(z)) gt.eq 0 $

- 선형계획 문제를 풀 때는 $upright(bold(z))$ 부분에 해당하는 값이 양수여야 함. 따라서 분위수 회귀문제를 선형계획으로 풀려면 다음과 같이 $epsilon_i$를 slack variable을 이용해 양수와 음수 파트로 나눠야 함. $ epsilon_i = u_i - v_i $

  이떄

  - $u_i = max \( 0 \, epsilon_i \) = \| epsilon_i \| I \[ epsilon_i gt.eq 0 \]$
  - $v_i = max \( 0 \, - epsilon_i \) = \| epsilon_i \| I \[ epsilon_i < 0 \]$

- Then $ sum_(i = 1)^n rho_tau \( epsilon_i \) = sum_(i = 1)^n tau u_i + \( 1 - tau \) v_i = tau upright(bold(1))_n^T upright(bold(u)) + \( 1 - tau \) upright(bold(1))_n^T upright(bold(v)) $ 여기에서 $upright(bold(u)) = \( u_1 \, dots.h \, u_n \)^T$, $upright(bold(v)) = \( v_1 \, dots.h \, v_n \)^T$이다.

- Quantile regression objective function (#ref(<eq-qr-objective>, supplement: [Equation])) may be reformulated as a linear program: $ min_(bold(beta) \, upright(bold(u)) \, upright(bold(v))) { tau upright(bold(1))_n^T upright(bold(u)) + \( 1 - tau \) upright(bold(1))_n^T upright(bold(v)) \| upright(bold(y)) = upright(bold(X)) bold(beta) + upright(bold(u)) - upright(bold(v)) } $

- 알고리즘

  - Simplex method

  - Frisch-Newton interior point method

  - Sparse regression quantile fitting

=== R 코드
<r-코드>
- #link("https://stats.stackexchange.com/questions/384909/formulating-quantile-regression-as-linear-programming-problem")[출처: stackexchange]

== Quantile crossing
<quantile-crossing>
- 분위수 회귀는 기본적으로 각 $tau$에 대해 따로 회귀모형을 적합하는 방식이기 때문에 낮은 $tau$에서의 조건부 분위수 추정값이 높은 $tau$에서의 조건부 분위수 추정값보다 높은 역전 현상이 발생할 수도 있는데, 이를 #strong[quantile crossing]이라 함

- Quantile crossing을 막으려면 한 번에 conditional distribution 전체를 모델링 해야 하고, GAMLSS 등이 그런 방법을 취하고 있으나, 분포가정을 해야 함

#part[Linear Model Asymptotics]
= Asymptotic Theory for Least Squares
<asymptotic-theory-for-least-squares>
기본적인 내용은 #cite(<Hansen2022>, form: "prose") 를 따른다.

#theorem(title: "Random sampling assumption")[
The variables $\( Y_i \, X_i \)$ are a #strong[random sample] if they are mutually independent and identically distributed (i.i.d.) across $i = 1 \, dots.h \, n$.

] <thm-rss>
#theorem(title: "Best linear predictor 관련 assumption")[
~

+ $E \[ Y^2 \] < oo$
+ $E parallel X parallel^2 < oo$
+ $Q_(X X) = E \[ X X^T \]$ is positive definite

이 가정의 처음 두 개는 $X$, $Y$가 유한한 평균과 분산, 공분산을 갖음을 의미한다. 세 번째는 $Q_(X X)$의 column들이 linearly independent하고 역행렬이 존재함을 보장한다.

\($Q_(X X)$가 positive definite일 때 linearly independence는 찾아볼 것)

] <thm-blp>
위의 random sampling과 finite second moment assumption을 가져간채로 least squares estimation에 대한 assumption을 다시 정리한다. (#cite(<Hansen2022>, form: "prose") Assumption 7.1)

+ The variables $\( Y_i \, X_i \)$, $i = 1 \, dots.h \, n$ are i.i.d.
+ $E \[ Y^2 \] < oo$.
+ $E parallel X parallel^2 < oo$.
+ $Q_(X X) = E \[ X X^T \]$ is positive definite.

== Consistency of Least Squares Estimator
<consistency-of-least-squares-estimator>
이 절의 목표는 $hat(beta)$가 $beta$에 consistent함을

+ weak law of large numbers (WLLN)
+ continuous mapping theorem (CMT)

을 이용해 보이는 것이다. (#cite(<Hansen2022>, form: "prose") 7.2)

Derivation을 다음과 같은 요소들로 구성된다.

+ OLS estimatior가 sample moment들의 집합의 연속함수로 표현될 수 있다.
+ WLLN을 이용해 sample moments가 population moments에 converge in probability함을 보인다.
+ CMT를 이용해 연속함수에서 converges in probability가 보존됨을 보장한다

그렇다면 먼저 OLS estimator를 다음과 같이 sample moments $hat(Q)_(X X) = 1 / n sum_(i = 1)^n X_i X_i^T$와 $hat(Q)_(X X) = 1 / n sum_(i = 1)^n X_i Y_i$의 함수로 쓸 수 있다.

$ hat(beta) = #scale(x: 180%, y: 180%)[\(] 1 / n sum_(i = 1)^n X_i X_i^T #scale(x: 180%, y: 180%)[\)]^(- 1) #scale(x: 180%, y: 180%)[\(] 1 / n sum_(i = 1)^n X_i Y_i #scale(x: 180%, y: 180%)[\)] = hat(Q)_(X X)^(- 1) hat(Q)_(X Y) $

$\( Y_i \, X_i \)$가 mutually i.i.d. 라는 가정은 $\( Y_i \, X_i \)$로 구성된, 예를 들면 $X_i X_i^T$와 $X_i Y_i$가 i.i.d.임을 의미한다. 이들은 또한 앞선 Assumption 7.1에 의해 finite expectation을 갖는다. 이러한 조건 하에서, $n arrow.r oo$일 때 WLLN은

#math.equation(block: true, numbering: equation-numbering, [ $ hat(Q)_(X X) = 1 / n sum_(i = 1)^n X_i X_i^T arrow.r^p E \[ X X^T \] = Q_(X X) \, quad  hat(Q)_(X Y) = 1 / n sum_(i = 1)^n X_i Y_i arrow.r^p E \[ X Y \] = Q_(X Y) . $ ])<eq-Hansen0701>

그 다음 continuous mapping theorem을 써서 $hat(beta) arrow.r beta$임을 보일 수 있다는 것이다. $n arrow.r oo$일 때,

$ hat(beta) = hat(Q)_(X X)^(- 1) hat(Q)_(X Y) arrow.r^p Q_(X X)^(- 1) Q_(X Y) = beta . $

Stochastic order notation으로 다음과 같이 쓸 수 있다.

#math.equation(block: true, numbering: equation-numbering, [ $ hat(beta) = beta + o_p \( 1 \) . $ ])<eq-Hansen0704>

== Asymptotic Normality
<asymptotic-normality>
Asymptotic normality를 다룰 때에는

+ 먼저 estimator를 sample moment의 함수로 쓰는 것으로부터 시작한다.
+ 그리고 그것들 중 하나가 zero-mean random vector의 sum으로 표현될 수 있고 이는 CLT를 적용 가능케 한다.

우선 $hat(beta) - beta = hat(Q)_(X X)^(- 1) hat(Q)_(X e)$라고 두자. 그리고 이를 $sqrt(n)$에 곱하면 다음 표현을 얻을 수 있다.

#math.equation(block: true, numbering: equation-numbering, [ $ sqrt(n) \( hat(beta) - beta \) = #scale(x: 180%, y: 180%)[\(] 1 / n sum_(i = 1)^n X_i X_i^T #scale(x: 180%, y: 180%)[\)]^(- 1) #scale(x: 180%, y: 180%)[\(] 1 / sqrt(n) sum_(i = 1)^n X_i e_i #scale(x: 180%, y: 180%)[\)] . $ ])<eq-Hansen0705>

즉 normalized and centered estimator $sqrt(n) \( hat(beta) - beta \)$는 (1) sample average의 함수 $#scale(x: 180%, y: 180%)[\(] 1 / n sum_(i = 1)^n X_i X_i^T #scale(x: 180%, y: 180%)[\)]^(- 1)$과 normalized sample average $#scale(x: 180%, y: 180%)[\(] 1 / sqrt(n) sum_(i = 1)^n X_i e_i #scale(x: 180%, y: 180%)[\)]$의 곱으로 쓸 수 있다.

그러면 뒷부분은 $E \[ X e \] = 0$이고 이것의 $k times k$ 공분산함수를 다음과 같이 둘 수 있다. $ Omega = E \[ \( X e \) \( X e \)^T \] = E \[ X X^T e^2 \] . $ 그리고 아래 가정에서처럼 $Omega < oo$라는 가정 하에 $X_i e_i$는 i.i.d. mean zero, 유한한 분산을 갖고 CLT에 의해 $ 1 / sqrt(n) sum_(i = 1)^n X_i e_i arrow.r^d cal(N) \( 0 \, Omega \) . $

\(#cite(<Hansen2022>, form: "prose") Assumption 7.2)

+ The variables $\( Y_i \, X_i \) \, i = 1 \, dots.h \, n$ are i.i.d.
+ $E \[ Y^4 \] < oo$.
+ $E parallel X parallel^4 < oo$.
+ $Q_(X X) = E \[ X X^T \]$ is positive definite.

여기서 두 번째 조건이 $Omega < oo$임을 의미한다. $Omega < oo$임을 보이려면 $j l$번째 원소 $E \[ X_j X_l e^2 \]$이 유한함을 보이면 될 것이다. Properties of Linear Projection Model (#cite(<Hansen2022>, form: "prose") Theorem 2.9.6) (If $E \| Y \|^r < oo$ and $E \| X \|^r < oo$ for $r gt.eq 2$, then $E \| e \|^r < oo$)을 이용해 위의 2, 3번 조건에 의해 $E \[ e^4 \] < oo$임을 보일 수 있다. 그러면 expectation inequality에 의해 $Omega$의 $j l$번째 원소는 다음과 같이 bounded된다. $ \| E \[ X_j X_l e^2 \] \| lt.eq E \| X_j X_l e^2 \| = E \[ \| X_j \| \| X_l \| e^2 \] . $ Cauchy-Schwarz 부등식을 적용하면 다음과 같다. $ \( E \[ X_j^2 X_ell^2 \] \)^(1 \/ 2) \( E \[ e^4 \] \)^(1 \/ 2) lt.eq \( E \[ X_j^4 \] \)^(1 \/ 4) \( E \[ X_ell^4 \] \)^(1 \/ 4) \( E \[ e^4 \] \)^(1 \/ 2) < oo . $

#theorem()[
앞선 가정은 $ Omega < oo $ 를 내포하고 #math.equation(block: true, numbering: equation-numbering, [ $ 1 / sqrt(n) sum_(i = 1)^n X_i e_i arrow.r^d cal(N) \( 0 \, Omega \) $ ])<eq-Hansen0707> as $n arrow.r oo$.

] <thm-finitecov>
식 #ref(<eq-Hansen0701>, supplement: [Equation]) , #ref(<eq-Hansen0705>, supplement: [Equation]) , #ref(<eq-Hansen0707>, supplement: [Equation]) 을 함께 쓰면 다음과 같다. $ sqrt(n) \( hat(beta) - beta \) arrow.r^d upright(bold(Q))_(X X)^(- 1) cal(N) \( 0 \, Omega \) = cal(N) \( 0 \, upright(bold(Q))_(X X)^(- 1) Omega upright(bold(Q))_(X X)^(- 1) \) quad  upright("as ") n arrow.r oo . $ 여기서 마지막 등식은 normal vector의 linear combination이 normal이라는 것에서부터 왔다.

#theorem(title: "Asymptotic normality of least squares estimator")[
앞선 가정 하에서, $n arrow.r oo$일 때 $ sqrt(n) \( hat(beta) - beta \) arrow.r^d cal(N) \( 0 \, upright(bold(V))_beta \) $ where $upright(bold(Q))_(X X) = E \[ X X^T \]$, $Omega = E \[ X X^T e^2 \]$, and $ upright(bold(V))_beta = upright(bold(Q))_(X X)^(- 1) Omega upright(bold(Q))_(X X)^(- 1) . $

] <thm-asymnormalls>
Stochastic order notation으로 다음과 같이 쓸 수 있다. $ hat(beta) = beta + O_p \( n^(- 1 \/ 2) \) . $ 이는 식 #ref(<eq-Hansen0704>, supplement: [Equation]) 보다 더 강한 조건이라고 한다.

#block[
#callout(
body: 
[
- 원래 $o_p$가 더 강한조건이긴 하나 order의 차이가 나서 저렇게 말하는 듯

]
, 
title: 
[
Remark
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
- $upright(bold(V))_beta$: #strong[asymptotic covariance matrix] of $hat(beta)$, $ upright(bold(V))_beta = upright(bold(Q))_(X X)^(- 1) Omega upright(bold(Q))_(X X)^(- 1) $ 이며 $sqrt(n) \( hat(beta) - beta \)$의 asymptotic distribution의 variance

#block[
#callout(
body: 
[
- $upright(bold(V))_beta$의 형태를 보면 $Omega$가 $upright(bold(Q))_(X X)^(- 1)$ 사이에 끼어있는 형태이므로 #strong[sandwich] form이라고 부름

]
, 
title: 
[
Remark
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
= Asymptotic Theory for Quantile Regression
<asymptotic-theory-for-quantile-regression>
== Basics
<basics>
#strong[Check function]

$ rho_tau \( x \) = x \( tau - I { x < 0 } \) = cases(delim: "{", - x \( 1 - tau \) \, & x < 0, x tau \, & x gt.eq 0) . $

$ psi_tau \( x \) = frac(d, d x) rho_tau \( x \) = tau - I { x < 0 } \, quad  x eq.not 0 . $

#theorem(title: "Consistency of quantile regression estimator")[
Assume that $\( Y_i \, X_i \)$ are i.i.d., $E \| Y \| < oo$, $E \[ parallel X parallel^2 \] < oo$, $f_tau \( e \| x \)$ exists and satisfies $f_tau \( e \| x \) lt.eq D < oo$, and the parameter space for $beta$ is compact. For any $tau in \( 0 \, 1 \)$ such that $ upright(bold(Q))_tau =^(upright("def")) E \[ X X^T f_tau \( 0 \| X \) \] > 0 $ then $hat(beta)_tau arrow.r^p beta_tau$ as $n arrow.r oo$.

] <thm-consistencyqr>
#theorem(title: "Asymptotic distribution of quantile regression estimator")[
In addition to the assumptions of #ref(<thm-consistencyqr>, supplement: [Theorem]) , assume that $f_tau \( e \| x \)$ is continuous in $e$, and $beta_tau$ is in the interior of the parameter space. Then as $n arrow.r oo$ $ sqrt(n) \( hat(beta)_tau - beta_tau \) arrow.r^d cal(N) \( 0 \, upright(bold(V))_tau \) $ where $upright(bold(V))_tau = upright(bold(Q))_tau^(- 1) Omega_tau upright(bold(Q))_tau^(- 1)$ and $Q_tau = E \[ X X^T psi_tau^2 \]$ for $psi_tau = tau - I { Y < X^T beta_tau }$.

] <thm-asympdistnqr>
#part[Advanced Topics]
= Spatial Linear Models
<spatial-linear-models>
- Reference: #link("https://www.routledge.com/Spatial-Linear-Models-for-Environmental-Data/Zimmerman-VerHoef/p/book/9780367183349")[Spatial Linear Models for Environmental Data]

== Linear Model
<linear-model>
- A #strong[linear model] for a response variable $Y$ postulates that the response is related to the observed values of $p$ explanatory variables $X_1 \, dots.h \, X_p$ via this equation: $ Y = X_1 beta_1 + X_2 beta_2 + dots.h.c + X_p beta_p + e \, $ where

- $beta_1 \, dots.h \, beta_p$: (unknown) parameters (#strong[coefficients])

- $e$: a random variable (#strong[error])

- $X_1 beta_1 + X_2 beta_2 + dots.h.c + X_p beta_p$: mean structure

- When $n$ obs $\( y_1 \, bold(x)_1 \) \, dots.h \, \( y_(\,) bold(x)_n \)$ are taken on the response and explanatory variables, the linear model as just defined implied that $ y_i = bold(x)_i^T bold(beta) + e_i \, quad  \( i = 1 \, dots.h \, n \) $ where

- $bold(beta) = \( beta_1 \, dots.h \, beta_p \)^T$ and $e_1 \, dots.h \, e_n$ are $n$ possibly correlated random variables.

- Using vector and matrix notations: $ bold(y) = bold(X beta) + bold(e) . $

- $bold(e)$: #strong[error vector]

- $bold(Sigma)$: $upright("Var") \( bold(e) \)$

== Spatial Linear Model
<spatial-linear-model>
- A #strong[spatial linear model] is defined as a linear model for spatial data for which the elements of $bold(Sigma)$ are spatially structured functions of the data sites

=== Spatial Aitken Model
<spatial-aitken-model>
- The simplest spatial linear model is an extension of the Gauss-Markov model that we call the #strong[spatial Aitken model]: $ bold(Sigma) = sigma^2 bold(R) \, $ where

- $sigma^2$: an unknown positive parameter and

- $bold(R)$ is a #strong[known] positive definite matrix whose elements are spatially structured functions of the data sites. We refer to $bold(R)$ as the #strong[scale-free covariance matrix] of the observations; in some settings, but not all, it is a correlation matrix.

- Estimation: #strong[generalized least squares (GLS)]

#example(title: "A toy example of a spatial Aitken model")[
Consider four obs located at the corners of the unit square in $bb(R)^2$, ordered such that the first and last obs are located at opposite corners of the square. Suppose that the model for the obs is given by $ bold(R) = mat(delim: "(", 1, e^(- 1), e^(- 1), e^(- sqrt(2)); e^(- 1), 1, e^(- sqrt(2)), e^(- 1); e^(- 1), e^(- sqrt(2)), 1, e^(- 1); e^(- sqrt(2)), e^(- 1), e^(- 1), 1) $

] <exm-Aitken>
- #strong[Symmetric]

- #strong[Positive definiteness]: the variance of any linear combinations of obs having this cov matrix, expect the trivial linear combination with all coeffs equal to zero.

== Spatial General Linear Model
<spatial-general-linear-model>
- A more flexible spatial linear model

- $bold(Sigma)$ is not fully specified but is given by a #strong[known] spatially structured, matrix-valued parametric function $bold(Sigma) \( bold(theta) \)$, where $bold(theta)$ is an #strong[unknown] parameter vector.

- Joint parameter space for $bold(beta)$ and $bold(theta)$ generally taken to be $ { \( bold(beta) \, bold(theta) \) : bold(beta) in bb(R)^p \, bold(theta) in Theta subset bb(R)^m } $ where

- $Theta$: the set of vectors $bold(theta)$ for which $bold(Sigma) \( bold(theta) \)$ is symmetric and positive definite, or possibly some subset of that set.

#block[
#emph[Remark 9.1]. A spatial Aitken model is a special case of a spatial general linear model, with $bold(theta) equiv sigma^2$ and $bold(R)$ not functionally dependent on any unknown parameters.

] <rem-Aitken>
#example(title: "A toy example of a spatial Aitken model (2)")[
$ bold(Sigma) \( bold(theta) \) = sigma^2 mat(delim: "(", 1, e^(- 1 \/ alpha), e^(- 1 \/ alpha), e^(- sqrt(2) \/ alpha); e^(- 1 \/ alpha), 1, e^(- sqrt(2) \/ alpha), e^(- 1 \/ alpha); e^(- 1 \/ alpha), e^(- sqrt(2) \/ alpha), 1, e^(- 1 \/ alpha); e^(- sqrt(2) \/ alpha), e^(- 1 \/ alpha), e^(- 1 \/ alpha), 1) $

The parameter space for $bold(theta) equiv \( sigma^2 \, alpha \)^T$ within which $bold(Sigma) \( bold(theta) \)$ is p.d. is $ { \( sigma^2 \, alpha \) : sigma^2 > 0 \, alpha > 0 } $

Small values of $alpha$ correspond to weak spatial correlation among the obs, and as $alpha$ increases the spatial correlation among obs become stronger.

] <exm-Aitken2>
= Gaussian Processes
<gaussian-processes>
== Regression analysis
<regression-analysis-1>
- All finite collection of realizations ($n$ obs) is modeled as having a multivariate normal (MVN) distribution.

- #strong[Mean function]: $mu \( x \)$

- #strong[Covariance function]: $Sigma \( x \, x' \)$

- $Sigma \( x \, x' \) = exp { - parallel x - x' parallel^2 }$

- $Sigma \( x \, x \) = 1$

- $Sigma \( x \, x' \)$ must be #strong[positive definite]

- $Sigma_n$: covariance matrix (p.d.)

== Splines vs GP
<splines-vs-gp>
= PCA and Least Squares
<pca-and-least-squares>
== PCA as least squares problems
<pca-as-least-squares-problems>
PCA can be formulated as follows:

Given $m$ vectors $bold(x)_1 \, dots.h \, bold(x)_m in bb(R)^n$, find matrices $bold(U) in cal(M)_(bb(R)) \( k \, n \)$ and $bold(V) in cal(M)_(bb(R)) \( n \, k \)$ such that $ sum_(i = 1)^m parallel bold(x)_i - bold(V) bold(U) bold(x)_i parallel^2 $ is minimized.

That is, for $k < n$, the vector $bold(U) bold(x)_i in bb(R)^k$ is the projection of $bold(x)_i$ into a lower-dimensional subspace, and $bold(V) bold(U) bold(x)_i$ is the #strong[reconstructed] original vector. PCA aims to find matrices $bold(U)$, $bold(V)$ that minimize the reconstruction error as measured by the $ell^2$-norm. It can be shown that, in fact, these matrices are orthogonal and $bold(U) = bold(V)^T$, so the problem reduces to $ arg min_(V in cal(M)_(bb(R)) \( n \, k \)) sum_(i = 1)^m parallel bold(x)_i - bold(V) bold(V)^T bold(x)_i parallel^2 $ Further manipulations show that $bold(V)$ is the matrix whose columns are the eigenvectors corresponding to the $k$ largest eigenvalues of $ sum_(i = 1)^m bold(x)_i bold(x)_i^T $ as expected. So indeed, PCA is a least squares method and it is quite sensitive to outliers.

= Summary
<summary>
In summary, this book has no content whatsoever.

#block[
#Skylighting(([#DecValTok("1");#NormalTok(" ");#SpecialCharTok("+");#NormalTok(" ");#DecValTok("1");],));
#block[
#Skylighting(([#NormalTok("[1] 2");],));
]
]
#heading(level: 1, numbering: none)[References]
<references>
#block[
] <refs>



#bibliography(("references.bib"))

