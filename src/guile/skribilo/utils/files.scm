;;; files.scm  --  File-related utilities.
;;;
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

(define-module (skribilo utils files)
  :export (file-prefix file-suffix file-size))

;;; Author:  Ludovic Court�s
;;;
;;; Commentary:
;;;
;;; This module defines filesystem-related utility functions.
;;;
;;; Code:

(define (file-size file)
  (let ((file-info (false-if-exception (stat file))))
    (if file-info
	(stat:size file-info)
	#f)))

(define (file-prefix fn)
  (if fn
      (let ((dot (string-rindex fn #\.)))
	(if dot (substring fn 0 dot) fn))
      "./SKRIBILO-OUTPUT"))

(define (file-suffix fn)
  (if fn
      (let ((dot (string-rindex fn #\.)))
	(if dot
	    (substring fn (+ dot 1) (string-length fn))
	    ""))
      #f))


;;; arch-tag: b63d2a9f-a254-4e2d-8d85-df773bbc4a9b

;;; files.scm ends here
