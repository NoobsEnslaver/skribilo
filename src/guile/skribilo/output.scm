;;;;
;;;; output.stk	-- Skribe Output Stage
;;;;
;;;; Copyright � 2003-2004 Erick Gallesio - I3S-CNRS/ESSI <eg@unice.fr>
;;;;
;;;;
;;;; This program is free software; you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation; either version 2 of the License, or
;;;; (at your option) any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License
;;;; along with this program; if not, write to the Free Software
;;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
;;;; USA.
;;;;
;;;;           Author: Erick Gallesio [eg@essi.fr]
;;;;    Creation date: 13-Aug-2003 18:42 (eg)
;;;; Last file update:  5-Mar-2004 10:32 (eg)
;;;;

(define-module (skribilo output)
   :export (output))

(use-modules (skribilo debug)
	     (skribilo types)
;	     (skribilo engine)
	     (skribilo writer)
	     (oop goops))


(define-generic out)

(define (%out/writer n e w)
  (with-debug 5 'out/writer
      (debug-item "n=" n " " (if (markup? n) (markup-markup n) ""))
      (debug-item "e=" (engine-ident e))
      (debug-item "w=" (writer-ident w))

      (when (writer? w)
	(invoke (slot-ref w 'before) n e)
	(invoke (slot-ref w 'action) n e)
	(invoke (slot-ref w 'after)  n e))))



(define (output node e . writer)
  (with-debug 3 'output
    (debug-item "node=" node " " (if (markup? node) (markup-markup node) ""))
    (debug-item "writer=" writer)
    (if (null? writer)
	(out node e)
	(cond
	  ((is-a? (car writer) <writer>)
	   (%out/writer node e (car writer)))
	  ((not (car writer))
	   (skribe-error 'output
			 (format "Illegal ~A user writer" (engine-ident e))
			 (if (markup? node) (markup-markup node) node)))
	  (else
	   (skribe-error 'output "Illegal user writer" (car writer)))))))


;;;
;;; OUT implementations
;;;
(define-method (out node e)
  #f)


(define-method (out (node <pair>) e)
  (let Loop ((n* node))
    (cond
      ((pair? n*)
       (out (car n*) e)
       (loop (cdr n*)))
      ((not (null? n*))
       (skribe-error 'out "Illegal argument" n*)))))


(define-method (out (node <string>) e)
  (let ((f (slot-ref e 'filter)))
    (if (procedure? f)
	(display (f node))
	(display node))))


(define-method (out (node <number>) e)
  (out (number->string node) e))


(define-method (out (n <processor>) e)
  (let ((combinator (slot-ref n 'combinator))
	(engine     (slot-ref n 'engine))
	(body	    (slot-ref n 'body))
	(procedure  (slot-ref n 'procedure)))
    (let ((newe (processor-get-engine combinator engine e)))
      (out (procedure body newe) newe))))


(define-method (out (n <command>) e)
  (let* ((fmt  (slot-ref n 'fmt))
	 (body (slot-ref n 'body))
	 (lb   (length body))
	 (lf   (string-length fmt)))
    (define (loops i n)
      (if (= i lf)
	  (begin
	    (if (> n 0)
		(if (<= n lb)
		    (output (list-ref body (- n 1)) e)
		    (skribe-error '! "Too few arguments provided" n)))
	    lf)
	  (let ((c (string-ref fmt i)))
	    (cond
	      ((char=? c #\$)
	       (display "$")
	       (+ 1 i))
	      ((not (char-numeric? c))
	       (cond
		 ((= n 0)
		    i)
		 ((<= n lb)
		    (output (list-ref body (- n 1)) e)
		    i)
		 (else
		    (skribe-error '! "Too few arguments provided" n))))
	      (else
	       (loops (+ i 1)
		      (+ (- (char->integer c)
			    (char->integer #\0))
			 (* 10 n))))))))

    (let loop ((i 0))
      (cond
	((= i lf)
	 #f)
	((not (char=? (string-ref fmt i) #\$))
	 (display (string-ref fmt i))
	 (loop (+ i 1)))
	(else
	 (loop (loops (+ i 1) 0)))))))


(define-method (out (n <handle>) e)
  'unspecified)


(define-method (out (n <unresolved>) e)
  (skribe-error 'output "Orphan unresolved" n))


(define-method (out (node <markup>) e)
  (let ((w (lookup-markup-writer node e)))
    (if (writer? w)
	(%out/writer node e w)
	(output (slot-ref node 'body) e))))
