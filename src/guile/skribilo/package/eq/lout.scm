;;; lout.scm  --  Lout implementation of the `eq' package.
;;;
;;; Copyright 2005, 2006  Ludovic Court�s <ludovic.courtes@laas.fr>
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

(define-module (skribilo package eq lout)
  :use-module (skribilo package eq)
  :use-module (skribilo ast)
  :autoload   (skribilo output) (output)
  :use-module (skribilo writer)
  :use-module (skribilo engine)
  :use-module (skribilo lib)
  :use-module (skribilo utils syntax)
  :use-module (skribilo utils keywords) ;; `the-options', etc.
  :use-module (ice-9 optargs))

(fluid-set! current-reader %skribilo-module-reader)



;;;
;;; Initialization.
;;;

(when-engine-is-instantiated (lookup-engine-class 'lout)
  (lambda (lout class)
    (let ((includes (engine-custom lout 'includes)))
      ;; Append the `eq' include file
      (engine-custom-set! lout 'includes
			  (string-append includes "\n"
					 "@SysInclude { eq }\n")))))


;;;
;;; Simple markup writers.
;;;


(markup-writer 'eq (lookup-engine-class 'lout)
   :options '(:inline?)
   :before "{ "
   :action (lambda (node engine)
	     (display (if (markup-option node :inline?)
			  "@E { "
			  "@Eq { "))
	     (let ((eq (markup-body node)))
	       ;;(fprint (current-error-port) "eq=" eq)
	       (output eq engine)))
   :after  " } }")



(define-macro (simple-lout-markup-writer sym . args)
  (let* ((lout-name (if (null? args)
			(symbol->string sym)
			(car args)))
	 (parentheses? (if (or (null? args) (null? (cdr args)))
			   #t
			   (cadr args)))
	 (precedence (operator-precedence sym))

	 ;; Note: We could use `pmatrix' here but it precludes line-breaking
	 ;; within equations.
	 (open-par `(if need-paren? "{ @VScale ( }" ""))
	 (close-par `(if need-paren? "{ @VScale ) }" "")))

    `(markup-writer ',(symbol-append 'eq: sym)
		    (lookup-engine-class 'lout)
		    :action (lambda (node engine)
			      (let loop ((operands (markup-body node)))
				(if (null? operands)
				    #t
				    (let* ((op (car operands))
					   (eq-op? (equation-markup? op))
					   (need-paren?
					    (and eq-op?
						 (< (operator-precedence
						     (equation-markup-name->operator
						      (markup-markup op)))
						    ,precedence)))
					   (column (port-column
						    (current-output-port))))

				      ;; Work around Lout's limitations...
				      (if (> column 1000) (display "\n"))

				      (display (string-append " { "
							      ,(if parentheses?
								   open-par
								   "")))
				      (output op engine)
				      (display (string-append ,(if parentheses?
								   close-par
								   "")
							      " }"))
				      (if (pair? (cdr operands))
					  (display ,(string-append " "
								   lout-name
								   " ")))
				      (loop (cdr operands)))))))))


;; `+' and `*' have higher precedence than `-', `/', `=', etc., so their
;; operands do not need to be enclosed in parentheses.  OTOH, since we use a
;; horizontal bar of `/', we don't need to parenthesize its arguments.


(simple-lout-markup-writer +)
(simple-lout-markup-writer * "times")
(simple-lout-markup-writer - "-")
(simple-lout-markup-writer / "over" #f)
(simple-lout-markup-writer =)
(simple-lout-markup-writer <)
(simple-lout-markup-writer >)
(simple-lout-markup-writer <=)
(simple-lout-markup-writer >=)

(define-macro (binary-lout-markup-writer sym lout-name)
  `(markup-writer ',(symbol-append 'eq: sym) (lookup-engine-class 'lout)
     :action (lambda (node engine)
	       (let ((body (markup-body node)))
		 (if (= (length body) 2)
		     (let* ((first (car body))
			    (second (cadr body))
			    (parentheses? (equation-markup? first)))
		       (display " { { ")
		       (if parentheses? (display "("))
		       (output first engine)
		       (if parentheses? (display ")"))
		       (display ,(string-append " } " lout-name " { "))
		       (output second engine)
		       (display " } } "))
		     (skribe-error ,(symbol-append 'eq: sym)
				   "wrong number of arguments"
				   body))))))

(binary-lout-markup-writer expt "sup")
(binary-lout-markup-writer in "element")
(binary-lout-markup-writer notin "notelement")

(markup-writer 'eq:apply (lookup-engine-class 'lout)
   :action (lambda (node engine)
	     (let ((func (car (markup-body node))))
	       (output func engine)
	       (display "(")
	       (let loop ((operands (cdr (markup-body node))))
		 (if (null? operands)
		     #t
		     (begin
		       (output (car operands) engine)
		       (if (not (null? (cdr operands)))
			   (display ", "))
		       (loop (cdr operands)))))
	       (display ")"))))



;;;
;;; Sums, products, integrals, etc.
;;;

(define-macro (range-lout-markup-writer sym lout-name)
  `(markup-writer ',(symbol-append 'eq: sym) (lookup-engine-class 'lout)
      :action (lambda (node engine)
		(let ((from (markup-option node :from))
		      (to (markup-option node :to))
		      (body (markup-body node)))
		  (display ,(string-append " { big " lout-name
					   " from { "))
		  (output from engine)
		  (display " } to { ")
		  (output to engine)
		  (display " } { ")
		  (output body engine)
		  (display " } } ")))))

(range-lout-markup-writer sum "sum")
(range-lout-markup-writer product "prod")

(markup-writer 'eq:script (lookup-engine-class 'lout)
   :action (lambda (node engine)
	     (let ((body (markup-body node))
		   (sup (markup-option node :sup))
		   (sub (markup-option node :sub)))
	       (display " { { ")
	       (output body engine)
	       (display " } ")
	       (if sup
		   (begin
		     (display (if sub " supp { " " sup { "))
		     (output sup engine)
		     (display " } ")))
	       (if sub
		   (begin
		     (display " on { ")
		     (output sub engine)
		     (display " } ")))
	       (display " } "))))


;;; arch-tag: 2a1410e5-977e-4600-b781-3d57f4409b35
