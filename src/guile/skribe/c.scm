;;;;
;;;; c.stk	-- C fontifier for Skribe
;;;; 
;;;; Copyright � 2004 Erick Gallesio - I3S-CNRS/ESSI <eg@essi.fr>
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
;;;;    Creation date:  6-Mar-2004 15:35 (eg)
;;;; Last file update:  7-Mar-2004 00:12 (eg)
;;;;

(require "lex-rt")		;; to avoid module problems

(define-module (skribe c)
   :export (c java)
   :import (skribe runtime))

(include "c-lex.stk")		;; SILex generated


(define *the-keys*	    #f)

(define *c-keys*	    #f)
(define *java-keys*	    #f)


(define (fontifier s)
  (let ((lex (c-lex (open-input-string s))))
    (let Loop ((token (lexer-next-token lex))
	       (res   '()))
      (if (eq? token 'eof)
	  (reverse! res)
	  (Loop (lexer-next-token lex)
		(cons token res))))))
  
;;;; ======================================================================
;;;;
;;;; 				C
;;;;
;;;; ======================================================================
(define (init-c-keys)
  (unless *c-keys*
    (set! *c-keys* '(for while return break continue void
		     do if else typedef struct union goto switch case
		     static extern default)))
  *c-keys*)

(define (c-fontifier s)
  (fluid-let ((*the-keys* (init-c-keys)))
    (fontifier s)))

(define c
  (new language
       (name "C")
       (fontifier c-fontifier)
       (extractor #f)))

;;;; ======================================================================
;;;;
;;;; 				JAVA
;;;;
;;;; ======================================================================
(define (init-java-keys)
  (unless *java-keys*
    (set! *java-keys* (append (init-c-keys)
			      '(public final class throw catch))))
  *java-keys*)

(define (java-fontifier s)
  (fluid-let ((*the-keys* (init-java-keys)))
    (fontifier s)))

(define java
  (new language
       (name "java")
       (fontifier java-fontifier)
       (extractor #f)))

