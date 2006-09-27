;;; engine.scm	-- Skribilo engines.
;;;
;;; Copyright 2003, 2004  Erick Gallesio - I3S-CNRS/ESSI <eg@essi.fr>
;;; Copyright 2005, 2006  Ludovic Courtès  <ludovic.courtes@laas.fr>
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

(define-module (skribilo engine)
  :use-module (skribilo debug)
  :use-module (skribilo utils syntax)
  :use-module (skribilo lib)

  ;; `(skribilo writer)' depends on this module so it needs to be loaded
  ;; after we defined `<engine>' and the likes.
  :autoload (skribilo writer) (<writer>)

  :use-module (oop goops)
  :use-module (ice-9 optargs)
  :autoload   (srfi srfi-39)  (make-parameter)

  :export (<engine-class> engine-class? engine-class-ident
			  engine-class-format
			  engine-class-customs engine-class-filter
			  engine-class-symbol-table
			  copy-engine-class

	   <engine> engine? engine-custom
	            engine-custom-set! engine-custom-add!
		    engine-format?

		    engine-ident engine-format
		    engine-filter engine-symbol-table

	   *current-engine*
	   default-engine-class default-engine-class-set!
	   push-default-engine-class pop-default-engine-class

	   make-engine-class lookup-engine-class
	   make-engine copy-engine engine-class
	   engine-class-add-writer!

	   processor-get-engine

	   engine-class-loaded? when-engine-class-is-loaded
	   when-engine-is-instantiated))


(fluid-set! current-reader %skribilo-module-reader)


;;;
;;; Class definitions.
;;;

;; Note on writers
;; ---------------
;;
;; `writers' here is an `eq?' hash table where keys are markup names
;; (symbols) and values are lists of markup writers (most of the time, the
;; list will only contain one writer).  Each of these writer may define a
;; predicate or class that may further restrict its applicability.
;;
;; `free-writers' is a list of writers that may apply to *any* kind of
;; markup.  These are typically define by passing `#t' to `markup-writer'
;; instead of a symbol:
;;
;;   (markup-writer #f (find-engine 'xml)
;;     :before ...
;;     ...)
;;
;; The XML engine contains an example of such free writers.  Again, these
;; writers may define a predicate or a class restricting their applicability.
;;
;; The distinction between these two kinds of writers is mostly performance:
;; "free writers" are rarely used and markup-specific are the most common
;; case which we want to be fast.  Therefore, for the latter case, we can't
;; afford traversing a list of markups, evaluating each and every markup
;; predicate.
;;
;; For more details, see `markup-writer-get' and `lookup-markup-writer' in
;; `(skribilo writer)'.

(define-class <engine-class> (<class>)
  (ident		:init-keyword :ident		:init-value '???)
  (format		:init-keyword :format		:init-value "raw")
  (info		        :init-keyword :info		:init-value '())
  (version		:init-keyword :version
			:init-value 'unspecified)
  (delegate		:init-keyword :delegate		:init-value #f)
  (writers              :init-thunk make-hash-table)
  (free-writers         :init-value '())
  (filter		:init-keyword :filter		:init-value #f)
  (customs		:init-keyword :custom		:init-value '())
  (symbol-table		:init-keyword :symbol-table	:init-value '()))

(define-class <engine> (<object>)
  (customs	:init-keyword :customs	:init-value '())
  :metaclass <engine-class>)


(define %format format)
(define* (make-engine-class ident :key (version 'unspecified)
				       (format "raw")
				       (filter #f)
				       (delegate #f)
				       (symbol-table '())
				       (custom '())
				       (info '()))
  ;; We use `make-class' from `(oop goops)' (currently undocumented).
  (let ((e (make-class (list <engine>) '()
             :metaclass <engine-class>
             :name (symbol-append '<engine: ident '>)

	     :ident ident :version version :format format
	     :filter filter :delegate delegate
	     :symbol-table symbol-table
	     :custom custom :info info)))
    (%format (current-error-port) "make-engine-class returns ~a~%" e)
    e))

(define (engine-class? obj)
  (is-a? obj <engine-class>))

