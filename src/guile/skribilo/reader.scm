;;; reader.scm  --  Skribilo's front-end (aka. reader) interface.
;;;
;;; Copyright 2005  Ludovic Court�s <ludovic.courtes@laas.fr>
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

(define-module (skribilo reader)
  :use-module (srfi srfi-9)  ;; records
  :use-module (srfi srfi-17) ;; generalized `set!'
  :export (%make-reader lookup-reader make-reader)
  :export-syntax (define-reader define-public-reader))

;;; Author:  Ludovic Court�s
;;;
;;; Commentary:
;;;
;;; This module contains Skribilo's front-end (aka. ``reader'') interface.
;;; Skribilo's default reader is `(skribilo reader skribe)' which provides a
;;; reader for the Skribe syntax.
;;;
;;; Code:

(define-record-type <reader>
  (%make-reader name version make)
  reader?
  (name      reader:name      reader:set-name!)    ;; a symbol
  (version   reader:version   reader:set-version!) ;; a string
  (make      reader:make      reader:set-make!))   ;; a one-argument proc
                                                   ;; that returns a reader
                                                   ;; proc

(define-public reader:name
  (getter-with-setter reader:name reader:set-name!))

(define-public reader:version
  (getter-with-setter reader:version reader:set-version!))

(define-public reader:make
  (getter-with-setter reader:make reader:set-make!))

(define-macro (define-reader name version make-proc)
  `(define reader-specification
     (%make-reader (quote ,name) ,version ,make-proc)))

(define-macro (define-public-reader name version make-proc)
  `(define-reader ,name ,version ,make-proc))



;;; The mechanism below is inspired by Guile-VM code written by K. Nishida.

(define (lookup-reader name)
  "Look for a reader named @var{name} (a symbol) in the @code{(skribilo
readers)} module hierarchy.  If no such reader was found, an error is
raised."
  (let ((m (resolve-module `(skribilo reader ,name))))
    (if (module-bound? m 'reader-specification)
	(module-ref m 'reader-specification)
	(error "no such reader" name))))

(define (make-reader name)
  "Look for reader @var{name} and instantiate it."
  (let* ((spec (lookup-reader name))
         (make (reader:make spec)))
    (make)))


;;; reader.scm ends here
