;;; bibtex.scm  --  Handling BibTeX references.
;;;
;;; Copyright 2006, 2007, 2020 Ludovic Courtès <ludo@gnu.org>
;;;
;;;
;;; This file is part of Skribilo.
;;;
;;; Skribilo is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; Skribilo is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Skribilo.  If not, see <http://www.gnu.org/licenses/>.


(define-module (skribilo biblio bibtex)
  #:autoload   (skribilo utils strings) (make-string-replace)
  #:use-module (skribilo ast)
  #:autoload   (skribilo engine)        (engine-filter find-engine)
  #:use-module (skribilo biblio author)
  #:use-module (srfi srfi-39)
  #:use-module (srfi srfi-13)
  #:export     (print-as-bibtex-entry))

;;; Author:  Ludovic Courtès
;;;
;;; Commentary:
;;;
;;; A set of BibTeX tools, e.g., issuing a BibTeX entry from a `&bib-entry'
;;; markup object.
;;;
;;; Code:

(define *bibtex-author-filter*
  ;; Defines how the `author' field is to be filtered.
  (make-parameter comma-separated->and-separated-authors))

(define (print-as-bibtex-entry entry)
  "Display @code{&bib-entry} object @var{entry} as a BibTeX entry."
  (let ((show-option (lambda (opt)
		       (let* ((o (markup-option entry opt))
			      (f (make-string-replace '((#\newline " "))))
			      (g (if (eq? opt 'author)
				     (lambda (a)
				       ((*bibtex-author-filter*) (f a)))
				     f)))
			 (if (not o)
			     #f
			     `(,(symbol->string opt)
			       " = \""
			       ,(g (ast->string (markup-body o)))
			       "\","))))))
    (format #t "@~a{~a,~%"
	    (markup-option entry 'kind)
	    (markup-ident entry))
    (for-each (lambda (opt)
		(let* ((o (show-option opt))
		       (tex-filter (engine-filter
				    (find-engine 'latex)))
		       (filter (lambda (n)
				 (tex-filter (ast->string n))))
		       (id (lambda (a) a)))
		  (if o
		      (display
		       (string-concatenate
			      `(,@(map (if (eq? 'url opt)
					   id filter)
				       (cons "  " o))
				"\n"))))))
	      '(author institution title
                booktitle journal number
		year month url pages address publisher))
    (display "}\n")))


;;; arch-tag: 8b5913cc-9077-4e92-839e-c4c633b7bd46

;;; bibtex.scm ends here
