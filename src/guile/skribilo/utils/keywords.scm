;;; keywords.scm  --  Convenience procedures for keyword-argument handling.
;;;
;;; Copyright 2003, 2004  Manuel Serrano
;;; Copyright 2006  Ludovic Court�s <ludovic.courtes@laas.fr>
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

(define-module (skribilo utils keywords)
  :export (the-body the-options list-split))

;;; Author: Manuel Serrano, Ludovic Court�s
;;;
;;; Commentary:
;;;
;;; This module provides convenience functions to handle keyword arguments.
;;; These are typically used by markup functions.
;;;
;;; Code:

(define (the-body opt+)
  ;; Filter out the keyword arguments from OPT+.
  (let loop ((opt* opt+)
             (res '()))
    (cond
     ((null? opt*)
      (reverse! res))
     ((not (pair? opt*))
      (skribe-error 'the-body "Illegal body" opt*))
     ((keyword? (car opt*))
      (if (null? (cdr opt*))
          (skribe-error 'the-body "Illegal option" (car opt*))
          (loop (cddr opt*) res)))
     (else
      (loop (cdr opt*) (cons (car opt*) res))))))

(define (the-options opt+ . out)
  ;; Return a list made of keyword arguments (i.e., each time, a keyword
  ;; followed by its associated value).  The OUT argument should be a list
  ;; containing keyword argument names to be filtered out (e.g.,
  ;; `(#:ident)').
  (let loop ((opt* opt+)
             (res '()))
    (cond
     ((null? opt*)
      (reverse! res))
     ((not (pair? opt*))
      (skribe-error 'the-options "Illegal options" opt*))
     ((keyword? (car opt*))
      (cond
       ((null? (cdr opt*))
        (skribe-error 'the-options "Illegal option" (car opt*)))
       ((memq (car opt*) out)
        (loop (cdr opt*) res))
       (else
        (loop (cdr opt*)
              (cons (list (car opt*) (cadr opt*)) res)))))
     (else
      (loop (cdr opt*) res)))))

(define (list-split l num . fill)
   (let loop ((l l)
	      (i 0)
	      (acc '())
	      (res '()))
      (cond
	 ((null? l)
	  (reverse! (cons (if (or (null? fill) (= i num))
			      (reverse! acc)
			      (append! (reverse! acc)
				       (make-list (- num i) (car fill))))
			  res)))
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

;;; arch-tag: 3e9066d5-6d7d-4da5-922b-cc3d4ba8476e

;;; keywords.scm ends here
