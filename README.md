# citeproc-orgref

Render [org-ref](https://github.com/jkitchin/org-ref) citations and
bibliographies in Citation Style Language (CSL) styles using the
[citeproc-el](https://github.com/andras-simonyi/citeproc-el) Emacs Lisp library.
See http://citationstyles.org/ for more information on the CSL project.

Currently `citeproc-orgref` supports only the rendering of BibTeX citations and
bibliographies — BibLaTeX support is planned.

## Requirements and dependencies

`citeproc-orgref` requires Emacs 25.1 or later and depends on
[citeproc-el](https://github.com/andras-simonyi/citeproc-el), which must be
installed before installing the `citeproc-orgref` package.

## Installation

The recommended method of installation is to download the latest release as a
package from this link, and install it using the `package-install-file` Emacs
command. 

## Setup

Add the following line to your `.emacs` or  `init.el` file:

```el
(citeproc-orgref-setup)
```

## Usage

In its basic use, `citeproc-orgref` simply replaces `org-ref`'s built-in
citation processing for non-LaTeX org-mode export backends with `citeproc-el`
and exported `org-ref` citation links are rendered in the default Chicago
author-date CSL style during export. The handling of citation links during LaTeX
export does not change, they continue to be rendered with BibTeX.

### Setting the CSL style

The CSL style used for rendering the references can be set by adding a

    #+ CSL-STYLE: /path/to/csl_style_file
	
line to the org-mode document. (CSL styles can be downloaded, for instance, from
the [Zotero Style Repository](https://www.zotero.org/styles).)

### CSL locales

By default, the `en-US` CSL locale file shipped with `citeproc-orgref` is used
for rendering localized dates and terms in the references. 

## License

Copyright (C) 2017 András Simonyi

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

The "Chicago Manual of Style 17th edition (author-date)" CSL style and the
"en-US" CSL locale distributed with `citeproc-orgref` are both licensed under the
[Creative Commons Attribution-ShareAlike 3.0 Unported
license](http://creativecommons.org/licenses/by-sa/3.0/) and were developed
within the Citation Style Language project (see http://citationstyles.org). The
"Chicago Manual of Style 17th edition (author-date)" CSL style was written by
Julian Onions with contributions from Sebastian Karcher, Richard Karnesky and
Andrew Dunning.
