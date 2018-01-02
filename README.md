# citeproc-orgref

Render [org-ref](https://github.com/jkitchin/org-ref) citations and
bibliographies in Citation Style Language (CSL) styles using the
[citeproc-el](https://github.com/andras-simonyi/citeproc-el) Emacs Lisp library.
See http://citationstyles.org/ for more information on the CSL project.

Currently citeproc-orgref supports only the rendering of BibTeX bibliographies —
BibLaTeX support is planned.

citeproc-orgref is in an early stage of its development and mostly untested, so 
bugs and rough edges are to be expected.

**Table of Contents**

- [Requirements and dependencies](#requirements-and-dependencies)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)
    - [Setting the CSL style](#setting-the-csl-style)
    - [CSL locales](#csl-locales)
    - [Using locators and pre/post texts in cite links](#using-locators-and-prepost-texts-in-cite-links)
    - [Suppressing affixes and author names in citations](#suppressing-affixes-and-author-names-in-citations)
    - [Output format configuration](#output-format-configuration)
        - [Ignored export backends](#ignored-export-backends)
        - [Mapping export backends to citeproc-el formatters](#mapping-export-backends-to-citeproc-el-formatters)
        - [Bibliography formatting](#bibliography-formatting)
- [License](#license)

## Requirements and dependencies

citeproc-orgref requires Emacs 25.1 or later and depends on
[citeproc-el](https://github.com/andras-simonyi/citeproc-el), which must be
installed before installing the citeproc-orgref package.

## Installation

The recommended method of installation is to download the latest release as a
package from this link, and install it using the `package-install-file` Emacs
command. 

## Setup

Using citeproc-orgref currently requires adding its main rendering function
(`citeproc-orgref-render-references`) to org-mode’s
`org-export-before-parsing-hook`. This makes it incompatible with [org-ref’s own
citeproc](https://github.com/jkitchin/org-ref/tree/master/citeproc), which also
uses this hook. Org-ref’s citeproc is not activated by default, but if you have
added its renderer function, `orcp-citeproc`, to your
`org-export-before-parsing-hook` then it has to removed before setting up
citeproc-orgref.

citeproc-orgref provides the Emacs command `citeproc-orgref-setup` to add its
renderer to `org-export-before-parsing-hook`, which can be used interactively by
invoking

    M-x citeproc-orgref-setup

during an Emacs session. After the command’s execution citeproc-orgref will
remain active until the end of the session. If you want to use it on a permanent
basis then add the following line to your `.emacs` or `init.el` file:

```el
(citeproc-orgref-setup)
```

## Usage

In its basic use, citeproc-orgref simply replaces org-ref’s built-in citation
rendering for non-LaTeX org-mode export backends with citeproc-el and exported
org-ref citation links are rendered in the default Chicago author-date CSL style
during export. The handling of citation links during LaTeX export does not
change, they continue to be rendered with BibTeX/BibLaTeX.

### Setting the CSL style

The CSL style used for rendering references can be set by adding a

    #+ CSL-STYLE: /path/to/csl_style_file
	
line to the org-mode document. (CSL styles can be downloaded, for instance, from
the [Zotero Style Repository](https://www.zotero.org/styles).)

### CSL locales

By default, the `en-US` CSL locale file shipped with citeproc-orgref is used for
rendering localized dates and terms in the references, independently of the
language settings of org documents. Additional CSL locales can be made available
by setting the value of the `citeproc-orgref-locales-dir` variable to a
directory containing the locale files in question (locales can be found at
https://github.com/citation-style-language/locales).

If `citeproc-orgref-locales-dir` is set and an org-mode document contains a
language setting corresponding to a locale which is available in the directory
then citeproc-orgref will automatically try to use that locale for rendering the
document’s references during export (the used locale will also depend on the
used CSL style’s locale information).

### Using locators and pre/post texts in cite links

org-ref supports adding affixes (pre and post text) to references in the
description field of cite links using the `pre_text::post_text` syntax.
citeproc-orgref also utilizes cite link descriptions for storing additional
citation information but changes the syntax to be compatible with how CSL
represents citations.

The basic syntax, inspired by [pandoc’s citation
syntax](https://pandoc.org/MANUAL.html#citations), is `pre_text locator,
post_text`. For example, the cite link 

    [[cite:Tarski-1965][see chapter 1 for an example]] 
	
will be rendered as

    (see Tarski 1965, chap. 1 for an example)

in the default CSL style. 

The start of the locator part has to be indicated by a locator term, while the
end is either the last comma if it is not followed by digits or, in the absence
of such a comma, the end of the full description. The following locator terms
are recognized: `bk.`, `bks.`, `book`, `chap.`, `chaps.`, `chapter`, `col.`,
`cols.`, `column`, `figure`, `fig.`, `figs.`, `folio`, `fol.`, `fols.`,
`number`, `no.`, `nos.`, `line`, `l.`, `ll.`, `note`, `n.`, `nn.`, `opus`,
`op.`, `opp.`, `page`, `p.`, `pp.`, `paragraph`, `para.`, `paras.`, `¶`, `¶¶`,
`§`, `§§`, `part`, `pt.`, `pts.`, `section`, `sec.`, `secs.`, `sub verbo`,
`s.v.`, `s.vv.`, `verse`, `v.`, `vv.`, `volume`, `vol.`, `vols.`. Similarly to
pandoc, if no locator term is used but a number is present then “page” is
assumed.

If there are more than one cites in a cite link then their associated locators
and pre/post texts can be specified by using semicolons as separators. For
instance, the link

    [[cite:Tarski-1965,Gödel-1931][p. 45;see also p. 53]]
	
renders as

    (Tarski 1965, 45; see also Gödel 1931, 53)
	
with the default style.

When an org-mode document is exported to a LaTeX-based format that should not be
rendered by citeproc-orgref the cite link descriptions (if present) are
rewritten to a form suitable for org-ref’s LaTeX export. The concrete form
depends on the value of the `citeproc-orgref-bibtex-export-use-affixes`
variable. If the value is `nil` (the default) then the rewritten content will be
simply the concatenation of the pre text, the locator and the post text (of the
first block, if there are more). If the value is non-nil then the rewritten
content will be `pre_text::locator post_text`.

In our experience, setting `citeproc-orgref-bibtex-export-use-affixes` to
non-nil works well with Natbib styles but causes errors when using the built-in
LaTeX bibliography styles because their `\cite` command doesn’t accept a
separate argument for post text.

### Suppressing affixes and author names in citations

In certain contexts it might be desirable to suppress the affixes (typically
brackets) around citations and/or the name(s) of the author(s). With
citeproc-orgref these effects can be achieved by using a suitable cite link
type.

The variables `citeproc-orgref-suppress-affixes-cite-link-types` (defaults to
`("citealt")`) and `citeproc-orgref-suppress-author-cite-link-types` (defaults
to `("citeyear")`) contain the lists of link types that suppress citation
affixes and/or author names.

### Output format configuration

#### Ignored export backends

citeproc-orgref does not render cite links for export backends on the list
`citeproc-orgref-ignore-backends` (the default value is `(latex beamer)`). Cite
link rendering for these backends is handled by org-ref’s default rendering
mechanism (which uses BibTeX/BibLaTeX for the `latex` and `beamer` backends).

By changing the value of `citeproc-orgref-ignore-backends` citeproc-orgref can
be instructed to ignore or take over the rendering for certain backends. Most
notably, setting its value to `nil` has the effect that references will always
be rendered with citeproc-el even for LaTeX output, and BibTeX/BibLaTeX will not
be used at all.

#### Mapping export backends to citeproc-el formatters

citeproc-orgref uses the `org`, `html` and (optionally) `latex` citeproc-el
output formatters to render citations and bibliographies when exporting an
org-mode document. Since the `org` formatter has some limitations (stemming from
the limitations of the org-mode markup) it is recommended to use the `html` and
the `latex` formatters for html and LaTeX-based export backends that can handle
direct HTML or LaTeX output.

The mapping between export backends and output formatters can be configured by
customizing the `citeproc-orgref-html-backends` and
`citeproc-orgref-latex-backends` variables — if a backend is in neither of these
lists then the `org` citeproc-el formatter is used for export.

#### Bibliography formatting

Most of the bibliography formatting parameters (heading, indentation etc.) can
be configured — see the `Citeproc Orgref` customization group for details.

## License

Copyright (C) 2018 András Simonyi

Authors: András Simonyi

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/.

---

The “Chicago Manual of Style 17th edition (author-date)” CSL style and the
“en-US” CSL locale distributed with citeproc-orgref are both licensed under the
[Creative Commons Attribution-ShareAlike 3.0 Unported
license](http://creativecommons.org/licenses/by-sa/3.0/) and were developed
within the Citation Style Language project (see http://citationstyles.org). The
“Chicago Manual of Style 17th edition (author-date)” CSL style was written by
Julian Onions with contributions from Sebastian Karcher, Richard Karnesky and
Andrew Dunning.