(define (engine-class-ident obj)
  (slot-ref obj 'ident))

(define (engine-class-format obj)
  (slot-ref obj 'format))

(define (engine-class-customs obj)
  (slot-ref obj 'customs))

(define (engine-class-filter obj)
  (slot-ref obj 'filter))

(define (engine-class-symbol-table obj)
  (slot-ref obj 'symbol-table))



;;;
;;; Engine instances.
;;;


(define (engine? obj)
  (is-a? obj <engine>))

(define (engine-class e)
  (and (engine? e) (class-of e)))

;; A mapping of engine classes to hooks.
(define %engine-instantiate-hook (make-hash-table))

(define-method (make-instance (class <engine-class>) . args)
  (define (initialize-engine! engine)
    ;; Automatically initialize the `customs' slot of the newly created
    ;; engine.
    (let ((init-values (engine-class-customs class)))
      (slot-set! engine 'customs (map list-copy init-values))
      engine))

  (format #t "making engine of class ~a~%" class)
  (let ((engine (next-method)))
    (if (engine? engine)
	(let ((hook (hashq-ref %engine-instantiate-hook class)))
	  (format (current-error-port) "engine made: ~a~%" engine)
          (initialize-engine! engine)
	  (if (hook? hook)
	      (run-hook hook engine class))
	  engine)
	engine)))

(define (make-engine engine-class)
  (make engine-class))


;; Convenience functions.

(define (engine-ident obj) (engine-class-ident (engine-class obj)))
(define (engine-format obj) (engine-class-format (engine-class obj)))
;;(define (engine-customs obj) (engine-class-customs (engine-class obj)))
(define (engine-filter obj) (engine-class-filter (engine-class obj)))
(define (engine-symbol-table obj)
  (engine-class-symbol-table (engine-class obj)))

(define (engine-format? fmt . e)
  (let ((e (cond
	     ((pair? e) (car e))
	     (else (*current-engine*)))))
    (if (not (engine? e))
	(skribe-error 'engine-format? "no engine" e)
	(string=? fmt (engine-format e)))))



;;;
;;; Writers.
;;;

(define (engine-class-add-writer! e ident pred upred opt before action
				  after class valid)
  ;; Add a writer to engine class E.  If IDENT is a symbol, then it should
  ;; denote a markup name and the writer being added is specific to that
  ;; markup.  If IDENT is `#t' (for instance), then it is assumed to be a
  ;; ``free writer'' that may apply to any kind of markup for which PRED
  ;; returns true.

  (define (check-procedure name proc arity)
    (cond
      ((not (procedure? proc))
	 (skribe-error ident "Illegal procedure" proc))
      ((not (equal? (%procedure-arity proc) arity))
	 (skribe-error ident
		       (format #f "Illegal ~S procedure" name)
		       proc))))

  (define (check-output name proc)
    (and proc (or (string? proc) (check-procedure name proc 2))))

  ;;
  ;; Engine-add-writer! starts here
  ;;
  (if (not (is-a? e <engine-class>))
      (skribe-error ident "Illegal engine" e))

  ;; check the options
  (if (not (or (eq? opt 'all) (list? opt)))
      (skribe-error ident "Illegal options" opt))

  ;; check the correctness of the predicate
  (if pred
      (check-procedure "predicate" pred 2))

  ;; check the correctness of the validation proc
  (if valid
      (check-procedure "validate" valid 2))

  ;; check the correctness of the three actions
  (check-output "before" before)
  (check-output "action" action)
  (check-output "after" after)

  ;; create a new writer and bind it
  (let ((n (make <writer>
	     :ident (if (symbol? ident) ident 'all)
	     :class class :pred pred :upred upred :options opt
	     :before before :action action :after after
	     :validate valid)))
    (if (symbol? ident)
	(let ((writers (slot-ref e 'writers)))
	  (hashq-set! writers ident
		      (cons n (hashq-ref writers ident '()))))
	(slot-set! e 'free-writers
		   (cons n (slot-ref e 'free-writers))))
    n))


;;;
;;; COPY-ENGINE
;;;
(define (copy-engine e)
  (let ((new (shallow-clone e)))
    (slot-set! new 'class   (engine-class e))
    (slot-set! new 'customs (list-copy (slot-ref e 'customs)))
    new))

(define* (copy-engine-class ident e :key (version 'unspecified)
					 (filter #f)
					 (delegate #f)
					 (symbol-table #f)
					 (custom #f))
  (let ((new (shallow-clone e)))
    (slot-set! new 'ident	 ident)
    (slot-set! new 'version	 version)
    (slot-set! new 'filter	 (or filter (slot-ref e 'filter)))
    (slot-set! new 'delegate	 (or delegate (slot-ref e 'delegate)))
    (slot-set! new 'symbol-table (or symbol-table (slot-ref e 'symbol-table)))
    (slot-set! new 'customs	 (or custom (slot-ref e 'customs)))

    ;; XXX: We don't use `list-copy' here because writer lists are only
    ;; consed, never mutated.

    ;(slot-set! new 'free-writers (list-copy (slot-ref e 'free-writers)))

    (let ((new-writers (make-hash-table)))
      (hash-for-each (lambda (m w*)
		       (hashq-set! new-writers m w*))
		     (slot-ref e 'writers))
      (slot-set! new 'writers new-writers))))


;;;
;;; Engine class loading.
;;;

;; Each engine is to be stored in its own module with the `(skribilo engine)'
;; hierarchy.  The `engine-id->module-name' procedure returns this module
;; name based on the engine name.

(define (engine-id->module-name id)
  `(skribilo engine ,id))

(define (engine-class-loaded? id)
  "Check whether engine @var{id} is already loaded."
  ;; Trick taken from `resolve-module' in `boot-9.scm'.
  (nested-ref the-root-module
	      `(%app modules ,@(engine-id->module-name id))))

;; A mapping of engine names to hooks.
(define %engine-class-load-hook (make-hash-table))

(define (consume-load-hook! id)
  (with-debug 5 'consume-load-hook!
    (let ((hook (hashq-ref %engine-class-load-hook id)))
      (if hook
	  (begin
	    (debug-item "running hook " hook " for engine " id)
	    (hashq-remove! %engine-class-load-hook id)
	    (run-hook hook))))))

(define (when-engine-class-is-loaded id thunk)
  "Run @var{thunk} only when engine with identifier @var{id} is loaded."
  (if (engine-class-loaded? id)
      (begin
	;; Maybe the engine had already been loaded via `use-modules'.
	(consume-load-hook! id)
	(thunk))
      (let ((hook (or (hashq-ref %engine-class-load-hook id)
		      (let ((hook (make-hook)))
			(hashq-set! %engine-class-load-hook id hook)
			hook))))
	(add-hook! hook thunk))))

(define (when-engine-is-instantiated engine-class proc)
  (let loop ((hook (hashq-ref %engine-instantiate-hook engine-class)))
    (if (not hook)
	(let ((hook (make-hook 2)))
	  (hashq-set! %engine-instantiate-hook engine-class hook)
	  (loop hook))
	(add-hook! hook proc))))


(define* (lookup-engine-class id :key (version 'unspecified))
  "Look for an engine named @var{name} (a symbol) in the @code{(skribilo
engine)} module hierarchy.  If no such engine was found, an error is raised,
otherwise the requested engine is returned."
  (with-debug 5 'lookup-engine
     (debug-item "id=" id " version=" version)

     (let* ((engine (symbol-append id '-engine))
	    (m (resolve-module (engine-id->module-name id))))
       (if (module-bound? m engine)
	   (let ((e (module-ref m engine)))
	     (if e (consume-load-hook! id))
	     e)
	   (error "no such engine" id)))))



;;;
;;; Engine methods.
;;;

(define (engine-custom e id)
  (let* ((customs (slot-ref e 'customs))
	 (c       (assq id customs)))
    (if (pair? c)
	(cadr c)
	'unspecified)))

(define (engine-custom-set! e id val)
  (let* ((customs (slot-ref e 'customs))
	 (c       (assq id customs)))
    (if (pair? c)
	(set-car! (cdr c) val)
	(slot-set! e 'customs (cons (list id val) customs)))))

(define (engine-custom-add! e id val)
   (let ((old (engine-custom e id)))
      (if (unspecified? old)
	  (engine-custom-set! e id (list val))
	  (engine-custom-set! e id (cons val old)))))

(define (processor-get-engine combinator newe olde)
  (cond
    ((procedure? combinator)
     (combinator newe olde))
    ((engine? newe)
     newe)
    (else
     olde)))



;;;
;;; Default engines.
;;;

(define *default-engine-classes*	'(html))

(define (default-engine-class)
  (let ((class (car *default-engine-classes*)))
    (cond ((symbol? class) (lookup-engine-class class))
	  (else class))))

(define (default-engine-class-set! e)
  (with-debug 5 'default-engine-set!
     (debug-item "engine=" e)

     (if (not (or (symbol? e) (engine-class? e)))
	 (skribe-error 'default-engine-class-set! "bad engine class ~S" e))
     (set-car! *default-engine-classes* e)
     e))


(define (push-default-engine-class e)
  (set! *default-engine-classes*
	(cons e *default-engine-classes*))
  e)

(define (pop-default-engine-class)
  (if (null? *default-engine-classes*)
      (skribe-error 'pop-default-engine-class "empty engine class stack" '())
      (set! *default-engine-classes* (cdr *default-engine-classes*))))



;;;
;;; Current engine.
;;;

;;; `(skribilo module)' must be loaded before the first `find-engine' call.
(use-modules (skribilo module))

;; At this point, we're almost done with the bootstrap process.
(format (current-error-port) "HERE~%")
(format #t "base engine: ~a~%" (lookup-engine-class 'base))
(format (current-error-port) "THERE~%")

(define *current-engine*
  ;; By default, use the HTML engine.
  (make-parameter #f ;'html ;(make-engine (lookup-engine-class 'html))
		  (lambda (val)
		    (cond ((symbol? val)
			   (make-engine (lookup-engine-class val)))
			  ((engine-class? val)
			   (make-engine val))
			  ((engine? val) val)
			  ((not val) val)
			  (else
			   (error "invalid value for `*current-engine*'"
				  val))))))


;;; engine.scm ends here
