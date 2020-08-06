;;; location.scm -- Skribilo source location.
;;;
;;; Copyright 2005, 2007, 2009, 2010, 2012, 2013, 2015, 2020  Ludovic Courtès <ludo@gnu.org>
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

(define-module (skribilo location)
  #:use-module (oop goops)
  #:use-module ((skribilo utils syntax) :select (skribilo-module-syntax))
  #:export (<location> location? ast-location
	   location-file location-line location-column
           invocation-location
           source-properties->location
           location->string))

;;; Commentary:
;;;
;;; An abstract data type to keep track of source locations.
;;;
;;; Code:

(skribilo-module-syntax)


;;;
;;; Class definition.
;;;

(define-class <location> ()
  (file   :init-keyword :file   :getter location-file)
  (column :init-keyword :column :getter location-column)
  (line   :init-keyword :line   :getter location-line))

(define (location? obj)
  (is-a? obj <location>))

(define (ast-location obj)
  (let ((loc (slot-ref obj 'loc)))
    (if (location? loc)
	(let* ((fname (location-file loc))
	       (line  (location-line loc))
	       (pwd   (getcwd))
	       (len   (string-length pwd))
	       (lenf  (string-length fname))
	       (file  (if (and (string-prefix? pwd fname len)
			       (> lenf len))
			  (substring fname len (string-length fname))
			  fname)))
	  (format #f "~a, line ~a" file line))
	"no source location")))

(define-method (write (loc <location>) port)
  (format port "#<<location> ~a \"~a\":~a:~a>"
          (object-address loc)
          (location-file loc)
          (location-line loc)
          (location-column loc)))



;;;
;;; Getting an invocation's location.
;;;

(define (invocation-location . depth)
  ;; Return a location object denoting the place of invocation of this
  ;; function's caller.  Debugging must be enable for this to work, via
  ;; `(debug-enable 'debug)', otherwise `#f' is returned.

  (define %outer-depth 3) ;; update when moving `make-stack'!

  (let ((depth (+ %outer-depth
                  (if (null? depth) 0 (car depth))))
        (stack (make-stack #t)))
    (and stack
         (< depth (stack-length stack))
         (let* ((frame  (stack-ref stack depth))
                (source (frame-source frame))
                (props  (and=> source source-properties)))
           (and=> props source-properties->location)))))

(define (source-properties->location loc)
  "Return a location object based on the info in LOC, an alist as returned
by Guile's `source-properties', `frame-source', `current-source-location',
etc."
  (let ((file (assq-ref loc 'filename))
        (line (assq-ref loc 'line))
        (col  (assq-ref loc 'column)))
    (and file (make <location>
                :file file
                :line (and line (+ line 1))
                :column (and col (+ col 1))))))

(define (location->string loc)
  "Return a user-friendly representation of LOC."
  (if (location? loc)
      (format #f "~a:~a:~a:" (location-file loc) (location-line loc)
              (location-column loc))
      "<unknown-location>:"))

;;; location.scm ends here.
