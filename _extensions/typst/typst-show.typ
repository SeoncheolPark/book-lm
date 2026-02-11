
// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates
#show: lecture.with(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(author)$
  authors: "$author$",
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(department)$
  department: "$department$",
$endif$
$if(institution)$
  institution: "$institution$",
$endif$
$if(email)$
  email: "$email$",
$endif$
$if(titlemessage)$
  titlemessage: "$titlemessage$",
$endif$
$if(ratio)$
  ratio: $ratio$,
$endif$
$if(logo)$
  logo: "$logo$",
$endif$
$if(logo-small)$
  logo-small: "$logo-small$",
$endif$
$if(qrurl)$
  qrurl: "$qrurl$",
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(lecturetype)$
  lecturetype: "$lecturetype$",
$endif$
$if(theme)$
  theme: "$theme$",
$endif$
$if(firstlevelheading)$
  firstlevelheading: "$firstlevelheading$",
$endif$
$if(firstlevelheading)$
  firstlevelheading: $firstlevelheading$,
$endif$
$if(footer-title)$
  footer-title: "$footer-title$",
$endif$
$if(footer-subtitle)$
  footer-subtitle: "$footer-subtitle$",
$endif$
$if(layout)$
  layout: "$layout$",
$endif$
$if(title-font)$
  title-font: "$title-font$",
$endif$
$if(title-color)$
  title-color: $title-color$,
$endif$
$if(main-font)$
  main-font: "$main-font$",
$endif$
$if(count)$
  count: "$count$",
$endif$
$if(footer)$
  footer: "$footer$",
$endif$ 
$for(toc)$
  toc: $toc$,
$endfor$ 
$if(column)$
  column: $column$,
$endif$
)
