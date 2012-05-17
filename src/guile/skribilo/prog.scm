;;; prog.scm  --  All the stuff for the prog markup
;;; -*- coding: iso-8859-1 -*-
;;;
;;; Copyright 2006, 2007, 2009  Ludovic Court�s  <ludo@gnu.org>
;;; Copyright 2003  Erick Gallesio - I3S-CNRS/ESSI <eg@essi.fr>
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

(define-module (skribilo prog)
  :use-module (ice-9 regex)
  :use-module (srfi srfi-1)
  :use-module (srfi srfi-11)

  :use-module (skribilo lib)  ;; `new'
  :use-module (skribilo ast)
  :use-module (skribilo utils syntax)

  :export (make-prog-body resolve-line))

(skribilo-module-syntax)


;;;
;;; Bigloo compatibility.
;;;

(define pregexp-match 	string-match)
(define pregexp-replace (lambda (rx str what)
			  (regexp-substitute/global #f rx str
						    'pre what 'post)))
(define pregexp-quote   regexp-quote)


(define node-body-set! markup-body-set!)

;;;
;;; FIXME: Tout le module peut se factoriser
;;;        d�finir en bigloo  node-body-set


;*---------------------------------------------------------------------*/
;*    resolve-line ...                                                 */
;*---------------------------------------------------------------------*/
(define (resolve-line doc id)
  (document-lookup-node doc id))

;*---------------------------------------------------------------------*/
;*    extract-string-mark ...                                          */
;*---------------------------------------------------------------------*/
(define (extract-string-mark line regexp)
  (let ((match (pregexp-match regexp line)))
    (if match
        (values (match:substring match 1)
                (pregexp-replace regexp line ""))
        (values #f line))))

;*---------------------------------------------------------------------*/
;*    extract-mark ...                                                 */
;*    -------------------------------------------------------------    */
;*    Extract the prog mark from a line.                               */
;*---------------------------------------------------------------------*/
(define (extract-mark line regexp)
   (cond
      ((not regexp)
       (values #f line))
      ((string? line)
       (extract-string-mark line regexp))
      ((list? line)
       (let loop ((ls line)
		  (res '()))
	  (if (null? ls)
	      (values #f line)
	      (let-values (((m l)
                            (extract-mark (car ls) regexp)))
		 (if (not m)
		     (loop (cdr ls) (cons l res))
		     (values m (append (reverse! res) (cons l (cdr ls)))))))))
      ((node? line)
       (let-values (((m l)
                     (extract-mark (node-body line) regexp)))
	  (if (not m)
	      (values #f line)
	      (begin
		 (node-body-set! line l)
		 (values m line)))))
      (else
       (values #f line))))

;*---------------------------------------------------------------------*/
;*    split-line ...                                                   */
;*---------------------------------------------------------------------*/
(define (split-line line)
   (cond
      ((string? line)
       (let ((l (string-length line)))
	  (let loop ((r1 0)
		     (r2 0)
		     (res '()))
	     (cond
		((= r2 l)
		 (if (= r1 r2)
		     (reverse! res)
		     (reverse! (cons (substring line r1 r2) res))))
		((char=? (string-ref line r2) #\Newline)
		 (loop (+ r2 1)
		       (+ r2 1)
		       (if (= r1 r2)
			   (cons 'eol res)
			   (cons* 'eol (substring line r1 r2) res))))
		(else
		 (loop r1
		       (+ r2 1)
		       res))))))
      ((list? line)
       (let loop ((ls line)
		  (res '()))
	  (if (null? ls)
	      res
	      (loop (cdr ls) (append res (split-line (car ls)))))))
      (else
       (list line))))

;*---------------------------------------------------------------------*/
;*    flat-lines ...                                                   */
;*---------------------------------------------------------------------*/
(define (flat-lines lines)
   (concatenate (map split-line lines)))

;*---------------------------------------------------------------------*/
;*    collect-lines ...                                                */
;*---------------------------------------------------------------------*/
(define (collect-lines lines)
   (let loop ((lines (flat-lines lines))
	      (res '())
	      (tmp '()))
      (cond
	 ((null? lines)
	  (reverse! (cons (reverse! tmp) res)))
	 ((eq? (car lines) 'eol)
	  (cond
	     ((null? (cdr lines))
	      (reverse! (cons (reverse! tmp) res)))
	     ((and (null? res) (null? tmp))
	      (loop (cdr lines)
		    res
		    '()))
	     (else
	      (loop (cdr lines)
		    (cons (reverse! tmp) res)
		    '()))))
	 (else
	  (loop (cdr lines)
		res
		(cons (car lines) tmp))))))

;*---------------------------------------------------------------------*/
;*    make-prog-body ...                                               */
;*---------------------------------------------------------------------*/
(define (make-prog-body src lnum-init ldigit mark)
   (let* ((regexp (and mark
		       (format #f "~a([-a-zA-Z_][-0-9a-zA-Z_]+)"
			       (pregexp-quote mark))))
	  (src (cond
		  ((not (pair? src)) (list src))
		  ((and (pair? (car src)) (null? (cdr src))) (car src))
		  (else src)))
	  (lines (collect-lines src))
	  (lnum (if (integer? lnum-init) lnum-init 1))
	  (s (number->string (+ (if (integer? ldigit)
				    (max lnum (expt 10 (- ldigit 1)))
				    lnum)
				(length lines)))))
     (let loop ((lines lines)
                (lnum lnum)
                (res '()))
	 (if (null? lines)
	     (reverse! res)
             (let-values (((m l)
                           (extract-mark (car lines) regexp)))
		(let* ((line-ident (symbol->string (gensym "&prog-line")))
		       (n (new markup
			     (markup  '&prog-line)
			     (ident   (or m line-ident))
                             (options `((:number ,(and lnum-init lnum))))
			     (body    l))))
 		   (loop (cdr lines)
 			 (+ lnum 1)
 			 (cons n res))))))))

