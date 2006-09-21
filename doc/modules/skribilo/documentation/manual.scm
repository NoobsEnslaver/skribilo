;;; manual.scm  --  Skribe manuals and documentation pages style
;;;
;;; Copyright 2003, 2004  Manuel Serrano
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
;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;;; USA.

(define-module (skribilo documentation manual)
  :use-module (skribilo reader)
  :use-module (skribilo engine)
  :use-module (skribilo writer)
  :use-module (skribilo ast)
  :use-module (skribilo lib) ;; `define-markup'
  :use-module (skribilo resolve)
  :use-module (skribilo output)
  :use-module (skribilo utils keywords)
  :use-module (skribilo utils syntax) ;; `when'

  :use-module (skribilo documentation env)
  :use-module (skribilo package base)
  :use-module (skribilo prog)
  :use-module (skribilo coloring lisp)
  :use-module (skribilo coloring xml)

  :use-module (ice-9 optargs))

(fluid-set! current-reader (make-reader 'skribe))


;*---------------------------------------------------------------------*/
;*    The various indexes                                              */
;*---------------------------------------------------------------------*/
(define-public *markup-index* (make-index "markup"))
(define-public *custom-index* (make-index "custom"))
(define-public *function-index* (make-index "function"))
(define-public *package-index* (make-index "package"))

;*---------------------------------------------------------------------*/
;*    Base configuration                                               */
;*---------------------------------------------------------------------*/
(let ((be (lookup-engine-class 'base)))
   (markup-writer 'example be
      :options '(:legend :number)
      :action (lambda (n e)
		 (let ((ident (markup-ident n))
		       (number (markup-option n :number))
		       (legend (markup-option n :legend)))
		    (skribe-eval (mark ident) e)
		    (skribe-eval (center
				  (markup-body n)
				  (if number
				      (bold (format #f "Ex. ~a: " number)))
				  legend)
				 e)))))

;*---------------------------------------------------------------------*/
;*    html-browsing-extra ...                                          */
;*---------------------------------------------------------------------*/
(define (html-browsing-extra n e)
   (let ((i1 (let ((m (find-markup-ident "Index")))
		(and (pair? m) (car m))))
	 (i2 (let ((m (find-markup-ident "markups-index")))
		(and (pair? m) (car m)))))
      (cond
	 ((not i1)
	  (skribe-error 'left-margin "Can't find section" "Index"))
	 ((not i2)
	  (skribe-error 'left-margin "Can't find chapter" "Standard Markups"))
	 (else
	  (table :width 100.
	     :border 0
	     :cellspacing 0 :cellpadding 0
	     (tr (td :align 'left :valign 'top (bold "index:"))
		(td :align 'right (ref :handle (handle i1) :text "Global")))
	     (tr (td :align 'left :valign 'top (bold "markups:"))
		(td :align 'right (ref :handle (handle i2) :text "Index")))
	     (tr (td :align 'left :valign 'top (bold "extensions:"))
		(td :align 'right (ref :url *skribe-dir-doc-url* 
				     :text "Directory"))))))))

;*---------------------------------------------------------------------*/
;*    Html configuration                                               */
;*---------------------------------------------------------------------*/
(let* ((he (lookup-engine-class 'html))
       (bd (markup-writer-get 'bold he)))
   (markup-writer 'bold he
		  :class 'api-proto-ident
		  :before "<font color=\"red\">"
		  :action (lambda (n e) (output n e bd))
		  :after "</font>")
   (engine-custom-set! he 'web-book-main-browsing-extra html-browsing-extra)
   (engine-custom-set! he 'favicon "lambda.gif"))

;*---------------------------------------------------------------------*/
;*    LaTeX                                                            */
;*---------------------------------------------------------------------*/
(let* ((le (lookup-engine-class 'latex))
       (opckg (engine-custom le 'usepackage))
       (lpckg "\\usepackage{fullpage}\n\\usepackage{eurosym}\n")
       (npckg (if (string? opckg)
		  (string-append lpckg opckg)
		  lpckg)))
   (engine-custom-set! le 'documentclass "\\documentclass{book}")
   (engine-custom-set! le 'usepackage npckg))

;*---------------------------------------------------------------------*/
;*    prgm ...                                                         */
;*---------------------------------------------------------------------*/
(define-markup (prgm #!rest opts #!key (language skribe) (line #f) (file #f) (definition #f))
   (let* ((c (cond
		((eq? language skribe) *prgm-skribe-color*)
		((eq? language xml) *prgm-xml-color*)
		(else *prgm-default-color*)))
	  (sc (cond
		 ((and file definition)
		  (source :language language :file file :definition definition))
		 (file
		  (source :language language :file file))
		 (else
		  (source :language language (the-body opts)))))
	  (pr (cond
		 (line
		  (prog :line line sc))
		 (else
		  (pre sc)))))
      (center
       (frame :margin 5 :border 0 :width *prgm-width*
	      (color :margin 5 :width 100. :bg c pr)))))

;*---------------------------------------------------------------------*/
;*    disp ...                                                         */
;*---------------------------------------------------------------------*/
(define-markup (disp #!rest opts #!key (verb #f) (line #f) (bg *disp-color*))
   (if (engine-format? "latex")
       (if verb 
	   (pre (the-body opts))
	   (the-body opts))
       (center
	  (frame :margin 5 :border 0 :width *prgm-width*
	     (color :margin 5 :width 100. :bg bg
		(if verb 
		    (pre (the-body opts))
		    (the-body opts)))))))

;*---------------------------------------------------------------------*/
;*    keyword ...                                                      */
;*---------------------------------------------------------------------*/
(define-markup (keyword arg)
   (new markup
      (markup '&source-key)
      (body (cond
	       ((keyword? arg)
		(with-output-to-string
		  (lambda ()
		    (write arg))))
	       ((symbol? arg)
		(string-append ":" (symbol->string arg)))
	       (else
		arg)))))

;*---------------------------------------------------------------------*/
;*    param ...                                                        */
;*---------------------------------------------------------------------*/
(define-markup (param arg)
   (cond
      ((keyword? arg)
       (keyword arg))
      ((symbol? arg)
       (code (symbol->string arg)))
      (else
       arg)))

;*---------------------------------------------------------------------*/
;*    example ...                                                      */
;*---------------------------------------------------------------------*/
(define-markup (example #!rest opts #!key legend class)
   (new container
      (markup 'example)
      (ident (symbol->string (gensym "example")))
      (class class)
      (required-options '(:legend :number))
      (options `((:number
		  ,(new unresolved
		      (proc (lambda (n e env)
			       (resolve-counter n env 'example #t)))))
		 ,@(the-options opts :ident :class)))
      (body (the-body opts))))

;*---------------------------------------------------------------------*/
;*    example-produce ...                                              */
;*---------------------------------------------------------------------*/
(define-markup (example-produce example . produce)
   (list (it "Example:")
	 example
	 (if (pair? produce)
	     (list (paragraph "Produces:") (car produce)))))

;*---------------------------------------------------------------------*/
;*    markup-ref ...                                                   */
;*---------------------------------------------------------------------*/
(define-markup (markup-ref mk)
   (ref :mark mk :text (code mk)))

;*---------------------------------------------------------------------*/
;*    &the-index ...                                                   */
;*---------------------------------------------------------------------*/
(markup-writer '&the-index
   :class 'markup-index
   :options '(:column)
   :before (lambda (n e)
	      (output (markup-option n 'header) e))
   :action (lambda (n e)
	      (define (make-mark-entry n fst)
		 (let ((l (tr :class 'index-mark-entry
			     (td :colspan 2 :align 'left 
				(bold (it (sf n)))))))
		    (if fst
			(list l)
			(list (tr (td :colspan 2)) l))))
	      (define (make-primary-entry n p)
		 (let* ((note (markup-option n :note))
			(b (markup-body n)))
		    (when p 
		       (markup-option-add! b :text 
					   (list (markup-option b :text) 
						 ", p."))
		       (markup-option-add! b :page #t))
		    (tr :class 'index-primary-entry
		       (td :colspan 2 :valign 'top :align 'left b))))
	      (define (make-column ie p)
		 (let loop ((ie ie)
			    (f #t))
		    (cond
		       ((null? ie)
			'())
		       ((not (pair? (car ie)))
			(append (make-mark-entry (car ie) f) 
				(loop (cdr ie) #f)))
		       (else
			(cons (make-primary-entry (caar ie) p)
			      (loop (cdr ie) #f))))))
	      (define (make-sub-tables ie nc p)
		 (define (split-list l num)
		    (let loop ((l l)
			       (i 0)
			       (acc '())
			       (res '()))
		       (cond
			  ((null? l)
			   (reverse! (cons (reverse! acc) res)))
			  ((= i num)
			   (loop l
				 0
				 '()
				 (cons (reverse! acc) res)))
			  (else
			   (loop (cdr l)
				 (+ i 1)
				 (cons (car l) acc)
				 res)))))
		 (let* ((l (length ie))
			(w (/ 100. nc))
			(iepc (let ((d (/ l nc)))
				 (if (integer? d) 
				     (inexact->exact d)
				     (+ 1 (inexact->exact (truncate d))))))
			(split (split-list ie iepc)))
		    (tr (map (lambda (ies)
				(td :valign 'top :width w
				   (if (pair? ies)
				       (table :width 100. (make-column ies p))
				       "")))
			     split))))
	      (let* ((ie (markup-body n))
		     (nc (markup-option n :column))
		     (pref (eq? (engine-custom e 'index-page-ref) #t))
		     (loc (ast-loc n))
		     ;; FIXME: Since we don't support
		     ;; `:&skribe-eval-location', we could set up a
		     ;; `parameterize' thing around `skribe-eval' to provide
		     ;; it with the right location information.
		     (t (cond
			   ((null? ie)
			    "")
			   ((or (not (integer? nc)) (= nc 1))
			    (table :width 100. ;;:&skribe-eval-location loc
			       (make-column ie pref)))
			   (else
			    (table :width 100. ;;:&skribe-eval-location loc
			       (make-sub-tables ie nc pref))))))
		 (output (skribe-eval t e) e))))

;*---------------------------------------------------------------------*/
;*    compiler-command ...                                             */
;*---------------------------------------------------------------------*/
(define-markup (compiler-command bin . opts)
   (disp :verb #t 
	 (color :fg "red" (bold bin))
	 (map (lambda (o)
		 (list " [" (it o) "]"))
	      opts)
	 "..."))

;*---------------------------------------------------------------------*/
;*    compiler-options ...                                             */
;*---------------------------------------------------------------------*/
(define-markup (compiler-options bin)
   (skribe-message "  [executing: ~a --options]\n" bin)
   (let ((port (open-input-file (format #f "| ~a --options" bin))))
      (let ((opts (read port)))
	 (close-input-port port)
	 (apply description (map (lambda (opt) (item :key (bold (car opt))
						     (cadr opt) "."))
				 opts)))))
