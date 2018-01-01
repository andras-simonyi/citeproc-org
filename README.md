# citeproc-orgref

Render [org-ref](https://github.com/jkitchin/org-ref) citations and
bibliographies in Citation Style Language (CSL) styles using the
[citeproc-el](https://github.com/andras-simonyi/citeproc-el) library. See
http://citationstyles.org/ for more information on the CSL project.

## Requirements and dependencies

`citeproc-orgref` requires Emacs 25.1 or later and depends on
[citeproc-el](https://github.com/andras-simonyi/citeproc-el), which must be
installed before installing it.

## Installation

Hopefully, `citeproc-orgref` will be available as a [MELPA](https://melpa.org)
package in the near future but until then the recommended method of installation
is to download the latest release as a package from this link, and install it
using the `package-install-file` Emacs command.

## Setup

Add the following line to your `.emacs` or  `init.el` file:

```el
(citeproc-orgref-setup)
```

## Usage

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
