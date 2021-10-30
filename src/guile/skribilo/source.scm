;;; -*- coding: utf-8; tab-width: 4; c-basic-offset: 2; indent-tabs-mode: t; -*-
;;; source.scm  -- Highlighting source files.
;;;
;;; Copyright 2005, 2008, 2009, 2010, 2018  Ludovic Courtès <ludo@gnu.org>
;;; Copyright 2003, 2004  Erick Gallesio - I3S-CNRS/ESSI <eg@essi.fr>
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

(define-module (skribilo source)
  #:export (<language> language? language-extractor language-fontifier
           language-name
           source-read-lines source-read-definition source-fontify

           &source-error source-error?
           &no-extractor-error no-extractor-error?
           no-extractor-error:language
           &definition-not-found-error definition-not-found-error?
           definition-not-found-error:definition
           definition-not-found-error:language)

  #:use-module (srfi srfi-35)
  #:autoload   (srfi srfi-34) (raise)
  #:autoload   (srfi srfi-13) (string-prefix-length string-concatenate)
  #:use-module (skribilo condition)

  #:use-module (skribilo utils syntax)
  #:use-module (skribilo parameters)
  #:use-module (oop goops)
  #:use-module (ice-9 rdelim))


(skribilo-module-syntax)


;;;
;;; Error conditions.
;;;

(define-condition-type &source-error &skribilo-error
  source-error?)

(define-condition-type &no-extractor-error &source-error
  no-extractor-error?
  (language    no-extractor-error:language))

(define-condition-type &definition-not-found-error &source-error
  definition-not-found-error?
  (definition  definition-not-found-error:definition)
  (language    definition-not-found-error:language))


(define (handle-source-error c)
  ;; Issue a user-friendly error message for error condition C.
  (cond ((no-extractor-error? c)
         (format (current-error-port)
                 (G_ "source language '~a' does not have an extractor~%")
                 (language-name (no-extractor-error:language c))))

        ((definition-not-found-error? c)
         (format (current-error-port)
                 (G_ "source definition of '~a' in language '~a' not found~%")
                 (definition-not-found-error:definition c)
                 (language-name (definition-not-found-error:language c))))

        (else
         (format (current-error-port)
                 (G_ "undefined source error: ~A~%")
                 c))))

(register-error-condition-handler! source-error? handle-source-error)


;;;
;;; Class definition.
;;;

(define-class <language> ()
  (name :init-keyword :name      :init-value #f :getter language-name)
  (fontifier    :init-keyword :fontifier :init-value #f
                :getter language-fontifier)
  (extractor    :init-keyword :extractor :init-value #f
                :getter language-extractor))

(define (language? obj)
  (is-a? obj <language>))



;*---------------------------------------------------------------------*/
;*    source-read-lines ...                                            */
;*---------------------------------------------------------------------*/
(define (source-read-lines file start stop tab)
  (with-file-input file
     (lambda (ip)
       (let ((startl (if (string? start) (string-length start) -1))
             (stopl  (if (string? stop)  (string-length stop)  -1)))
         (let loop ((l      0) ;; In Guile, line nums are 0-origined.
                    (armedp (not (or (integer? start) (string? start))))
                    (s      (read-line))
                    (r      '()))
           (cond
            ((or (eof-object? s)
                 (and (integer? stop) (> l stop))
                 (and (string? stop)
                      (= (string-prefix-length stop s) stopl)))
             (string-concatenate (reverse! r)))
            (armedp
             (loop (+ l 1)
                   #t
                   (read-line)
                   (cons* "\n" (untabify s tab) r)))
            ((and (integer? start) (>= l start))
             (loop (+ l 1)
                   #t
                   (read-line)
                   (cons* "\n" (untabify s tab) r)))
            ((and (string? start)
                  (= (string-prefix-length start s) startl))
             (loop (+ l 1) #t (read-line) r))
            (else
             (loop (+ l 1) #f (read-line) r))))))))

;*---------------------------------------------------------------------*/
;*    untabify ...                                                     */
;*---------------------------------------------------------------------*/
(define (untabify obj tab)
   (if (not tab)
       obj
       (let ((len (string-length obj))
             (tabl tab))
          (let loop ((i 0)
                     (col 1))
             (cond
                ((= i len)
                 (let ((nlen (- col 1)))
                    (if (= len nlen)
                        obj
                        (let ((new (make-string col #\space)))
                           (let liip ((i 0)
                                      (j 0)
                                      (col 1))
                              (cond
                                 ((= i len)
                                  new)
                                 ((char=? (string-ref obj i) #\tab)
                                  (let ((next-tab (* (/ (+ col tabl)
                                                            tabl)
                                                       tabl)))
                                     (liip (+ i 1)
                                           next-tab
                                           next-tab)))
                                 (else
                                  (string-set! new j (string-ref obj i))
                                  (liip (+ i 1) (+ j 1) (+ col 1)))))))))
                ((char=? (string-ref obj i) #\tab)
                 (loop (+ i 1)
                       (* (/ (+ col tabl) tabl) tabl)))
                (else
                 (loop (+ i 1) (+ col 1))))))))

;*---------------------------------------------------------------------*/
;*    source-read-definition ...                                       */
;*---------------------------------------------------------------------*/

(define (source-read-definition file definition tab lang)
  (unless (language-extractor lang)
    (raise (condition (&no-extractor-error
                       (language lang)))))
  (with-file-input file
     (lambda (ip)
       (let ((s ((language-extractor lang) ip definition tab)))
         (if (not (string? s))
             (raise (condition (&definition-not-found-error
                                (definition definition)
                                (language   lang))))
             s)))))

;*---------------------------------------------------------------------*/
;*    source-fontify ...                                               */
;*---------------------------------------------------------------------*/
(define (source-fontify o language)
   (define (fontify f o)
      (cond
         ((string? o) (f o))
         ((pair? o) (map (lambda (s) (if (string? s) (f s) (fontify f s))) o))
         (else o)))
   (let ((f (language-fontifier language)))
      (if (procedure? f)
          (fontify f o)
          o)))

;; ------------------------- Internal ------------------------
(define (with-file-input file callback)
  (let ([p (search-path (*source-path*) file)])
    (when (or (not p) (not (file-exists? p)))
      (raise (condition (&file-search-error (file-name file)
                                            (path (*source-path*))))))
    (with-input-from-file p
      (lambda ()
        (set-correct-file-encoding!)
        (when (> (*verbose*) 0)
          (format (current-error-port) "  [source file: ~S]\n" p))
        (callback (current-input-port))))))
