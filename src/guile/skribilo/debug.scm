;;; debug.scm  --  Debugging facilities.  -*- coding: iso-8859-1 -*-
;;;
;;; Copyright 2005, 2006, 2009, 2012, 2020  Ludovic Court�s <ludo@gnu.org>
;;; Copyright 2003, 2004  Erick Gallesio - I3S-CNRS/ESSI <eg@unice.fr>
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


(define-module (skribilo debug)
  #:use-module (skribilo utils syntax)
  #:use-module (srfi srfi-39)
  #:export (debug-item debug-bold with-debug))

(skribilo-module-syntax)


;;;
;;; Parameters.
;;;

;; Current debugging level.
(define-public *debug*
  (make-parameter 0 (lambda (val)
		      (cond ((number? val) val)
			    ((string? val)
			     (string->number val))
			    (else
			     (error "*debug*: wrong argument type"
				    val))))))

;; Whether to use colors.
(define-public *debug-use-colors?* (make-parameter #t))

;; Where to spit debugging output.
(define-public *debug-port* (make-parameter (current-output-port)))

;; Whether to debug individual items.
(define-public *debug-item?* (make-parameter #f))

;; Watched (debugged) symbols (procedure names).
(define-public *watched-symbols* (make-parameter '()))



;;;
;;; Implementation.
;;;

(define *debug-depth*   (make-parameter 0))
(define *debug-margin*	(make-parameter ""))
(define *margin-level*  (make-parameter 0))



;;
;;   debug-port
;;
; (define (debug-port . o)
;    (cond
;       ((null? o)
;        *debug-port*)
;       ((output-port? (car o))
;        (set! *debug-port* o)
;        o)
;       (else
;        (error 'debug-port "Invalid debug port" (car o)))))
;

;;;
;;; debug-color
;;;
(define (debug-color col . o)
  (with-output-to-string
    (if (and (*debug-use-colors?*)
	     (equal? (getenv "TERM") "xterm"))
	(lambda ()
	  (format #t "[0m[1;~Am" (+ 31 col))
	  (for-each display o)
	  (display "[0m"))
	(lambda ()
	  (for-each display o)))))

;;;
;;; debug-bold
;;;
(define (debug-bold . o)
   (apply debug-color -30 o))

;;;
;;; debug-item
;;;

(define (%do-debug-item . args)
  (begin
    (display (*debug-margin*) (*debug-port*))
    (display (debug-color (- (*debug-depth*) 1) "- ") (*debug-port*))
    (for-each (lambda (a) (display a (*debug-port*))) args)
    (newline (*debug-port*))))

(define-syntax-rule (debug-item args ...)
  (if (*debug-item?*)
      (%do-debug-item args ...)))


;;;
;;; %with-debug-margin
;;;
(define (%with-debug-margin margin thunk)
  (parameterize ((*debug-depth*   (+ (*debug-depth*) 1))
		 (*debug-margin*  (string-append (*debug-margin*) margin)))
    (thunk)))

;;;
;;; %with-debug
;;;
(define (%do-with-debug lvl lbl thunk)
  (parameterize ((*margin-level* lvl)
                 (*debug-item?* #t))
    (display (*debug-margin*) (*debug-port*))
    (display (if (= (*debug-depth*) 0)
                 (debug-color (*debug-depth*) "+ " lbl)
                 (debug-color (*debug-depth*) "--+ " lbl))
             (*debug-port*))
    (newline (*debug-port*))
    (%with-debug-margin (debug-color (*debug-depth*) "  |")
                        thunk)))

;; We have this as a macro in order to avoid procedure calls in the
;; non-debugging case.  Unfortunately, the macro below duplicates BODY,
;; which has a negative impact on memory usage and startup time (XXX).
(cond-expand
 (guile-2
  (define-syntax with-debug
    (lambda (s)
      (syntax-case s ()
        ((_ level label body ...)
         (integer? (syntax->datum #'level))
         #'(if (or (>= (*debug*) level)
                   (memq label (*watched-symbols*)))
               (%do-with-debug level label (lambda () body ...))
               (begin body ...)))))))
 (else
  (begin
    (export %do-with-debug)
    (define-macro (with-debug level label . body)
      (if (number? level)
          `(if (or (>= (*debug*) ,level)
                   (memq ,label (*watched-symbols*)))
               (%do-with-debug ,level ,label (lambda () ,@body))
               (begin ,@body))
          (error "with-debug: syntax error"))))))


; Example:

; (with-debug 0 'foo1.1
;   (debug-item 'foo2.1)
;   (debug-item 'foo2.2)
;   (with-debug 0 'foo2.3
;      (debug-item 'foo3.1)
;      (with-debug 0 'foo3.2
;	(debug-item 'foo4.1)
;	(debug-item 'foo4.2))
;      (debug-item 'foo3.3))
;   (debug-item 'foo2.4))

;;; debug.scm ends here
