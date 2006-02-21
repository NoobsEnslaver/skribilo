;;; lout.scm  --  Lout implementation of the `slide' package.
;;;
;;; Copyright 2005, 2006  Ludovic Court�s <ludovic.courtes@laas.fr>
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

(define-skribe-module (skribilo package slide lout)
  :use-module (skribilo utils syntax)

  ;; FIXME: For some reason, changing the following `autoload' in
  ;; `use-modules' doesn't work.

  :autoload (skribilo engine lout) (lout-tagify lout-output-pdf-meta-info)
  )


(fluid-set! current-reader %skribilo-module-reader)

;;; TODO:
;;;
;;; Make some more PS/PDF trickery.

(format (current-error-port) "slide/lout.scm~%")

(define-public (%slide-lout-initialize!)
  (format (current-error-port) "Lout slides initializing...~%")

  (let ((le (find-engine 'lout)))

    ;; Automatically switch to the `slides' document type.
    (engine-custom-set! le 'document-type 'slides)

    (markup-writer 'slide le
       :options '(:title :number :toc :ident) ;; '(:bg :vspace :image)

       :validate (lambda (n e)
		    (eq? (engine-custom e 'document-type) 'slides))

       :before (lambda (n e)
		  (display "\n@Overhead\n")
		  (display "  @Title { ")
		  (output (markup-option n :title) e)
		  (display " }\n")
		  (if (markup-ident n)
		      (begin
			 (display "  @Tag { ")
			 (display (lout-tagify (markup-ident n)))
			 (display " }\n")))
		  (if (markup-option n :number)
		      (begin
			 (display "  @BypassNumber { ")
			 (output (markup-option n :number) e)
			 (display " }\n")))
		  (display "@Begin\n")

		  ;; `doc' documents produce their PDF outline right after
		  ;; `@Text @Begin'; other types of documents must produce it
		  ;; as part of their first chapter.
		  (lout-output-pdf-meta-info (ast-document n) e))

       :after "@End @Overhead\n")

    (markup-writer 'slide-vspace le
       :options '(:unit)
       :validate (lambda (n e)
		    (and (pair? (markup-body n))
			 (number? (car (markup-body n)))))
       :action (lambda (n e)
		  (printf "\n//~a~a # slide-vspace\n"
			  (car (markup-body n))
			  (case (markup-option n :unit)
			     ((cm)              "c")
			     ((point points pt) "p")
			     ((inch inches)     "i")
			     (else
			      (skribe-error 'lout
					    "Unknown vspace unit"
					    (markup-option n :unit)))))))

    (markup-writer 'slide-pause le
       ;; FIXME:  Use a `pdfmark' custom action and a PDF transition action.
       ;; << /Type /Action
       ;; << /S /Trans
       ;; entry in the trans dict
       ;; << /Type /Trans  /S /Dissolve >>
       :action (lambda (n e)
		 (let ((filter (make-string-replace lout-verbatim-encoding))
		       (pdfmark "
[ {ThisPage} << /Trans << /S /Wipe /Dm /V /D 3 /M /O >> >> /PUT pdfmark"))
		   (display (lout-embedded-postscript-code
			     (filter pdfmark))))))

    ;; For movies, see
    ;; http://www.tug.org/tex-archive/macros/latex/contrib/movie15/movie15.sty .
    (markup-writer 'slide-embed le
       :options '(:alt :geometry :rgeometry :geometry-opt :command)
       ;; FIXME:  `pdfmark'.
       ;; << /Type /Action   /S /Launch
       :action (lambda (n e)
		 (let ((command (markup-option n :command))
		       (filter (make-string-replace lout-verbatim-encoding))
		       (pdfmark "[ /Rect [ 0 ysize xsize 0 ]
  /Name /Comment
  /Contents (This is an embedded application)
  /ANN pdfmark

[ /Type /Action
  /S    /Launch
  /F    (~a)
  /OBJ pdfmark"))
		 (display (string-append
			   "4c @Wide 3c @High "
			   (lout-embedded-postscript-code
			    (filter (format #f pdfmark command))))))))))


;;; arch-tag: 0c717553-5cbb-46ed-937a-f844b6aeb145
