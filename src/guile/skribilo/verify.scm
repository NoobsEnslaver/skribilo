;;; verify.scm  --  Skribe AST verification.
;;; -*- coding: iso-8859-1 -*-
;;;
;;; Copyright 2005, 2007, 2008, 2018  Ludovic Court�s <ludo@gnu.org>
;;; Copyright 2003, 2004  Erick Gallesio - I3S-CNRS/ESSI <eg@unice.fr>
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

(define-module (skribilo verify)
  :autoload   (skribilo engine) (engine-ident processor-get-engine)
  :autoload   (skribilo writer) (writer? writer-options lookup-markup-writer)
  :autoload   (skribilo lib)    (skribe-warning/ast)
  :use-module (skribilo debug)
  :use-module (skribilo ast)
  :use-module (skribilo condition)
  :use-module (skribilo utils syntax)
  :autoload   (skribilo location) (location?)

  :autoload   (srfi srfi-34)    (raise)
  :use-module (srfi srfi-35)

  :use-module (oop goops)

  :export (verify))


(skribilo-module-syntax)



;;;
;;; Error conditions.
;;;

(define-condition-type &verify-error &skribilo-error
  verify-error?)

(define-condition-type &unsupported-markup-option-error &verify-error
  unsupported-markup-option-error?
  (markup  unsupported-markup-option-error:markup)
  (engine  unsupported-markup-option-error:engine)
  (option  unsupported-markup-option-error:option))


(define (handle-verify-error c)
  ;; Issue a user-friendly error message for error condition C.
  (define (show-location obj)
    (let ((location (and (ast? obj) (ast-loc obj))))
      (if (location? location)
          (format (current-error-port) "~a:~a:~a: "
                  (location-file location)
                  (location-line location)
                  (location-column location)))))

  (cond ((unsupported-markup-option-error? c)
	 (let ((node   (unsupported-markup-option-error:markup c))
               (engine (unsupported-markup-option-error:engine c))
               (option (unsupported-markup-option-error:option c)))
           (show-location node)
	   (format (current-error-port)
                   (G_ "option '~a' of markup '~a' not supported by engine '~a'~%")
		   option (and (markup? node)
                               (markup-markup node))
                   (engine-ident engine))))

	(else
	 (format (current-error-port)
                 (G_ "undefined verify error: ~a~%")
		 c))))

(register-error-condition-handler! verify-error? handle-verify-error)


(define-generic verify)

;;;
;;; CHECK-REQUIRED-OPTIONS
;;;
(define (check-required-options markup writer engine)
  (let ((required-options (slot-ref markup 'required-options))
	(options	  (slot-ref writer 'options))
	(verified?	  (slot-ref writer 'verified?)))
    (or verified?
	(eq? options 'all)
	(begin
	  (for-each (lambda (o)
		      (if (not (memq o options))
                          (raise (condition (&unsupported-markup-option-error
                                             (markup markup)
                                             (option o)
                                             (engine engine))))))
		    required-options)
	  (slot-set! writer 'verified? #t)))))

;;;
;;; CHECK-OPTIONS
;;;
(define (check-options lopts markup engine)

  ;;  Only keywords are checked, symbols are voluntary left unchecked. */
  (with-debug 6 'check-options
      (debug-item "markup="  (markup-markup markup))
      (debug-item "options=" (slot-ref markup 'options))
      (debug-item "lopts="   lopts)
      (for-each
	  (lambda (o2)
	    (for-each
		(lambda (o)
		  (if (and (keyword? o)
			   (not (eq? o :&skribe-eval-location))
			   (not (memq o lopts)))
		      (skribe-warning/ast
		       3
		       markup
		       'verify
		       (format #f "engine ~a does not support markup ~a option '~a' -- ~a"
			       (engine-ident engine)
			       (markup-markup markup)
			       o
			       (markup-option markup o)))))
		o2))
	  (slot-ref markup 'options))))


;;; ======================================================================
;;;
;;;				V E R I F Y
;;;
;;; ======================================================================

;;; TOP
(define-method (verify (obj <top>) e)
  obj)

;;; PAIR
(define-method (verify (obj <pair>) e)
  (if (list? obj)
      (for-each (lambda (o) (verify o e)) obj)
      (begin
        (verify (car obj) e)
        (verify (cdr obj) e)))
  obj)

;;; PROCESSOR
(define-method (verify (obj <processor>) e)
  (let ((combinator (slot-ref obj 'combinator))
	(engine     (slot-ref obj 'engine))
	(body       (slot-ref obj 'body)))
    (verify body (processor-get-engine combinator engine e))
    obj))

;;; NODE
(define-method (verify (node <node>) e)
  ;; Verify body
  (verify (slot-ref node 'body) e)
  ;; Verify options
  (for-each (lambda (o) (verify (cadr o) e))
	    (slot-ref node 'options))
  node)

;;; MARKUP
(define-method (verify (node <markup>) e)
  (with-debug 5 'verify::<markup>
     (debug-item "node="    (markup-markup node))
     (debug-item "options=" (slot-ref node 'options))
     (debug-item "e="	    (engine-ident e))

     (next-method)

     (let ((w (lookup-markup-writer node e)))
       (when (writer? w)
	 (check-required-options node w e)
	 (when (pair? (writer-options w))
	   (check-options (slot-ref w 'options) node e))
	 (let ((validate (slot-ref w 'validate)))
	   (when (procedure? validate)
	     (unless (validate node e)
	       (skribe-warning/ast
		     1
		     node
		     (format #f "node '~a' forbidden here by ~a engine"
			     (markup-markup node)
			     (engine-ident e))))))))
     node))


;;; DOCUMENT
(define-method (verify (node <document>) e)
  (next-method)

  ;; verify the engine customs
  (for-each (lambda (c)
	      (let ((a (cadr c)))
		(set-car! (cdr c) (verify a e))))
	    (slot-ref e 'customs))

   node)

;;; verify.scm ends here
