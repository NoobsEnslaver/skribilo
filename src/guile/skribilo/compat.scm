;;; compat.scm  --  Skribe compatibility module.
;;;
;;; Copyright 2005  Ludovic Court�s  <ludovic.courtes@laas.fr>
;;;
;;;
;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 2 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
;;; USA.


(define-module (skribilo compat)
  :use-module (skribilo parameters)
  :use-module (srfi srfi-1))


;;;
;;; Global variables that have been replaced by parameter objects
;;; in `(skribilo parameters)'.
;;;

;;; Switches
(define-public *skribe-verbose*	0)
(define-public *skribe-warning*	5)
(define-public *load-rc*		#t)


;;; Path variables
(define-public *skribe-path*		#f)
(define-public *skribe-bib-path*	'("."))
(define-public *skribe-source-path*	'("."))
(define-public *skribe-image-path*	'("."))


(define-public *skribe-rc-directory*
  (string-append (getenv "HOME") "/" ".skribilo"))


;;; In and out ports
(define-public *skribe-src*		'())
(define-public *skribe-dest*		#f)

;;; Engine
(define-public *skribe-engine*	'html)	;; Use HTML by default

;;; Misc
(define-public *skribe-chapter-split*	'())
(define-public *skribe-ref-base*	#f)
(define-public *skribe-convert-image*  #f)	;; i.e. use the Skribe standard converter
(define-public *skribe-variants*	'())



;;;
;;; Accessors mapped to parameter objects.
;;;

(define-public skribe-path        *document-path*)
(define-public skribe-image-path  *image-path*)
(define-public skribe-source-path *source-path*)
(define-public skribe-bib-path    *bib-path*)


;;;
;;; Compatibility with Bigloo.
;;;

(define-public (substring=? s1 s2 len)
  (let ((l1 (string-length s1))
	(l2 (string-length s2)))
    (let Loop ((i 0))
      (cond
	((= i len) #t)
	((= i l1)  #f)
	((= i l2)  #f)
	((char=? (string-ref s1 i) (string-ref s2 i)) (Loop (+ i 1)))
	(else #f)))))

(define-public (directory->list str)
  (map basename (glob (string-append str "/*") (string-append "/.*"))))

(define-macro (printf . args)   `(format #t ,@args))
(export-syntax printf)
(define-public fprintf			format)

(define-public (fprint port . args)
  (if port
      (with-output-to-port port
	(lambda ()
	  (for-each display args)
	  (display "\n")))))

(define-public (file-prefix fn)
  (if fn
      (let ((match (regexp-match "(.*)\\.([^/]*$)" fn)))
	(if match
	    (cadr match)
	    fn))
      "./SKRIBILO-OUTPUT"))

(define-public (file-suffix s)
  ;; Not completely correct, but sufficient here
  (let* ((basename (regexp-replace "^(.*)/(.*)$" s "\\2"))
	 (split    (string-split basename ".")))
    (if (> (length split) 1)
	(car (reverse! split))
	"")))

(define-public prefix			file-prefix)
(define-public suffix			file-suffix)
(define-public system->string		system)  ;; FIXME
(define-public any?			any)
(define-public every?			every)
(define-public find-file/path		(lambda (. args)
				  (format #t "find-file/path: ~a~%" args)
				  #f))
(define-public process-input-port	#f) ;process-input)
(define-public process-output-port	#f) ;process-output)
(define-public process-error-port	#f) ;process-error)

;;; hash tables
(define-public make-hashtable		make-hash-table)
(define-public hashtable?		hash-table?)
(define-public hashtable-get		(lambda (h k) (hash-ref h k #f)))
(define-public hashtable-put!		hash-set!)
(define-public hashtable-update!	hash-set!)
(define-public hashtable->list	(lambda (h)
                          (map cdr (hash-map->list cons h))))

(define-public find-runtime-type	(lambda (obj) obj))



;;;
;;; Miscellaneous.
;;;

(use-modules ((srfi srfi-19) #:renamer (symbol-prefix-proc 's19:)))

(define (date)
  (s19:date->string (s19:current-date) "~c"))



;;; compat.scm ends here
