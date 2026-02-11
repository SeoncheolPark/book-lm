#import "@preview/thmbox:0.2.0": *
//#import "@preview/cades:0.3.0": qr-code //qrcode
#import "@preview/scienceicons:0.1.0": email-icon, orcid-icon //icon
#import "@preview/statastic:1.0.0": *
#show: thmbox-init(counter-level: 1)

#let logo-title = image("images/hanyang.png", width: 30%, fit: "contain")
//#let logo = image("images/hanyang.png", height: 0.8em, fit: "contain")

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
#let theorem = thmbox.with(color: colors.dark-red, variant: translations.variant("theorem"))
/// Used for propositions, uses a light blue color by default.
#let proposition = thmbox.with(color: colors.light-blue, variant: translations.variant("proposition"))
/// Used for lemmas, uses a light turquoise color by default.
#let lemma = thmbox.with(color: colors.light-turquoise, variant: translations.variant("lemma"))
/// Used for corollaries, uses a pink color by default.
#let corollary = thmbox.with(color: colors.pink, variant: translations.variant("corollary"))
/// Used for definitions, uses an orange color by default.
#let definition = thmbox.with(color: colors.orange, variant: translations.variant("definition"))
/// Used for examples, uses a lime color and is not numbered by default.
#let example = thmbox.with(
  color: colors.lime, 
  variant: translations.variant("example"), 
  //numbering: none, 
  sans: false,
)
/// Used for notes, uses a turquoise color and is not numbered by default.
#let note = thmbox.with(
  color: colors.turquoise, 
  variant: translations.variant("note"), 
  //numbering: none, 
  sans: false,
)
/// Used for exercises, uses a blue color by default.
#let exercise = thmbox.with(
  color: colors.light-aqua, 
  variant: translations.variant("exercise"),
  //numbering: none,
  sans: false,
)
/// Used for algorithms, uses a purple color by default.
#let algorithm = thmbox.with(
  color: colors.purple, 
  variant: translations.variant("algorithm"), 
  sans: false,
)
/// Used for claims, uses a green color and is not numbered by default.
#let claim = thmbox.with(
  color: colors.green, 
  variant: translations.variant("claim"), 
  numbering: none,
)
/// Used for axioms, uses an aqua color by default.
#let axiom = thmbox.with(color: colors.aqua, variant: translations.variant("axiom"))
/// Used for remarks, uses a gray color and is not numbered by default.
#let remark = remark.with(
    color: colors.gray, 
    title: "Remark", 
    numbering: none, 
    sans: false,
)
// derive from some predefined function
#let solution = proof.with(
    //fill: rgb("#ffdcdc"), 
    title: "Solution", 
    color: dark-blue,
    //title-fonts: "Noto Sans",
    numbering: none
)
#let proof = proof.with(
    //fill: rgb("#ffdcdc"), 
    variant: translations.variant("proof"), 
    color: blue,
    numbering: none,
    //bar-thickness: 3pt,
    //fill: yellow.lighten(100%),
    //title-font: "Noto Sans",
    inset: (x: 0pt, y: 0em)
)
#let assumption = thmbox.with(
    //fill: rgb("#ffdcdc"), 
    variant: "Assumption", 
    color: dark-gray
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

//diatypst 0.5.0 lib.typ file
#let layouts = (
  "small": ("height": 9cm, "space": 1.4cm),
  "medium": ("height": 10.5cm, "space": 1.6cm),
  "large": ("height": 12cm, "space": 1.8cm),
)

