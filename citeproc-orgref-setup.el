;;; citeproc-orgref-setup.el --- Set up citeproc-orgref -*- lexical-binding: t; -*-

;; Copyright (C) 2017 András Simonyi

;; Author: András Simonyi <andras.simonyi@gmail.com>
;; Maintainer: András Simonyi <andras.simonyi@gmail.com>
;; URL: https://github.com/andras-simonyi/citeproc-orgref
;; Keywords: bib
;; Package-Requires: ((emacs "25.1") (org-ref "1.1.1") (citeproc "0.1"))
;; Version: 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Function to set up citeproc-orgref. It is in a separate file to avoid loading
;; the whole program and citeproc-el in the setup phase.

;;; Code:

;;;###autoload
(defun citeproc-orgref-setup ()
  "Add citeproc-orgref rendering to the `org-export-before-parsing-hook' hook."
  (interactive)
  (add-hook 'org-export-before-parsing-hook #'citeproc-orgref-render-references))

;;; citeproc-orgref-setup ends here 
