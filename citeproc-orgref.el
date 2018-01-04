;;; Commentary:

;; Functions to render org-ref bibliographic reference links in Citation Style
;; Language (CSL) styles using the citeproc-el library. See the accompanying
;; README for full documentation.

;;; citeproc-orgref.el --- Render org-ref references in CSL styles -*- lexical-binding: t; -*-

;; Copyright (C) 2017 András Simonyi

;; Author: András Simonyi <andras.simonyi@gmail.com>
;; Maintainer: András Simonyi <andras.simonyi@gmail.com>
;; URL: https://github.com/andras-simonyi/citeproc-orgref
;; Keywords: org-ref, org-mode, cite, bib
;; Package-Requires: ((emacs "25.1") (dash "2.13.0") (org "9") (f "0.18.0") (citeproc "0.1") (org-ref "1.1.1"))
;; Version: 0.1.0

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

;;; Code:

(require 'subr-x)
(require 'org)
(require 'org-element)
(require 'cl-lib)
(require 'dash)
(require 'map)
(require 'f)
(require 'let-alist)
(require 'org-ref)

(require 'citeproc)
(require 'citeproc-itemgetters)

(defgroup citeproc-orgref nil
  "Customization group for citeproc-orgref."
  :tag "Citeproc Orgref"
  :group 'org-ref)

(defcustom citeproc-orgref-default-style-file nil
  "Default CSL style file.
If nil then the chicago-author-date style is used as a fallback."
  :type 'file
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-locales-dir nil
  "Directory of CSL locale files.
If nil then only the fallback en-US locale will be available."
  :type 'dir
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-html-bib-header
  "<h2 class='citeproc-orgref-bib-h2'>Bibliography</h1>\n"
  "HTML bibliography header to use for html export."
  :type 'string
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-latex-bib-header "\\section*{Bibliography}\n\n"
  "HTML bibliography header to use for LaTeX export."
  :type 'string
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-org-bib-header "* Bibliography\n"
  "Org-mode bibliography header to use for non-html and non-LaTeX export."
  :type 'string
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-suppress-affixes-cite-link-types '("citealt")
  "Suppress citation affixes for these cite link types."
  :type '(repeat :tag "List of citation link types" string)
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-suppress-author-cite-link-types '("citeyear")
  "Suppress author for these cite link types."
  :type '(repeat :tag "List of citation link types" string)
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-link-cites t
  "Link cites to references."
  :type 'boolean
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-bibtex-export-use-affixes nil
  "Use separate prefix and suffix cite arguments for LaTeX export.
Some BibTeX packages (notably, NatBib) support separate prefix
and postfix arguments. If non-nil then affixes will be passed as
separate arguments."
  :type 'boolean
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-html-backends '(html twbs)
  "Use the html formatter for these org-mode export backends."
  :type '(repeat symbol)
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-latex-backends '(latex beamer)
  "Use the LaTeX formatter for these org-mode export backends."
  :type '(repeat symbol)
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-no-citelinks-backends '(ascii)
  "Backends for which cite linking should always be turned off."
  :type '(repeat symbol)
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-ignore-backends '(latex beamer)
  "List of backends whose output shouldn't be processed by citeproc-orgref."
  :type '(repeat symbol)
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-html-hanging-indent "1.5em"
  "The size of hanging-indent for html ouput in valid CSS units.
Used only when hanging-indent is activated by the used CSL
style."
  :type 'string
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-html-label-width-per-char "0.6em"
  "Character width in CSS units for calculating entry label widths.
Used only when second-field-align is activated by the used CSL
style."
  :type 'string
  :group 'citeproc-orgref)

(defcustom citeproc-orgref-latex-hanging-indent "1.5em"
  "The size of hanging-indent for LaTeX ouput in valid LaTeX units.
Always used for LaTeX output."
  :type 'string
  :group 'citeproc-orgref)

(defvar citeproc-orgref--proc-cache nil
  "Cached citeproc processor for citeproc-orgref.
Its value is either nil or a list of the form
(PROC STYLE-FILE BIBTEX-FILE LOCALE).")

(defconst citeproc-orgref--load-dir (f-dirname load-file-name)
  "The dir from which this file was loaded.")

(defconst citeproc-orgref--fallback-style-file
  (f-join citeproc-orgref--load-dir  "styles" "chicago-author-date.csl")
  "Default CSL style file.")

(defconst citeproc-orgref--fallback-locales-dir
  (f-join citeproc-orgref--load-dir "locales")
  "Directory of CSL locale files.")

(defconst citeproc-orgref--label-alist
  '(("bk." . "book")
    ("bks." . "book")
    ("book" . "book")
    ("chap." . "chapter")
    ("chaps." . "chapter")
    ("chapter" . "chapter")
    ("col." . "column")
    ("cols." . "column")
    ("column" . "column")
    ("figure" . "figure")
    ("fig." .  "figure")
    ("figs." .  "figure")
    ( "folio" . "folio")
    ("fol." .  "folio")
    ("fols." .  "folio")
    ("number" . "number")
    ("no." .  "number")
    ("nos." .  "number")
    ("line" . "line")
    ("l." .  "line")
    ("ll." .  "line")
    ("note" . "note")
    ("n." .  "note")
    ("nn." .  "note")
    ("opus" . "opus")
    ("op." .  "opus")
    ("opp." .  "opus")
    ("page" . "page")
    ("p." .  "page")
    ("pp." .  "page")
    ("paragraph" . "paragraph")
    ("para." .  "paragraph")
    ("paras." .  "paragraph")
    ("¶" . "paragraph")
    ("¶¶" . "paragraph")
    ("§" . "paragraph")
    ("§§" . "paragraph")
    ("part" . "part")
    ("pt." .  "part")
    ("pts." .  "part")
    ("section" . "section")
    ("sec." .  "section")
    ("secs." .  "section")
    ("sub verbo" . "sub verbo")
    ("s.v." .  "sub verbo")
    ("s.vv." . "sub verbo")
    ("verse" . "verse")
    ("v." .  "verse")
    ("vv." .  "verse")
    ("volume" . "volume")
    ("vol." .  "volume")
    ("vols." .  "volume"))
  "Alist mapping locator names to locators.")

(defconst citeproc-orgref--label-regex
  (let ((labels (map-keys citeproc-orgref--label-alist)))
    (concat "\\<\\("
	    (mapconcat (lambda (x) (s-replace "." "\\." x))
		       labels "\\|")
	    "\\)[ $]")))

(defun citeproc-orgref--parse-locator-affix (s)
  "Parse string S as a cite's locator and affix description.
Return the parse as an alist with `locator', `label', `prefix'
and `suffix' keys."
  (if (s-blank-p s) nil
    (let ((label-matches (s-matched-positions-all citeproc-orgref--label-regex s 1))
	  (digit-matches (s-matched-positions-all "\\<\\w*[[:digit:]]+" s))
	  (comma-matches (s-matched-positions-all "," s))
	  label locator prefix suffix location)
      (let ((last-comma-pos (and comma-matches
				 (cdr (-last-item comma-matches)))))
	(if (or label-matches digit-matches)
	    (let (label-exp loc-start loc-end)
	      (if (null label-matches)
		  (setq loc-start (caar digit-matches)
			loc-end (cdr (-last-item digit-matches))
			label "page")
		(progn
		  (setq label-exp (substring s (caar label-matches) (cdar label-matches))
			label (assoc-default label-exp citeproc-orgref--label-alist))
		  (if (null digit-matches)
		      (setq loc-start (caar label-matches)
			    loc-end (cdr (-last-item label-matches)))
		    (setq loc-start (min (caar label-matches) (caar digit-matches))
			  loc-end (max (cdr (-last-item label-matches))
				       (cdr (-last-item digit-matches)))))))
	      (when (> loc-start 0) (setq prefix (substring s 0 loc-start)))
	      (if (and last-comma-pos (> last-comma-pos loc-end))
		  (setq suffix (substring s last-comma-pos)
			loc-end (1- last-comma-pos))
		(setq loc-end nil))
	      (setq location (substring s loc-start loc-end)
		    locator (if label-exp (s-replace label-exp "" location) location)
		    locator (s-trim locator)))
	  (if last-comma-pos
	      (setq prefix (substring s 0 (1- last-comma-pos))
		    suffix (substring s last-comma-pos))
	    (setq prefix s))))
      `((locator . ,locator) (label . ,label) (location . ,location)
	(prefix . ,prefix) (suffix . ,suffix)))))

(defun citeproc-orgref--in-fn-p (elt)
  "Return whether org element ELT is in a footnote."
  (let ((curr (org-element-property :parent elt))
	result)
    (while (and curr (not result))
      (when (memq (org-element-type curr)
		  '(footnote-definition footnote-reference))
	(setq result (or (org-element-property :label curr) t)))
      (setq curr (org-element-property :parent curr)))
    result))

(defun citeproc-orgref--get-option-val (opt)
  "Return the value of org mode option OPT."
  (goto-char (point-min))
  (if (re-search-forward
       (concat "^#\\+" opt ":\\(.+\\)$")
       nil t)
      (let* ((match (match-data))
	     (start (elt match 2))
	     (end (elt match 3)))
	(s-trim (buffer-substring-no-properties start end)))
    nil))

(defun citeproc-orgref--get-cleared-proc (bibtex-file)
  "Return a cleared citeproc processor reading items from BIBTEX-FILE.
Clear and return the buffer's cached processor if it is available
and had the same parameters. Create and return a new processor
otherwise."
  (let ((style-file (or (citeproc-orgref--get-option-val "csl-style")
			citeproc-orgref-default-style-file
			citeproc-orgref--fallback-style-file))
	(locale (or (citeproc-orgref--get-option-val "language") "en"))
	result)
    (-when-let ((c-proc c-style-file c-bibtex-file c-locale)
		citeproc-orgref--proc-cache)
      (when (and (string= style-file c-style-file)
		 (string= locale c-locale))
	(progn
	  (unless (string= bibtex-file c-bibtex-file)
	    (setf (citeproc-proc-getter c-proc)
		  (citeproc-itemgetter-from-bibtex bibtex-file)
		  (elt citeproc-orgref--proc-cache 1) bibtex-file))
	  (citeproc-clear c-proc)
	  (setq result c-proc))))
    (or result
	(let ((proc (citeproc-create
		     style-file
		     (citeproc-itemgetter-from-bibtex bibtex-file)
		     (citeproc-locale-getter-from-dir
		      (or citeproc-orgref-locales-dir
			  citeproc-orgref--fallback-locales-dir))
		     locale)))
	  (setq citeproc-orgref--proc-cache
		(list proc style-file bibtex-file locale))
	  proc))))

(defun citeproc-orgref--links-and-notes()
  "Collect the buffer's bib-related links and info about them.
Returns a list (BIB-LINKS LINKS-AND-NOTES CITE-LINKS-COUNT
FOOTNOTES-COUNT) where LINKS-AND-NOTES is the list of cite link
and footnote representations (lists of the form (`link'
CITE-LINK-IDX CITE-LINK) or (`footnote' FN-LABEL [CITE-LINK_n ...
CITE-LINK_0])), in which CITE_LINK_n is the n-th cite-link
occurring in the footnote."
  (let* ((elts (org-element-map (org-element-parse-buffer)
		   '(footnote-reference link) #'identity))
	 cite-links bib-links links-and-notes
	 (act-link-no 0)
	 (cite-links-count 0)
	 (footnotes-count 0))
    (dolist (elt elts)
      (if (eq 'footnote-reference (org-element-type elt))
	  (progn
	    (cl-incf footnotes-count)
	    ;; footnotes repesented as ('footnote <label> <link_n> ... <link_0>)
	    (push (list 'footnote (org-element-property :label elt))
		  links-and-notes))
	(let ((link-type (org-element-property :type elt)))
	  (cond
	   ((member link-type org-ref-cite-types)
	    (push elt cite-links)
	    (cl-incf cite-links-count)
	    (let ((fn-label (citeproc-orgref--in-fn-p elt))
		  ;; links as ('link <link-idx> link)
		  (indexed (list 'link act-link-no elt)))
	      (cl-incf act-link-no)
	      (pcase fn-label
		;; not in footnote
		((\` nil) (push indexed links-and-notes))
		;; unlabelled, in the last footnote
		('t (push indexed (cddr (car links-and-notes))))
		;; labelled footnote
		(_ (let ((fn-with-label (--first (and (eq (car it) 'footnote)
						      (string= fn-label
							       (cadr it)))
						 links-and-notes)))
		     (if fn-with-label
			 (setf (cddr fn-with-label)
			       (cons indexed (cddr fn-with-label)))
		       (error
			"No footnote reference before footnote definition with label %s"
			fn-label)))))))
	   ((or (string= link-type "bibliography")
		(string= link-type "nobibliography"))
	    (push elt bib-links))))))
    (list (nreverse cite-links)
	  bib-links links-and-notes cite-links-count footnotes-count)))

(defun citeproc-orgref--assemble-link-info
    (links-and-notes link-count footnote-count &optional all-links-are-notes)
  "Return position and note info using LINKS-AND-NOTES info.
The format and content of LINKS-AND-NOTES is as described in the
documentation of `citeproc-orgref--links-and-notes'. LINK-COUNT
and FOOTNOTE-COUNT is the number of links and footnotes in
LINKS-AND-NOTES. If optional ALL-LINKS-ARE-NOTES is non-nil then
treat all links as footnotes (usde for note CSL styles)."
  (let (link-info
	(act-fn-no (let ((links-and-notes-count (length links-and-notes)))
		     (1+ (if all-links-are-notes
			     links-and-notes-count
			   footnote-count))))
	(act-cite-no link-count))
    (dolist (elt links-and-notes)
      (pcase (car elt)
	('link
	 (push (list
		:link (cl-caddr elt)
		:link-no (cadr elt)
		:cite-no (cl-decf act-cite-no)
		:fn-no (if all-links-are-notes
			   (cl-decf act-fn-no)
			 nil)
		:new-fn all-links-are-notes)
	       link-info))
	('footnote
	 (cl-decf act-fn-no)
	 (dolist (link (cddr elt))
	   (push (list
		  :link (cl-caddr link)
		  :link-no (cadr link)
		  :cite-no (cl-decf act-cite-no)
		  :fn-no act-fn-no)
		 link-info)))))
    link-info))

(defun citeproc-orgref--link-to-citation (link footnote-no new-fn
					       &optional capitalize-outside-fn)
  "Return a citeproc citation corresponding to an org cite LINK.
FOOTNOTE-NO is nil if LINK is not in a footnote or the number of
the link's footnote. If NEW-FN is non-nil the the link was not in
a footnote biIf CAPITALIZE-OUTSIDE-FN is non-nil then set the
`capitalize-first' slot of the citation struct to t when the link
is not in a footnote."
  (let* ((type (org-element-property :type link))
	 (path (org-element-property :path link))
	 (content (let ((c-begin (org-element-property :contents-begin link))
			(c-end (org-element-property :contents-end link)))
		    (if (and c-begin c-end)
			(buffer-substring-no-properties c-begin c-end)
		      nil)))
	 (itemids (split-string path ","))
	 (cites-ids (--map (cons 'id it)
			   itemids)))
    (citeproc-citation-create
     :note-index footnote-no
     :cites
     (let ((cites
	    (if content
		(let* ((cites-rest (mapcar #'citeproc-orgref--parse-locator-affix
					   (split-string content ";")))
		       (cites-no (length cites-ids))
		       (rest-no (length cites-rest))
		       (diff (- cites-no rest-no))
		       (cites-rest-filled
			(let* ()
			  (if (> diff 0)
			      (-concat cites-rest (make-list diff nil))
			    cites-rest))))
		  (-zip cites-ids cites-rest-filled))
	      (mapcar #'list cites-ids))))
       (if (member type citeproc-orgref-suppress-author-cite-link-types)
	   (cons (cons '(suppress-author . t) (car cites)) (cdr cites))
	 cites))
     :capitalize-first (and capitalize-outside-fn
			    new-fn)
     :suppress-affixes (member type
			       citeproc-orgref-suppress-affixes-cite-link-types))))
 
(defun citeproc-orgref--element-boundaries (element)
  "Return the boundaries of an org ELEMENT.
Returns a (BEGIN END) list -- post-blank positions are not
considered when calculating END."
  (let ((begin (org-element-property :begin element))
	(end (org-element-property :end element))
	(post-blank (org-element-property :post-blank element)))
    (list begin (- end post-blank))))

(defun citeproc-orgref--format-html-bib (bib parameters)
  "Format html bibliography BIB using formatting PARAMETERS."
  (let* ((char-width (car (s-match "[[:digit:].]+"
				   citeproc-orgref-html-label-width-per-char)))
	 (char-width-unit (substring citeproc-orgref-html-label-width-per-char
				     (length char-width))))
    (let-alist parameters
      (concat "\n#+BEGIN_EXPORT html\n"
	      (when .second-field-align
		(concat "<style>.csl-left-margin{float: left; padding-right: 0em;} "
			".csl-right-inline{margin: 0 0 0 "
			(number-to-string (* .max-offset (string-to-number char-width)))
			char-width-unit ";}</style>"))
	      (when .hanging-indent
		(concat "<style>.csl-entry{text-indent: -"
			citeproc-orgref-html-hanging-indent
			"; margin-left: "
			citeproc-orgref-html-hanging-indent
			";}</style>"))
	      citeproc-orgref-html-bib-header
	      bib
	      "\n#+END_EXPORT\n"))))

(defun citeproc-orgref--format-latex-bib (bib)
  "Format LaTeX bibliography BIB."
  (concat "#+latex_header: \\usepackage{hanging}\n#+BEGIN_EXPORT latex\n"
		 citeproc-orgref-latex-bib-header
		 "\\begin{hangparas}{" citeproc-orgref-latex-hanging-indent "}{1}"
		 bib "\n\\end{hangparas}\n#+END_EXPORT\n"))

(defun citeproc-orgref--bibliography (proc backend)
  "Return a bibliography using citeproc PROC for BACKEND."
  (cond ((memq backend citeproc-orgref-html-backends)
	 (-let ((rendered
		 (citeproc-render-bib proc 'html (not citeproc-orgref-link-cites))))
	   (citeproc-orgref--format-html-bib (car rendered) (cdr rendered))))
	((memq backend citeproc-orgref-latex-backends)
	 (citeproc-orgref--format-latex-bib
	  (car (citeproc-render-bib proc 'latex (not citeproc-orgref-link-cites)))))
	(t (concat citeproc-orgref-org-bib-header
		   (car (citeproc-render-bib
			 proc
			 'org
			 (or (memq backend citeproc-orgref-no-citelinks-backends)
			     (not citeproc-orgref-link-cites))))
		   "\n"))))

(defun citeproc-orgref--append-and-render-citations (link-info proc backend)
  "Render citations using LINK-INFO and PROC for BACKEND.
Return the list of corresponding rendered citations."
  (let* ((is-note-style (citeproc-style-cite-note (citeproc-proc-style proc)))
	 (citations (--map (citeproc-orgref--link-to-citation
			    (plist-get it :link)
			    (plist-get it :fn-no)
			    (plist-get it :new-fn)
			    is-note-style)
			   link-info)))
    (citeproc-append-citations citations proc)
    (let* ((rendered
	    (cond ((memq backend citeproc-orgref-html-backends)
		   (--map (concat "@@html:" it "@@")
			  (citeproc-render-citations
			   proc 'html (not citeproc-orgref-link-cites))))
		  ((memq backend citeproc-orgref-latex-backends)
		   (--map (concat "@@latex:" it "@@")
			  (citeproc-render-citations
			   proc 'latex (not citeproc-orgref-link-cites))))
		  (t (citeproc-render-citations
		      proc 'org (or (memq backend citeproc-orgref-no-citelinks-backends)
				    (not citeproc-orgref-link-cites)))))))
      (setq rendered (cl-loop for l-i in link-info
			      for rendered-citation in rendered
			      collect (if (plist-get l-i :new-fn)
					  (concat "[fn::" rendered-citation "]")
					rendered-citation)))
      (citeproc-orgref--reorder-rendered-citations rendered link-info))))

(defun citeproc-orgref--reorder-rendered-citations (rendered-citations link-info)
  "Put RENDERED-CITATIONS into insertion order using LINK-INFO."
  (let ((sorted (cl-sort link-info #'< :key (lambda (x) (plist-get x :link-no)))))
    (--map (elt rendered-citations (plist-get it :cite-no)) sorted)))

;;;###autoload
(defun citeproc-orgref-render-references (backend)
  "Render cite and bib links for export with BACKEND."
  (interactive)
  (if (not (memq backend citeproc-orgref-ignore-backends))
      (-let (((cite-links bib-links links-and-notes link-count footnote-count)
	      (citeproc-orgref--links-and-notes)))
	(when cite-links
	  ;; Deal with the existence and boundaries of the bib link
	  (-let* ((bl-count (length bib-links))
		  (bib-link (cond
			     ((= bl-count 1) (car bib-links))
			     ((> bl-count 1)
			      (error "Cannot process more then one bibliography links"))
			     ((= bl-count 0)
			      (error "Missing bibliography link"))))
		  (bibtex-file (org-element-property :path bib-link))
		  (omit-bib (string= (org-element-property :type bib-link)
				     "nobibliography"))
		  (proc (citeproc-orgref--get-cleared-proc bibtex-file))
		  ((bl-begin bl-end)
		   (and bib-link (citeproc-orgref--element-boundaries bib-link))))
	    (-let* ((link-info
		     (citeproc-orgref--assemble-link-info
		      links-and-notes link-count footnote-count
		      (citeproc-style-cite-note (citeproc-proc-style proc))))
		    (rendered-cites
		     (citeproc-orgref--append-and-render-citations link-info proc backend))
		    (rendered-bib (if omit-bib ""
				    (citeproc-orgref--bibliography proc backend)))
		    (offset 0)
		    (bib-inserted-p nil))
	      (cl-loop for rendered in rendered-cites
		       for link in cite-links
		       do
		       (-let* (((begin end) (citeproc-orgref--element-boundaries link)))
			 (when (and bib-link (> begin bl-end))
			   ;; Reached a cite link after the bibliography link so
			   ;; we insert the rendered bibliography before it
			   (setf (buffer-substring (+ bl-begin offset) (+ bl-end offset))
				 rendered-bib)
			   (setq bib-inserted-p t)
			   (cl-incf offset (- (length rendered-bib) (- bl-end bl-begin))))
			 (when (and (string= "[fn::" (substring rendered 0 5))
				    (= (char-before (+ begin offset)) ?\s))
			   ;; Remove (a single) space before the footnote
			   (cl-decf begin 1))
			 (setf (buffer-substring (+ begin offset) (+ end offset))
			       rendered)
			 (cl-incf offset (- (length rendered) (- end begin)))))
	      (when (not bib-inserted-p)
		;; The bibliography link was the last one
		(setf (buffer-substring (+ bl-begin offset) (+ bl-end offset))
		      rendered-bib))))))
    (citeproc-orgref--citelinks-to-legacy))
  nil)

(defun citeproc-orgref--citelink-content-to-legacy (content)
  "Convert a parsed citelink CONTENT to a legacy one."
  (message "content: %s" content)
  (let* ((first-item (car (split-string content ";")))
	 (parsed (citeproc-orgref--parse-locator-affix first-item))
	 prefix suffix)
    (let-alist parsed
      (if (not citeproc-orgref-bibtex-export-use-affixes)
	  (concat .prefix .location .suffix)
	(progn
	  (setq prefix .prefix
		suffix (concat .location .suffix))
	  (if (null suffix) prefix (concat prefix "::" suffix)))))))

(defun citeproc-orgref--citelinks-to-legacy ()
  "Replace cite link contents with their legacy `org-ref' versions."
  (interactive)
  (let ((links (--filter (and (string= (org-element-property :type it) "cite")
			      (org-element-property :contents-begin it))
			 (org-element-map (org-element-parse-buffer)
			     'link #'identity)))
	(offset 0))
    (dolist (link links)
      (-let* (((begin end) (citeproc-orgref--element-boundaries link))
	      (raw-link (org-element-property :raw-link link))
	      (c-begin (+ offset (org-element-property :contents-begin link)))
	      (c-end (+ offset (org-element-property :contents-end link)))
	      (content (buffer-substring-no-properties c-begin c-end))
	      (new-content (citeproc-orgref--citelink-content-to-legacy content))
	      (new-link (if (s-blank-p new-content)
			    (concat "[[" raw-link "]]")
			  (concat "[[" raw-link "][" new-content "]]"))))
	(setf (buffer-substring (+ begin offset) (+ end offset))
	      new-link)
	(cl-incf offset (- (length new-link) (- end begin)))))))

(provide 'citeproc-orgref)

;;; citeproc-orgref.el ends here
