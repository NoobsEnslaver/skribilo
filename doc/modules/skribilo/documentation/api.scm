;;; api.scm  --  The style for documenting Scheme APIs.
;;;
;;; Copyright 2003, 2004  Manuel Serrano
;;; Copyright 2005, 2006, 2007  Ludovic Court�s <ludovic.courtes@laas.fr>
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

(define-module (skribilo documentation api)
  :use-module (skribilo reader)
  :use-module (skribilo engine)
  :use-module (skribilo writer)
  :use-module (skribilo ast)
  :use-module (skribilo output)
  :use-module (skribilo lib) ;; `define-markup'
  :use-module (skribilo utils compat)
  :use-module (skribilo utils syntax) ;; `%skribilo-module-reader'

  :use-module (skribilo package base)
  :use-module (skribilo documentation manual) ;; `*markup-index*'
  :use-module (skribilo documentation env) ;; `*api-engines*'

  :use-module (srfi srfi-1)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs))

(fluid-set! current-reader %skribilo-module-reader)


;*---------------------------------------------------------------------*/
;*    Html configuration                                               */
;*---------------------------------------------------------------------*/
(let* ((he (find-engine 'html))
       (tro (markup-writer-get 'tr he)))
   (markup-writer 'tr he
      :class 'api-table-header
      :options '(:width :bg)
      :action (lambda (n e)
		 (let ((c (engine-custom e 'section-title-background)))
		    (markup-option-add! n :bg c)
		    (output n e tro))))
   (markup-writer 'tr he
      :class 'api-table-prototype
      :options '(:width :bg)
      :action (lambda (n e)
		 (let ((c (engine-custom e 'title-background)))
		    (markup-option-add! n :bg c)
		    (output n e tro))))
   (markup-writer 'tr he
      :class 'api-symbol-prototype
      :options '(:width :bg)
      :action (lambda (n e)
		 (let ((c (engine-custom e 'title-background)))
		    (markup-option-add! n :bg c)
		    (output n e tro)))))

;*---------------------------------------------------------------------*/
;*    LaTeX configuration                                              */
;*---------------------------------------------------------------------*/
(let* ((le (find-engine 'latex))
       (tro (markup-writer-get 'tr le)))
   (markup-writer 'tr le
      :class 'api-table-prototype
      :options '(:width :bg)
      :action #f)
   (markup-writer 'tr le
      :class 'api-table-header
      :options '(:width :bg)
      :action (lambda (n e)
		 (let ((c (engine-custom e 'section-title-background)))
		    (markup-option-add! n :bg c)
		    (output n e tro)))))

;*---------------------------------------------------------------------*/
;*    api-search-definition ...                                        */
;*    -------------------------------------------------------------    */
;*    Find a definition inside a source file.                          */
;*---------------------------------------------------------------------*/
(define* (api-search-definition id file pred :optional (skribe-source? #t))
   ;; If SKRIBE-SOURCE? is true, then assume Skribe syntax.  Otherwise, use
   ;; the ``Skribilo module syntax''.
   (let* ((path (append %load-path (skribe-path)))
	  (f (find-file/path file path))
	  (read (if skribe-source? (make-reader 'skribe)
		    %skribilo-module-reader)))
      (if (not (string? f))
	  (skribe-error 'api-search-definition
			(format #f "can't find source file `~a' in path"
				file)
			path)
	  (with-input-from-file f
	     (lambda ()
		(let loop ((exp (read)))
		   (if (eof-object? exp)
		       (skribe-error 'api-search-definition
				     (format #f
					     "can't find `~a' definition" id)
				     file)
		       (or (pred id exp) (loop (read))))))))))

;*---------------------------------------------------------------------*/
;*    api-compare-set ...                                              */
;*    -------------------------------------------------------------    */
;*    This function compares two sets. It returns either #t            */
;*    is they are equal, or two subsets which contain elements         */
;*    not present in the arguments. For instance:                      */
;*      (api-compare-set '(foo bar) '(bar foo)) ==> #t                 */
;*      (api-compare-set '(foo gee) '(gee bar)) ==> '((foo) (bar))     */
;*---------------------------------------------------------------------*/
(define (api-compare-set s1 s2)
   (let ((d1 (filter (lambda (x) (not (memq x s2))) s1))
	 (d2 (filter (lambda (x) (not (memq x s1))) s2)))
      (or (and (null? d1) (null? d2))
	  (list d1 d2))))


;*---------------------------------------------------------------------*/
;*    define-markup? ...                                               */
;*---------------------------------------------------------------------*/
(define (define-markup? id o)
   (match o
      (((or 'define-markup 'define 'define* 'define-public 'define*-public)
	((? (lambda (x) (eq? x id)))
	 . (? (lambda (x) (or (pair? x) (null? x)))))
	. _)
       o)
      (('define-simple-markup (? (lambda (x) (eq? x id))))
       o)
      (('define-simple-container (? (lambda (x) (eq? x id))))
       o)
      (else
       #f)))

;*---------------------------------------------------------------------*/
;*    make-engine? ...                                                 */
;*---------------------------------------------------------------------*/
(define (make-engine? id o)
   ;(format #t "make-engine? ~a ~a~%" id o)
   (match o
      (((or 'make-engine 'copy-engine) ('quote sym) . rest)
       (if (eq? sym id)
	   o
	   #f))
      ((exp ___)
       (let ((exp exp))
	 (cond ((null? exp)
		#f)
	       ((pair? exp)
		(or (make-engine? id (car exp))
		    (make-engine? id (cdr exp))))
	       (else
		(make-engine? id exp)))))
      (else
       #f)))

;*---------------------------------------------------------------------*/
;*    make-engine-custom ...                                           */
;*---------------------------------------------------------------------*/
(define (make-engine-custom def)
  (let ((customs (memq :custom def)))
    (match (if customs (cdr customs) #f)
      ((((or 'quote 'quasiquote) custom) _ ___)
       custom)
      (((custom) _ ___)
       (primitive-eval custom))
      (else
       '()))))

;*---------------------------------------------------------------------*/
;*    define-markup-formals ...                                        */
;*    -------------------------------------------------------------    */
;*    Returns the formal parameters of a define-markup (not the        */
;*    options).                                                        */
;*---------------------------------------------------------------------*/
(define (define-markup-formals def)
   (match def
      ((_ (id args ___) _ ___)
       (let loop ((args args)
		  (res '()))
	 (cond
	  ((null? args)
	   (reverse! res))
	  ((symbol? args)
	   (reverse! (cons args res)))
	  ((not (symbol? (car args)))
	   (reverse! res))
	  (else
	   (loop (cdr args) (cons (car args) res))))))
      (('define-simple-markup _)
       '())
      (('define-simple-container _)
       '())
      (else
       (skribe-error 'define-markup-formals
		     "Illegal `define-markup' form"
		     def))))

;*---------------------------------------------------------------------*/
;*    define-markup-options ...                                        */
;*    -------------------------------------------------------------    */
;*    Returns the options parameters of a define-markup.               */
;*---------------------------------------------------------------------*/
(define (define-markup-options def)
   (match def
      ((_ (args ___) _ ___)
       (if (not (list? args))
	   '()
	   (let ((keys (memq :key args)))
	      (if (pair? keys)
		  (cdr keys) ;; FIXME: do we need to filter ((key val)...)?
		  '()))))
      (('define-simple-markup _)
       '((ident #f) (class #f)))
      (('define-simple-container _)
       '((ident #f) (class #f)))
      (else
       (skribe-error 'define-markup-options
		     "Illegal `define-markup' form"
		     def))))

;*---------------------------------------------------------------------*/
;*    define-markup-rest ...                                           */
;*    -------------------------------------------------------------    */
;*    Returns the rest parameter of a define-markup.                   */
;*---------------------------------------------------------------------*/
(define (define-markup-rest def)
   (match def
      ((_ (args ___) _)
       (if (not (pair? args))
	   args
	   (let ((l (last-pair args)))
	      (if (symbol? (cdr l))
		  (cdr l)
		  (let ((rest (memq :rest args)))
		     (if (pair? rest)
			 (if (or (not (pair? (cdr rest)))
				 (not (symbol? (cadr rest))))
			     (skribe-error 'define-markup-rest
					   "Illegal `define-markup' form"
					   def)
			     (cadr rest))
			 #f))))))
      (('define-simple-markup _)
       'node)
      (('define-simple-container _)
       'node)
      (else
       (skribe-error 'define-markup-rest
		     "Illegal `define-markup' form"
		     def))))

;*---------------------------------------------------------------------*/
;*    doc-check-arguments ...                                          */
;*---------------------------------------------------------------------*/
(define %undocumented-options
  ;; Special markup options that don't need to be documented.
  (list (symbol->keyword '&location)
        (string->symbol ":&location")
        '&location))

(define (doc-check-arguments id args dargs)
   (if (not args)
       (skribe-error 'doc-check-arguments id args))
   (if (not dargs)
       (skribe-error 'doc-check-arguments id dargs))
   (let* ((s1 (reverse! (fold (lambda (x res)
                                (let ((x (if (pair? x) (car x) x)))
                                  (if (memq x %undocumented-options)
                                      res
                                      (cons x res))))
                              '()
                              args)))
	  (s2 (map (lambda (x)
		      (let ((i (car x)))
			 (if (keyword? i)
			     (keyword->symbol i)
			     i)))
		   dargs))
	  (d (api-compare-set s1 s2)))
      (if (pair? d)
	  (let ((d1 (car d))
		(d2 (cadr d)))
	     (if (pair? d1)
		 (skribe-error 'doc-markup 
			       (format #f "~a: missing descriptions" id)
			       d1)
		 (skribe-error 'doc-markup 
			       (format #f "~a: extra descriptions" id)
			       d2))))))

;*---------------------------------------------------------------------*/
;*    exp->skribe ...                                                  */
;*---------------------------------------------------------------------*/
(define (exp->skribe exp)
   (cond
      ((number? exp) exp)
      ((string? exp) (string-append "\"" exp "\""))
      ((eq? exp #f) "#f")
      ((eq? exp #t) "#t")
      ((symbol? exp) (symbol->string exp))
      ((equal? exp '(quote ())) "'()")
      ((ast? exp) 
       (table :cellpadding 0 :cellspacing 0 
	  (tr (td :align 'left exp))))
      (else 
       (match exp
	  ((and sym (? symbol?))
	   (string-append "'" (symbol->string sym)))
	  (else
	   (with-output-to-string (lambda () (write exp))))))))

;*---------------------------------------------------------------------*/
;*    doc-markup-proto ...                                             */
;*---------------------------------------------------------------------*/
(define (doc-markup-proto id options formals rest)
   (define (option opt)
      (if (pair? opt)
	  (if (eq? (cadr opt) #f)
	      (list " [" (keyword (car opt)) "]")
	      (list " [" (keyword (car opt)) " " 
		    (code (exp->skribe (cadr opt))) "]"))
	  (list " " (keyword opt))))
   (define (formal f)
      (list " " (param f)))
   (code (list (bold "(") (bold :class 'api-proto-ident
				(format #f "~a" id)))
	 (map option (sort options 
			   (lambda (s1 s2)
			      (cond
				 ((and (pair? s1) (not (pair? s2)))
				  #f)
				 ((and (pair? s2) (not (pair? s1)))
				  #t)
				 (else
				  #t)))))
	 (if (pair? formals)
	     (map formal formals))
	 (if rest (list " " (param rest)))
	 (bold ")")))

;*---------------------------------------------------------------------*/
;*    doc-markup ...                                                   */
;*---------------------------------------------------------------------*/
(define-markup (doc-markup id args
			   :rest
			   opts
			   :key
			   (ident #f)
			   (writer-id #f)
			   (common-args '((:ident "The node identifier.")
					  (:class "The node class.")))
			   (ignore-args '(&skribe-eval-location))
			   (force-args '())
			   (idx *markup-index*)
			   (idx-note "definition")
		           (idx-suffix #f)
			   (source "skribilo/package/base.scm")
			   (def #f)
			   (see-also '())
			   (others '())
			   (force-engines '())
			   (engines *api-engines*)
			   (sui #f)
			   (skribe-source? #t)
			   &skribe-eval-location)
   (define (opt-engine-support opt)
      ;; find the engines providing a writer for id
      (map (lambda (e)
	      (let* ((id (engine-ident e))
		     (s (symbol->string id)))
		 (if (engine-format? "latex")
		     (list s " ")
		     (list (if sui
			       (ref :skribe sui 
				  :mark (string-append s "-engine") 
				  :text s)
			       (ref :mark (string-append s "-engine") 
				  :text s))
			   " "))))
	   (if (pair? force-engines) 
	       force-engines 
	       (filter (lambda (e)
			  (or (memq opt '(:ident :class))
			      (memq opt force-args)
			      (let ((w (markup-writer-get (or writer-id id)
							  e)))
				 (cond
				    ((not (writer? w))
				     #f)
				    (else
				     (let ((o (writer-options w)))
					(cond
					   ((eq? o 'all)
					    #t)
					   ((not (pair? o))
					    #f)
					   (else
					    (memq opt o)))))))))
		       engines))))
   (cond
      ((and def source)
       (skribe-error 'doc-markup "source and def both specified" id))
      ((and (not def) (not source))
       (skribe-error 'doc-markup "source or def must be specified" id))
      (else
       (let* ((d (or def (api-search-definition id source define-markup?
						skribe-source?)))
	      (od (map (lambda (o)
			  (api-search-definition o source define-markup?
						 skribe-source?))
		       others))
	      (args (append common-args args))
	      (formals (define-markup-formals d))
	      (fformals (filter (lambda (s)
				   (let ((c (assq s args)))
				      (not 
				       (and (pair? c) 
					    (eq? (cadr c) 'ignore)))))
				formals))
	      (options (filter (lambda (s)
				  (not (memq s ignore-args)))
			       (define-markup-options d)))
	      (dformals (filter (lambda (x) 
				   (symbol? (car x)))
				args))
	      (doptions (filter (lambda (x) 
				   (and (keyword? (car x))
					;; useful for STklos only
					(not (eq? (car x) :rest))))
				args))
	      (drest (filter (lambda (x) 
				(eq? :rest (car x))) 
			     args))
	      (dargs (and (pair? drest) (cadr (car drest))))
	      (p+ (cons (doc-markup-proto id options fformals dargs)
			(map (lambda (id def)
				(doc-markup-proto 
				 id 
				 (define-markup-options def)
				 (define-markup-formals def)
				 dargs))
			     others od))))
	  ;; doc table
	  (define (doc-markup.html)
	     (let ((df (map (lambda (f)
			       (tr :bg *prgm-skribe-color*
				  (td :colspan 2 :width 20. :align 'left
				     (param (car f)) )
				  (td :align 'left :width 80. (cadr f))))
			    dformals))
		   (dr (and (pair? drest)
			    (tr :bg *prgm-skribe-color*
			       (td :align 'left 
				  :valign 'top
				  :colspan 2 
				  :width 20.
				  (param (cadr (car drest))))
			       (td :align 'left :width 80. 
				  (caddr (car drest))))))
		   (do (map (lambda (f)
			       (tr :bg *prgm-skribe-color*
				  (td :align 'left 
				     :valign 'top
				     :width 10.
				     (param (car f)))
				  (td :align 'left 
				     :valign 'top
				     :width 20.
				     (opt-engine-support (car f)))
				  (td :align 'left :width 70. (cadr f))))
			    doptions))
		   (so (map (lambda (x)
			       (let ((s (symbol->string x)))
				  (list 
				   (ref :mark s :text (code s))
				   " ")))
			    see-also)))
		(table :&location &invocation-location
                   :border (if (engine-format? "latex") 1 0)
		   :width (if (engine-format? "latex") #f *prgm-width*)
		   `(,(tr :class 'api-table-prototype
			 (th :colspan 3 :align 'left :width *prgm-width*
			    "prototype"))
		     ,@(map (lambda (p)
			       (tr :bg *prgm-skribe-color*
				  (td :colspan 3 :width *prgm-width*
				     :align 'left  p)))
			    p+)
		     ,@(if (pair? do)
			   `(,(tr :class 'api-table-header
				 (th :align 'left "option" 
				    :width 10.) 
				 (th :align 'center "engines"
				    :width 20.)
				 (th "description"))
			     ,@do)
			   '())
		     ,@(if (or (pair? df) dr)
			   `(,(tr :class 'api-table-header
				 (th :colspan 2 
				    :align 'left 
				    :width 30.
				    "argument") 
				 (th "description"))
			     ,@(if (pair? df) df '())
			     ,@(if dr (list dr) '()))
			   '())
		     ,@(if (pair? so)
			   `(,(tr :class 'api-table-header
				 (th :colspan 3 :align 'left 
				    (it "See also")))
			     ,(tr :bg *prgm-skribe-color*
				 (td :colspan 3 :align 'left so)))
			   '())))))
	  ;; doc enumerate
	  (define (doc-markup.latex)
	     (let ((df (map (lambda (f)
			       (item :key (param (car f)) (cadr f)))
			    dformals))
		   (dr (if (pair? drest)
			   (list (item :key (param (cadr (car drest))) 
				    (caddr (car drest))))
			   '()))
		   (do (map (lambda (f)
			       (item :key (param (car f))
				  (list (opt-engine-support (car f))
					(cadr f))))
			    doptions))
		   (so (map (lambda (x)
			       (let ((s (symbol->string x)))
				  (list 
				   (ref :mark s :page #t 
				      :text (list (code s) ", p."))
				   " ")))
			    see-also)))
		(list (center 
			 (frame :margin 5 :border 0 :width *prgm-width*
			    (color :class 'api-table-prototype
			       :margin 5 :width 100. :bg "#ccccff"
			       p+)))
		      (when (pair? do)
			 (subsubsection :title "Options" :number #f :toc #f
			    (description do)))
		      (when (or (pair? df) (pair? dr))
			 (subsubsection :title "Parameters" :number #f :toc #f
			    (description (append df dr))))
		      (when (pair? so)
			 (subsubsection :title "See also" :number #f :toc #f
			    (p so)
			    (! "\\noindent"))))))
	  ;; check all the descriptions
	  (doc-check-arguments id formals dformals)
	  (doc-check-arguments id options doptions)
	  (if (and (pair? drest) (not (define-markup-rest d)))
	      (skribe-error 'doc-markup "No rest argument for" id)
	      options)
	  (list (mark :class "public-definition"
		      (or ident (symbol->string id)))
		(map (lambda (i) (mark (symbol->string i))) others)
		(map (lambda (i)
			(let ((is (symbol->string i)))
			   (index (if (string? idx-suffix)
				      (string-append is idx-suffix)
				      is)
			      :index idx
			      :note idx-note)))
		     (cons id others))
		(cond
		   ((engine-format? "latex")
		    (doc-markup.latex))
		   (else
		    (center (doc-markup.html)))))))))

;*---------------------------------------------------------------------*/
;*    doc-engine ...                                                   */
;*---------------------------------------------------------------------*/
(define-markup (doc-engine id args
			   :rest 
			   opts
			   :key 
			   (idx *custom-index*)
			   source
			   (skribe-source? #t)
			   (def #f))
   (cond
      ((and def source)
       (skribe-error 'doc-engine "source and def both specified" id))
      ((and (not def) (not source))
       (skribe-error 'doc-engine "source or def must be specified" id))
      (else
       (let* ((d (or def (api-search-definition id source make-engine?
						skribe-source?)))
	      (c (make-engine-custom d)))
	  (doc-check-arguments id c args)
	  (cond
	     ((engine-format? "latex")
	      #f)
	     (else
	      (center
		 (apply table
                        :&location &invocation-location
			:width *prgm-width*
			(tr :class 'api-table-header
			   (th :align 'left :width 20. "custom")
			   (th :width 10. "default")
			   (th "description"))
			(map (lambda (r)
				(tr :bg *prgm-skribe-color*
				   (td :align 'left :valign 'top
				      (list (index (symbol->string (car r))
					       :index idx
					       :note (format #f "~a custom"
							     id))
					    (symbol->string (car r))))
				   (let ((def (assq (car r) c)))
				      (td :valign 'top
					 (code (exp->skribe (cadr def)))))
				   (td :align 'left :valign 'top (cadr r))))
			     (filter cadr args))))))))))
	  
