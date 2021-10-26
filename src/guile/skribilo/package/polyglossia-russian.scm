;;; -*- coding: utf-8 -*-
;;; Easy configuring `xelatex' for working with cyryllic text
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

(define-module (skribilo package polyglossia-russian)
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
\\usepackage{polyglossia}
\\usepackage{fontspec}\n")

  (opt-append 'predocument "
\\newfontfamily\\cyrillicfont[Script=Cyrillic]{Liberation Serif}
\\setmainfont{Liberation Serif}
\\setsansfont{Liberation Sans}
\\setmonofont{Liberation Mono}
\\setdefaultlanguage{russian}
\\setotherlanguages{english}\n")

  (engine-custom-set! le 'hyperref-usepackage "\\usepackage[unicode,setpagesize=false]{hyperref}\n"))
