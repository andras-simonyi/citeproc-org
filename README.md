# citeproc-org
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Render [Org-mode](https://orgmode.org/) citations and
bibliographies in Citation Style Language (CSL) styles using the
[citeproc-el](https://github.com/andras-simonyi/citeproc-el) Emacs Lisp library.
(See http://citationstyles.org/ for more information on the CSL project.)

Currently citeproc-org supports only the rendering of BibTeX
bibliographies—biblatex support is planned.

**Table of Contents**

- [Requirements and dependencies](#requirements-and-dependencies)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)
    - [Setting the CSL style](#setting-the-csl-style)
    - [CSL locales](#csl-locales)
	- [Org-ref citations](#org-ref-citations)
        - [Locators and pre/post texts in cite links](#locators-and-prepost-texts-in-cite-links)
        - [Suppressing affixes and author names in citations](#suppressing-affixes-and-author-names-in-citations)
    - [Org-mode citations and bibliography using the “wip-cite” syntax](#org-mode-citations-and-bibliography-using-the-wip-cite-syntax)
	    - [Bibliography file and placement](#bibliography-file-and-placement)
 		- [Citations](#citations)
        - [Locators](#locators)
    - [Output format configuration](#output-format-configuration)
        - [Ignored export backends](#ignored-export-backends)
        - [Mapping export backends to citeproc-el formatters](#mapping-export-backends-to-citeproc-el-formatters)
        - [Bibliography formatting](#bibliography-formatting)
- [Credits](#credits)
- [License](#license)

## Requirements and dependencies

citeproc-org requires Emacs 25.1 or later compiled with libxml2 support,
Org-mode 9.0 or later and depends on
[citeproc-el](https://github.com/andras-simonyi/citeproc-el), which must be
installed before installing the citeproc-org package. Rendering
[org-ref](https://github.com/jkitchin/org-ref) citation links requires org-ref,
while rendering cites in the Org citation syntax requires an Org version that
supports the syntax implemented by the `wip-cite` org-mode development branch.

## Installation

The recommended method of installation is to download the [latest release as a
package](https://github.com/andras-simonyi/citeproc-org/releases/download/0.2.3/citeproc-org-0.2.3.tar)
and install it using the `package-install-file` Emacs command.

## Setup

Using citeproc-org currently requires adding its main rendering function
(`citeproc-org-render-references`) to org-mode’s
`org-export-before-parsing-hook`. This makes it incompatible with [org-ref’s own
citeproc](https://github.com/jkitchin/org-ref/tree/master/citeproc), which also
uses this hook. Org-ref’s citeproc is not activated by default, but if you have
added its renderer function, `orcp-citeproc`, to your
`org-export-before-parsing-hook` then it has to be removed before setting up
citeproc-org.

citeproc-org provides the Emacs command `citeproc-org-setup` to add its
renderer to `org-export-before-parsing-hook`, which can be used interactively by
invoking

    M-x citeproc-org-setup

during an Emacs session. After the command’s execution citeproc-org will
remain active until the end of the session. If you want to use it on a permanent
basis then add the following line to your `.emacs` or `init.el` file:

```el
(citeproc-org-setup)
```

## Usage

citeproc-org supports two different Org citation syntaxes:
[org-ref](https://github.com/jkitchin/org-ref) citation links and,
experimentally, the citation syntax used by the `wip-cite` development branch of
org-mode. During the export process citeproc-org detects which type of citations
are present in the document and automatically uses the corresponding citation
parser. The two citation styles cannot be mixed.

In its basic use, citeproc-org overtakes citation rendering for non-LaTeX
Org-mode export backends and exported org-mode citations are rendered in the
default Chicago author-date CSL style during export. The handling of citations
for LaTeX-based export backends does not change (but see [Ignored export
backends](#ignored-export-backends) for ways of changing this behaviour).

### Setting the CSL style

The CSL style used for rendering references can be set by adding a

    #+CSL_STYLE: /path/to/csl_style_file
	
line to the Org-mode document. (CSL styles can be downloaded, for instance, from
the [Zotero Style Repository](https://www.zotero.org/styles).) Dependent styles
(which are not “unique” styles in the terminology of the Zotero Style
Repository) are not supported.

### CSL locales

By default, the `en-US` CSL locale file shipped with citeproc-org is used for
rendering localized dates and terms in the references, independently of the
language settings of Org documents. Additional CSL locales can be made available
by setting the value of the `citeproc-org-locales-dir` variable to a
directory containing the locale files in question (locales can be found at
https://github.com/citation-style-language/locales). The directory must contain
at least the `en-US` CSL locale.

If `citeproc-org-locales-dir` is set and an org-mode document contains a
language setting corresponding to a locale which is available in the directory
then citeproc-org will automatically try to use that locale for rendering the
document’s references during export (the used locale will also depend on the
used CSL style’s locale information).

### Org-ref citations

The syntax and usage of org-ref citation and bibliography links is described in
detail in the [org-ref
manual](https://github.com/jkitchin/org-ref/blob/master/org-ref.org).
citeproc-org relies on a few extensions of the basic syntax and semantics to
support using locators, cite-specific pre/post texts, and suppressing affixes
and authors in citations.

#### Locators and pre/post texts in cite links

org-ref supports adding pre and post texts to references in the description
field of cite links using the `pre_text::post_text` syntax. citeproc-org also
utilizes cite link descriptions for storing additional citation information but
changes the syntax to be compatible with how CSL represents citations.

The basic syntax, inspired by [pandoc’s citation
syntax](https://pandoc.org/MANUAL.html#citations), is `pre_text locator,
post_text`. For example, the cite link 

    [[cite:Tarski-1965][see chapter 1, for an example]] 
	
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

When an Org-mode document is exported to a LaTeX-based format that should not be
rendered by citeproc-org the cite link descriptions (if present) are
rewritten to a form suitable for org-ref’s LaTeX export. The concrete form
depends on the value of the `citeproc-org-bibtex-export-use-affixes`
variable. If the value is `nil` (the default) then the rewritten content will be
simply the concatenation of the pre text, the locator and the post text (of the
first block, if there are more). If the value is non-nil then the rewritten
content will be `pre_text::locator post_text`.

In our experience, setting `citeproc-org-bibtex-export-use-affixes` to
non-nil works well with Natbib styles but causes errors when using the built-in
LaTeX bibliography styles because their `\cite` command doesn’t accept a
separate argument for post text.

#### Suppressing affixes and author names in citations

In certain contexts it might be desirable to suppress the affixes (typically
brackets) around citations and/or the name(s) of the author(s). With org-ref and
citeproc-org these effects can be achieved by using a suitable cite link type.

The variables `citeproc-org-suppress-affixes-cite-link-types` (defaults to
`("citealt")`) and `citeproc-org-suppress-author-cite-link-types` (defaults
to `("citeyear")`) contain the lists of link types that suppress citation
affixes and/or author names.

### Org-mode citations and bibliography using the “wip-cite” syntax

Currently only the the `wip-cite` development branch of Org supports this
citaton syntax.

#### Bibliography file and placement

The path of the BibTeX file to be used has to be specified by a

	#+BIBLIOGRAPHY: /path/to/bibtex_file

line, while the location where the rendered bibliography should be placed can be
indicated by a

	#+BIBLIOGRAPHY: here
	
line in the document. If the document does not contain a `#+BIBLIOGRAPHY: here`
line then the bibliography is omitted.

#### Citations

citeproc-org supports all citation forms implemented by the `wip-cite`
development branch of Org. Short form citations contain only a single item id
prefixed with an `@` character with or without square brackets to indicate
parentheses, e.g.,

    In his magnum opus [@doe2018], Doe contradicts the earlier @doe2010.

which would be rendered as

	In his magnum opus (Doe 2018), Doe contradicts the earlier Doe 2010.

in the default style.

Long form citations, in contrast, have a far more elaborate syntax, which
supports multiple cites and pre/post texts:

	[cite:common_pre_text;pre_text1 @itemid1 post_text1;...;pre_text_n @itemid_n post_text_n;common_post_text]
	
(using pre/post texts and multiple cites is, of course, optional). There is a
parenthetical variant as well:
	
	[(cite):common_pre_text;pre_text1 @itemid1 post_text1;...;pre_text_n @itemid_n post_text_n;common_post_text]
	
#### Locators
	
Similarly to org-ref cites, citeproc-org uses post-texts to represent cite
locators. More concretely, the post-text field of cites can have the form
`locator, suffix`, where the locator starts with a recognized locator term
such as “p.” and "chap.” (see section [Locators and pre/post texts in cite
links](#locators-and-prepost-texts-in-cite-links), above, for the full list),
and ends before the first comma or at the end of the whole post-text field if
there is no comma. For example, the citation

	[(cite):see @Doe2018 p. 123, for further references]
	
would be rendered as

	(see Doe 2018, 123 for further references)
	
in the default style.

### Output format configuration

#### Ignored export backends

citeproc-org does not render cite links for export backends that are on the list
`citeproc-org-ignore-backends` (the default value is `(latex beamer)`). Citation
rendering for these backends is handed over to the active default rendering
mechanism (org-ref, for instance, uses BibTeX/biblatex for the `latex` and
`beamer` backends).

By changing the value of `citeproc-org-ignore-backends` citeproc-org can
be instructed to ignore or take over the rendering for certain backends. Most
notably, setting its value to `nil` has the effect that references will always
be rendered with citeproc-el even for LaTeX output, and BibTeX/biblatex will not
be used at all.

#### Mapping export backends to citeproc-el formatters

citeproc-org uses the `org`, `html` and (optionally) `latex` citeproc-el output
formatters to render citations and bibliographies when exporting an Org
document. Since the `org` formatter has some limitations (stemming from the
limitations of the Org-mode markup) it is recommended to use the `html` and the
`latex` formatters for HTML and LaTeX-based export backends that can handle
direct HTML or LaTeX output.

The mapping between export backends and output formatters can be configured by
customizing the `citeproc-org-html-backends` and
`citeproc-org-latex-backends` variables—if a backend is in neither of these
lists then the `org` citeproc-el formatter is used for export.

#### Bibliography formatting

Most of the bibliography formatting parameters (heading, indentation etc.) can
be configured—see the `Citeproc Org` customization group for details.

## Credits

Thanks to John Kitchin and his co-developers for creating the excellent org-ref
package. citeproc-org was inspired by and borrows some implementation ideas
from John Kitchin’s [org-ref citation processor](https://github.com/jkitchin/org-ref/tree/master/citeproc).

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
“en-US” CSL locale distributed with citeproc-org are both licensed under the
[Creative Commons Attribution-ShareAlike 3.0 Unported
license](http://creativecommons.org/licenses/by-sa/3.0/) and were developed
within the Citation Style Language project (see http://citationstyles.org). The
“Chicago Manual of Style 17th edition (author-date)” CSL style was written by
Julian Onions with contributions from Sebastian Karcher, Richard Karnesky and
Andrew Dunning.