#let lecture(
  title: [],
  subtitle: [],
  authors: (),
  date: none,
  //date: datetime.today().display(),
  department: none,
  institution: none,
  email: none,
  titlemessage: none,
  ratio: 16/9,
  logo: "images/hanyang.png",
  logo-small: "images/hanyang_mini.png",
  qrurl: none,
  abstract: [],
  column: 1,
  lecturetype: "note",//밑에서부터는 slide용
  theme: "full",
  firstlevelheading: true,
  footer-title: none,
  footer-subtitle: none,
  layout: "medium",
  title-font: "IBM Plex Sans",//"Manrope", //"IBM Plex Sans"//"Manrope",//"HK Grotesk", "Manrope", "inter"
  title-color: none,
  main-font: "IBM Plex Sans",//IBM Plex Sans
  count: "number",
  footer: true,
  toc: true, //TOC는 note에서도 가능케 함
  content,
) = if lecturetype=="note"{
  // Set and show rules from before.
  set page(
    paper: "a4",
    margin: (
      top: 2.8cm,
      bottom: 2.8cm,
      left: 1.4cm,
      right: 1.4cm,
    ),
    header:  context [
      #grid(
        columns: (460pt, 1fr, 1fr),
        align: (left, right),
        [
          #set text(11.5pt, font: main-font, weight: "bold")
          #title
        ], 
        [
          //#figure(
            //#image(logo, width:275%, fit:"contain"),
        //)
        #figure(
            image(logo, width:275%, fit:"contain"),
        )
        ],
      )
    ],
    footer: context [
      #set text(11.5pt, font: main-font, weight: "bold")
      #authors
      #h(1fr)
      #counter(page).display(
        "1",
      )
    ],
   
    columns: column,
  )

  // 제목 달기
  place(
  top + center,
  scope: "parent",
  float: true,
  text(19.5pt, weight: "bold", font: main-font)[
    #title
  ],
  )

   place(
  top + center,
  scope: "parent",
  float: true,
  text(11pt, weight: "regular", font: main-font)[
    #authors
  ],
  )


  //let count = authors.len()
  //let ncols = calc.min(count, 3)
  //grid(
   // columns: (1fr,) * ncols,
   // row-gutter: 24pt,
   // ..authors.map(author => [
    //  #author.name \
    //  //#author.affiliation \
    //  //#link("mailto:" + author.email)
    //]),
  //)

  //par(justify: true)[
  //  *Abstract* \
  //  #abstract
  //]

  set heading(numbering: "1.1")

  //(SC) eqn 등
  set math.equation(numbering: n => {
    numbering("(1)", n)
  }, supplement: [])
  show ref: it => {
    // provide custom reference for equations
    if it.element != none and it.element.func() == math.equation {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#link(it.target)[#it]]
    } else if  it.element != none and it.element.func() != math.equation {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#link(it.target)[#it]]
    } else {
      it
    }
  }
  show link: it => {
    if type(it.dest) != str { // Local Links
      it
    }
    else {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#it]
      //underline(stroke: 1pt+fuchsia)[#it] // Web Links
    }
  }
  
  set text(
    font: main-font,
    size: 11pt,
  )

  if toc==true{
    outline()
  }

  /*(SC) Figures*/
  show figure.caption: it => {
    set align(left)
    it
  }
  
  set align(left)
  content
}else if lecturetype=="note-horiz"{
  // Set and show rules from before.
  set page(
    paper: "presentation-16-9",
    margin: (
      top: 1.8cm,
      bottom: 1.0cm,
      left: 0.6cm, //(SC) orig: 1.0cm
      right: 0.6cm, //(SC) orig: 1.0cm
    ),
    header:  context [
      #grid(
        columns: (800pt, 1fr, 1fr), //(SC) orig: 780pt
        align: (left, right),
        [
          #set text(9.5pt, font: main-font, weight: "bold") //(SC) orig: 9.5pt
          #subtitle\
          #title//\
        ], 
        [
          //#figure(
            #image(logo, width: 2000%, fit:"contain") //(SC) orig: 4000%
        //)
        ],
      )
    ],
    footer: context [
      #set text(9.5pt, font: main-font, weight: "bold") //(SC) orig: 11.5pt
      #authors
      #h(1fr)
      #counter(page).display(
        "1",
      )
    ],
   
    columns: column,
  )

  // 제목 달기
  place(
  top + center,
  //scope: "parent",
  float: true,
  text(15.5pt, weight: "bold", font: main-font)[
    #title//#subtitle
  ],
  ) //(SC) orig: 19.5pt

   place(
  top + center,
  //scope: "parent",
  float: true,
  text(9pt, weight: "regular", font: main-font)[
    #authors
  ],
  )

  show figure.caption: it => {
    set align(left)
    it
  }

  //let count = authors.len()
  //let ncols = calc.min(count, 3)
  //grid(
   // columns: (1fr,) * ncols,
   // row-gutter: 24pt,
   // ..authors.map(author => [
    //  #author.name \
    //  //#author.affiliation \
    //  //#link("mailto:" + author.email)
    //]),
  //)

  //par(justify: true)[
  //  *Abstract* \
  //  #abstract
  //]

  set heading(numbering: "1.1")

  //(SC) eqn 등
  set math.equation(numbering: n => {
    numbering("(1)", n)
  }, supplement: [])
  show ref: it => {
    // provide custom reference for equations
    if it.element != none and it.element.func() == math.equation {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#link(it.target)[#it]]
    } else if  it.element != none and it.element.func() != math.equation {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#link(it.target)[#it]]
    } else {
      it
    }
  }
  show link: it => {
    if type(it.dest) != str { // Local Links
      it
    }
    else {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#it]
      //underline(stroke: 1pt+fuchsia)[#it] // Web Links
    }
  }
  
  set text(
    font: main-font,
    size: 9pt, //(SC) orig: 11pt
  )

  set align(left)
  content
}else if lecturetype=="slide"{

  // Parsing
  if layout not in layouts {
      panic("Unknown layout " + layout)
  }
  let (height, space) = layouts.at(layout)
  let width = ratio * height

  if count not in (none, "dot", "number") {
    panic("Unknown Count, valid counts are 'dot' and 'number', or none")
  }

  // Colors
  if title-color == none {
      title-color = default-color.darken(0%)
  }
  let block-color = title-color.lighten(90%)
  let body-color = title-color.lighten(80%)
  let header-color = title-color.lighten(65%)
  let fill-color = title-color.lighten(50%)

  // Setup
  set document(
    title: title,
    author: authors,
    //author: authors.map(author => author.name)
  )
  //set heading(numbering: "1.1")
  set heading(numbering: none)

  // PAGE----------------------------------------------
  set page(
    width: width,
    height: height,
    margin: (x: 0.5 * space, top: 0.8 * space, bottom: 0.6 * space),
  // HEADER
    header: [
      #context {
        let page = here().page()
        let headings = query(selector(heading.where(level: 2)))
        //let headings = query(selector(heading.where(level: 2)).or(selector(heading.where(level: 1))))
        let heading = headings.rev().find(x => x.location().page() <= page)

        if heading != none {
          set align(top)

          if (theme == "full") {
            block(
              width: 100%,
              fill: supp-color,
              height: space * 0.625,
              outset: (x: 0.5 * space)
            )[
              #set text(2em, font: title-font, weight: "bold", fill: title-color)
              #v(space / 8)
              #heading.body
              #if not heading.location().page() == page [
                (cont.)
              ]
            ]
          } else if (theme == "normal") {
            set text(2em, font: title-font, weight: "bold", fill: title-color)
            //v(space / 2)
            v(space / 8)
            heading.body
            if not heading.location().page() == page [
              (cont.)
              /*#{numbering("(i)", page - heading.location().page() + 1)}*/
            ]
          }
        }
    }    
    #place(
      top + right,
      /*dx: 5pt,
      dy: 10pt,*/
      dx: 2pt,
      dy: 4pt,
      //figure(
            image(logo-small, width:4%, fit:"contain"),
        //)
    )
  // COUNTER
  /*
    #if count == "dot" {
      //v(-space / 1.5)
      v(-space / 1.15)
      set align(right + top)
      context {
        let last = counter(page).final().first()
        let current = here().page()
        // Before the current page
        for i in range(1,current) {
          link((page:i, x:0pt,y:0pt))[
            #box(circle(radius: 0.08cm, fill: fill-color, stroke: 1pt+fill-color))
          ]
        }
        // Current Page
        link((page:current, x:0pt,y:0pt))[
            #box(circle(radius: 0.08cm, fill: fill-color, stroke: 1pt+fill-color))
          ]
        // After the current page
        for i in range(current+1,last+1) {
          link((page:i, x:0pt,y:0pt))[
            #box(circle(radius: 0.08cm, stroke: 1pt+fill-color))
          ]
        }
      }
    } else if count == "number" {
      //v(-space / 1.5)
      v(-space / 1.15)
      set align(right + top)
      context {
        let last = counter(page).final().first()
        let current = here().page()
        set text(weight: "bold", font: "Noto Sans CJK KR")
        set text(fill: white, font: "Noto Sans CJK KR") 
        set text(fill: title-color, font: "Noto Sans CJK KR")
        [#current / #last]
      }
    }*/
    ],
    header-ascent: 0%,
  // FOOTER
    footer: [
      #if footer == true {
        context{
          let last = counter(page).final().first()
          let current = here().page()
          let ratio = current/last

          set text(0.7em)
          // Colored Style
          box()[#line(length: ratio * 100%, stroke: 2pt+fill-color )]
          box()[#line(length: (1-ratio) * 100%, stroke: 2pt+body-color)]
        }
        
        set text(0.7em)
        //// Colored Style
        //box()[#line(length: 50%, stroke: 2pt+fill-color )]
        //box()[#line(length: 50%, stroke: 2pt+body-color)]
        v(-0.3cm)
        grid(
          columns: (1fr, 1fr),
          align: (left,right),
          inset: (y: 4pt),
          [#smallcaps()[
            #if footer-title != none {
              set text(font: title-font, weight: "semibold")
              footer-title} else {
                set text(font: title-font, weight: "semibold", fill: title-color)
                title}]],
          [// COUNTER
          #if count == "dot" {
            //v(-space / 1.5)
            //v(-space / 1.15)
            set align(right + top)
            context {
              let last = counter(page).final().first()
              let current = here().page()
              // Before the current page
              for i in range(1,current) {
                link((page:i, x:0pt,y:0pt))[
                  #box(circle(radius: 0.08cm, fill: fill-color, stroke: 1pt+fill-color))
                ]
              }
              // Current Page
              link((page:current, x:0pt,y:0pt))[
                  #box(circle(radius: 0.08cm, fill: fill-color, stroke: 1pt+fill-color))
                ]
              // After the current page
              for i in range(current+1,last+1) {
                link((page:i, x:0pt,y:0pt))[
                  #box(circle(radius: 0.08cm, stroke: 1pt+fill-color))
                ]
              }
            }
          } else if count == "number" {
            //v(-space / 1.5)
            //v(-space / 1.15)
            set align(right + top)
            context {
              let last = counter(page).final().first()
              let current = here().page()
              set text(weight: "semibold", fill: title-color, font: title-font)
              //set text(fill: white, font: "Noto Sans CJK KR") 
              //set text(fill: title-color, font: "Noto Sans CJK KR")
              [#current / #last]
            }
          } else if footer-subtitle != none {
              set text(font: title-font, weight: "semibold", fill: title-color)
              footer-subtitle
          } else if subtitle != none {
              set text(font: main-font, weight: "semibold", fill: title-color)
              subtitle
          } else if authors != none {
                if (type(authors) != array) {authors = (authors,)}
                set text(font: title-font, weight: "semibold", fill: title-color)
                authors.join(", ", last: " and ")
              } else [#date]
          ],
        )
      }
    ],
    footer-descent:0.3*space,
  )


  // SLIDES STYLING--------------------------------------------------
  // Section Slides

  
  show heading.where(level: 1): x => {
    set page(header: none,footer: none, margin: 0cm)
    set align(horizon)
    //  grid(
    //    columns: (1fr, 3fr),
    //    inset: 10pt,
     //   align: (right,left),
    //    fill: (title-color, white), //왼쪽을 바꾸면 색칠하게 됨
    //    [#block(height: 100%)],[#text(1.2em, font: "Noto Sans CJK KR", weight: "bold", fill: title-color)[#x]]
    //  )
    if firstlevelheading==true {
      context{
        let last = counter(page).final().first() 
        let current = here().page() 
        let ratio = current/last 
        block(
          inset: (x:0.5*space, y:7em),
          fill: white, //Presentation 위쪽 색칠
          width: 100%,
          height: 50%,
          [#set align(center)
          #text(1.25em, font: title-font, weight: "bold", fill: title-color, [#x])] + v(30pt) +
          //set text(0.7em) +
          // Colored Style
          box()[#line(length: ratio * 100%, stroke: 2pt+fill-color )] +
          box()[#line(length: (1-ratio) * 100%, stroke: 2pt+body-color)]
        )
      }
    }
    place(
      top + right,
      /*dx: 5pt,
      dy: 10pt,*/
      dx: -20.7pt,
      dy: 4pt,
      //figure(
            image(logo-small, width:3.65%, fit:"contain"),
        //)
    )
  }

  
  show heading.where(level: 2): pagebreak(weak: true) // this is where the magic happens
  //show heading.where(level: 2).or(heading.where(level: 1)): pagebreak(weak: true) // this is where the magic happens
  show heading: set text(1.5em, font: title-font, fill: title-color) //subsubsection


  // ADD. STYLING --------------------------------------------------
  // Terms
  show terms.item: it => {
    set block(width: 100%, inset: 5pt)
    stack(
      block(fill: header-color, radius: (top: 0.2em, bottom: 0cm), strong(it.term)),
      block(fill: block-color, radius: (top: 0cm, bottom: 0.2em), it.description),
    )
  }

  // Code
  /*
  show raw.where(block: false): it => {
    box(fill: block-color, inset: 1pt, radius: 1pt, baseline: 1pt)[#text(size:8pt ,it)]
  }

  show raw.where(block: true): it => {
    block(radius: 0.5em, fill: block-color,
          width: 100%, inset: 1em, it)
  }
  */

  // Bullet List
  show list: set list(marker: (
    text(fill: title-color)[•],
    text(fill: title-color)[‣],
    text(fill: title-color)[-],
  ))

  // Enum
  let color_number(nrs) = text(fill:title-color)[*#nrs.*]
  set enum(numbering: color_number)

  // Table
  show table: set table(
    stroke: (x, y) => (
      //x: none,
      x: 0.8pt+black,
      bottom: 0.8pt+black,
      top: if y == 0 {0.8pt+black} else if y==1 {0.4pt+black} else { 0.4pt+silver },
      //top: if y == 0 {0.8pt+black} else if y==1 {0.4pt+black} else { 0pt },
    )
  )

  show table.cell.where(y: 0): set text(
    style: "normal", weight: "bold", font: main-font) // for first / header row

  set table.hline(stroke: 0.4pt+black)
  set table.vline(stroke: 0.4pt)

  // Quote
  set quote(block: true)
  show quote.where(block: true): it => {
    v(-5pt)
    block(
      fill: block-color, inset: 5pt, radius: 1pt,
      stroke: (left: 3pt+fill-color), width: 100%,
      outset: (left:-5pt, right:-5pt, top: 5pt, bottom: 5pt)
      )[#it]
    v(-5pt)
  }

  // Outline
  set outline(
    target: heading.where(level: 1).or(heading.where(level:2)),
    indent: auto,
  )

  /*(SC)*/
  show outline.entry: it => link(
    it.element.location(),
    // Keep just the body, dropping
    // the fill and the page.
    it.indented(it.prefix(), it.body()),
  )

  /*(SC) Figures*/
  show figure.caption: it => {
    set align(left)
    it
  }
  //https://forum.typst.app/t/figure-and-table-captions-with-chapter-number/1520

  show outline: set heading(level: 2) // To not make the TOC heading a section slide by itself

  // Bibliography
  set bibliography(
    title: none
  )


  // CONTENT---------------------------------------------
  // Title Slide
  if (title == none) {
    panic("A title is required")
  }
  else {
    if (type(authors) != array) {
      authors = (authors,)
    }
    set page(footer: none, margin: (
      top: 1*space,
      bottom: 0cm,
      left: 0cm,
      right: 0cm,
    ),
    header: place(
      top + center,
      dx: 189pt,
      dy: 10pt,
      //figure(
            image(logo, width:20%, fit:"contain"),
        //)
    )
  )
    block(
      inset: (x:0.5*space, y:1em),
      fill: white, //Presentation 위쪽 색칠
      width: 100%,
      height: 50%,
      [#text(2.5em, font: title-font, weight: "bold", fill: title-color, title)] +
      if subtitle != [] { text(1.4em, font: main-font)[ \ ] } + v(-5pt) +
      if subtitle != none {[
        #text(1.4em, font: title-font, fill: title-color, weight: "bold", subtitle)
      ]} else {[
        //#text(1em, font: title-font, fill: title-color, weight: "bold", " ")
      ]}  + v(-5pt) +
      align(center)[#line(length: 100%, stroke: 2pt+fill-color )]
    )
    // Try to auto-size the column block.
    // It's not perfect
    block(
      height: 30%,
      width: 100%,
      inset: (x:0.5*space,top:-0.75cm, bottom: 1em),
      if date != none {text(1.1em, font: title-font, date, weight: "bold")} +
      if authors != none { text(1.4em, font: main-font)[ \ ] } +
      if authors != none { text(1.1em, authors.join(", ", last: " & "), font: title-font, weight: "bold")} + 
      if department != none { text(1.4em, font: main-font)[ \ ] } +
      if department != none {text(1.1em, font: title-font, department, weight: "bold")} + 
      if institution != none { text(1.4em, font: main-font)[ \ ] } +
      if institution != none {text(1.1em, font: title-font, institution, weight: "bold")} +
      if email != none { text(1.4em, font: main-font)[ \ ] } +
      if email != none { 
                set text(1.1em, font: title-font, weight: "bold")
                email-icon(color: title-color, height: 1.0em, baseline: 20%) + link("mailto:", email)} +
      if titlemessage != none { text(1.4em, font: main-font)[ \ ] } +
      if titlemessage != none {
        //text(0.8em, font: title-font, titlemessage, weight: "bold")
        grid(
          columns: (7fr, 3fr),
          rows: (auto, auto),
          gutter: (),
          [#v(-0.55em)
          #text(0.8em, font: title-font, titlemessage, weight: "bold")],
          [],
        )
      }
      //)
      /*for i in range(calc.ceil(authors.len() / 3)) {
        let end = calc.min((i + 1) * 3, authors.len())
        let is-last = authors.len() == end
        let slice = authors.slice(i * 3, end)
        grid(
          columns: slice.len() * (1fr,),
          gutter: -15em,
          ..slice.map(author => align(center, {
            set text(font: title-font)
            set align(left)
            text(size: 1.2em, author.name, weight: "semibold")
            if "department" in author [
              \ #emph(author.department)
            ]
            if "organization" in author [
              \ #emph(author.organization)
            ]
            if "location" in author [
              \ #author.location
            ]
            if "email" in author {
              if type(author.email) == str [
                \ #email-icon(color: title-color, height: 1.0em, baseline: 20%) #link("mailto:" + author.email)
              ] else [
                \ #author.email 
              ]
            }
          }))
        )

        if not is-last {
          v(16pt, weak: true)
        }
      }*/
    )
    if(qrurl!=none){
      place(
      top + center,
      dx: 199pt,
      dy: 138pt,
      qr-code(qrurl, width: 3cm)
      //figure(
      //      image(qrurl, width:16%, fit:"contain"),
      //  ),
      )
    }
  }
    
  // Outline
  show outline.entry.where(
  level: 1
  ): it => {
    v(1em, weak: true)
    strong(it)
  }
  if (toc == true) {
    set page(columns: 2)
    set text(1em, font: main-font)
    outline()
  }
  // Normal Content
  set page(columns: column) //내가 넣음
  set text(1em, font: main-font)

  //(SC) eqn 등
  set math.equation(numbering: n => {
    numbering("(1)", n)
  }, supplement: [])
  show ref: it => {
    // provide custom reference for equations
    if it.element != none and it.element.func() == math.equation {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#link(it.target)[#it]]
    } else if  it.element != none and it.element.func() != math.equation {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#link(it.target)[#it]]
    } else {
      it
    }
  }
  show link: it => {
    if type(it.dest) != str { // Local Links
      it
    }
    else {
      highlight(stroke: (thickness: 0.1em, paint: aqua, cap: "round"), fill:none, extent: 0pt)[#it]
      //underline(stroke: 1pt+fuchsia)[#it] // Web Links
    }
  }
  
  content

}
