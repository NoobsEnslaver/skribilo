;*=====================================================================*/
;*    serrano/prgm/project/skribe/skr/acmproc.skr                      */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sun Sep 28 14:40:38 2003                          */
;*    Last change :  Thu Jun  2 10:55:39 2005 (serrano)                */
;*    Copyright   :  2003-05 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    The Skribe style for ACMPROC articles.                           */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    LaTeX global customizations                                      */
;*---------------------------------------------------------------------*/
(let ((le (find-engine 'latex)))
   (engine-custom-set! le
		       'documentclass
		       "\\documentclass[letterpaper]{acmproc}")
   ;; &latex-author
   (markup-writer '&latex-author le
      :before (lambda (n e)
		 (let ((body (markup-body n)))
		    (printf "\\numberofauthors{~a}\n\\author{\n"
			    (if (pair? body) (length body) 1))))
      :action (lambda (n e)
		 (let ((body (markup-body n)))
		    (for-each (lambda (a)
				 (display "\\alignauthor\n")
				 (output a e))
			      (if (pair? body) body (list body)))))
      :after "}\n")
   ;; author
   (let ((old-author (markup-writer-get 'author le)))
      (markup-writer 'author le
         :options (writer-options old-author)		     
         :action (writer-action old-author)))
   ;; ACM category, terms, and keywords
   (markup-writer '&acm-category le
      :options '(:index :section :subsection)
      :before (lambda (n e)
		 (display "\\category{")
		 (display (markup-option n :index))
		 (display "}")
		 (display "{")
		 (display (markup-option n :section))
		 (display "}")
		 (display "{")
		 (display (markup-option n :subsection))
		 (display "}\n["))
      :after "]\n")
   (markup-writer '&acm-terms le
      :before "\\terms{"
      :after "}")
   (markup-writer '&acm-keywords le
      :before "\\keywords{"
      :after "}")
   (markup-writer '&acm-copyright le
      :action (lambda (n e)
		 (display "\\conferenceinfo{")
		 (output (markup-option n :conference) e)
		 (display ",} {")
		 (output (markup-option n :location) e)
		 (display "}\n")
		 (display "\\CopyrightYear{")
		 (output (markup-option n :year) e)
		 (display "}\n")
		 (display "\\crdata{")
		 (output (markup-option n :crdata) e)
		 (display "}\n"))))

;*---------------------------------------------------------------------*/
;*    HTML global customizations                                       */
;*---------------------------------------------------------------------*/
(let ((he (find-engine 'html)))
   (markup-writer '&html-acmproc-abstract he
      :action (lambda (n e)
		 (let* ((ebg (engine-custom e 'abstract-background))
			(bg (or (and (string? ebg) 
				     (> (string-length ebg) 0))
				ebg
				"#cccccc"))
			(exp (p (center (color :bg bg :width 90. 
					   (markup-body n))))))
		    (skribe-eval exp e))))
   ;; ACM category, terms, and keywords
   (markup-writer '&acm-category :action #f)
   (markup-writer '&acm-terms :action #f)
   (markup-writer '&acm-keywords :action #f)
   (markup-writer '&acm-copyright :action #f))
		 
;*---------------------------------------------------------------------*/
;*    abstract ...                                                     */
;*---------------------------------------------------------------------*/
(define-markup (abstract #!rest opt #!key (class "abstract") postscript)
   (if (engine-format? "latex")
       (section :number #f :title "ABSTRACT" (p (the-body opt)))
       (let ((a (new markup
		   (markup '&html-acmproc-abstract)
		   (body (the-body opt)))))
	  (list (if postscript
		    (section :number #f :toc #f :title "Postscript download"
		       postscript))
		(section :number #f :toc #f :class class :title "Abstract" a)
		(section :number #f :toc #f :title "Table of contents"
		   (toc :subsection #t))))))

;*---------------------------------------------------------------------*/
;*    acm-category ...                                                 */
;*---------------------------------------------------------------------*/
(define-markup (acm-category #!rest opt #!key index section subsection)
   (new markup
      (markup '&acm-category)
      (options (the-options opt))
      (body (the-body opt))))

;*---------------------------------------------------------------------*/
;*    acm-terms ...                                                    */
;*---------------------------------------------------------------------*/
(define-markup (acm-terms #!rest opt)
   (new markup
      (markup '&acm-terms)
      (options (the-options opt))
      (body (the-body opt))))

;*---------------------------------------------------------------------*/
;*    acm-keywords ...                                                 */
;*---------------------------------------------------------------------*/
(define-markup (acm-keywords #!rest opt)
   (new markup
      (markup '&acm-keywords)
      (options (the-options opt))
      (body (the-body opt))))

;*---------------------------------------------------------------------*/
;*    acm-copyright ...                                                */
;*---------------------------------------------------------------------*/
(define-markup (acm-copyright #!rest opt #!key conference location year crdata)
   (let* ((le (find-engine 'latex))
	  (cop (format "\\conferenceinfo{~a,} {~a}
\\CopyrightYear{~a}
\\crdata{~a}\n" conference location year crdata))
	  (old (engine-custom le 'predocument)))
      (if (string? old)
	  (engine-custom-set! le 'predocument (string-append cop old))
	  (engine-custom-set! le 'predocument cop))))
   
;*---------------------------------------------------------------------*/
;*    references ...                                                   */
;*---------------------------------------------------------------------*/
(define (references)
   (list "\n\n"
	 (if (engine-format? "latex")
	     (font :size -1 (flush :side 'left (the-bibliography)))
	     (section :title "References"
                      (font :size -1 (the-bibliography))))))