;;; -*- coding: utf-8; tab-width: 4; c-basic-offset: 2; indent-tabs-mode: nil; -*-
;;; Easy configuring `pdflatex' for working with cyryllic text
;;:
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

(define-module (skribilo package babel-russian)
  #:use-module (skribilo engine))

;*---------------------------------------------------------------------*/
;*    LaTeX configuration                                              */
;*---------------------------------------------------------------------*/
(let ((le (find-engine 'latex)))
  (define (opt-append key val)
    (if (string? (engine-custom le key))
        (engine-custom-set! le key (string-append (engine-custom le key) val))
        (engine-custom-set! le key val)))

  (opt-append 'usepackage "
\\usepackage[T1, T2A]{fontenc}
\\usepackage[english, russian]{babel}\n")

  (opt-append 'predocument "\\DeclareUnicodeCharacter{00A0}{~}\n")

  (engine-custom-set! le 'hyperref-usepackage "\\usepackage[unicode,setpagesize=false]{hyperref}\n"))
