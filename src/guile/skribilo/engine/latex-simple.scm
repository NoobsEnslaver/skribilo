(define-skribe-module (skribilo engine latex-simple))

;;;
;;; LES CUSTOMS SONT TROP SPECIFIQUES POUR LA DISTRIBS. NE DOIT PAS VIRER
;;; CE FICHIER (sion simplifie il ne rest plus grand chose)
;;;		Erick 27-10-04
;;;


;*=====================================================================*/
;*    scmws04/src/latex-style.skr                                      */
;*    -------------------------------------------------------------    */
;*    Author      :  Damien Ciabrini                                   */
;*    Creation    :  Tue Aug 24 19:17:04 2004                          */
;*    Last change :  Thu Oct 28 21:45:25 2004 (eg)                     */
;*    Copyright   :  2004 Damien Ciabrini, see LICENCE file            */
;*    -------------------------------------------------------------    */
;*    Custom style for Latex...                                        */
;*=====================================================================*/

(let* ((le (find-engine 'latex))
       (oa (markup-writer-get 'author le)))
   ; latex class & package for the workshop
   (engine-custom-set! le 'documentclass "\\documentclass[letterpaper]{sigplan-proc}")
   (engine-custom-set! le 'usepackage
   "\\usepackage{epsfig}
\\usepackage{workshop}
\\conferenceinfo{Fifth Workshop on Scheme and Functional Programming.}
	       {September 22, 2004, Snowbird, Utah, USA.}
\\CopyrightYear{2004}
\\CopyrightHolder{Damien Ciabrini}
\\renewcommand{\\ttdefault}{cmtt}
")
   (engine-custom-set! le 'image-format '("eps"))
   (engine-custom-set! le 'source-define-color "#000080")
   (engine-custom-set! le 'source-thread-color "#8080f0")
   (engine-custom-set! le 'source-string-color "#000000")

   ; hyperref options
   (engine-custom-set! le 'hyperref #t)
   (engine-custom-set! le 'hyperref-usepackage
   "\\usepackage[bookmarksopen=true, bookmarksopenlevel=2,bookmarksnumbered=true,colorlinks,linkcolor=blue,citecolor=blue,pdftitle={Debugging Scheme Fair Threads}, pdfsubject={debugging cooperative threads based on reactive programming}, pdfkeywords={debugger, functional, reactive programming, Scheme}, pdfauthor={Damien Ciabrini}]{hyperref}")
   ; nbsp with ~ char
   (set! latex-encoding (delete! (assoc #\~ latex-encoding) latex-encoding))

   ; let latex process citations
   (markup-writer 'bib-ref le
      :options '(:text :bib)
      :before "\\cite{"
      :action (lambda (n e) (display (markup-option n :bib)))
      :after "}")
   (markup-writer 'bib-ref+ le
      :options '(:text :bib)
      :before "\\cite{"
      :action (lambda (n e)
		 (let loop ((bibs (markup-option n :bib)))
		    (if (pair? bibs)
			(begin
			   (display (car bibs))
			   (if (pair? (cdr bibs)) (display ", "))
			   (loop (cdr bibs))))))
      :after "}")
   (markup-writer '&the-bibliography le
      :action (lambda (n e)
		 (print "\\bibliographystyle{abbrv}")
		 (display "\\bibliography{biblio}")))

   ; ACM-style for authors
   (markup-writer '&latex-author le
      :before (lambda (n e)
		 (let ((body (markup-body n)))
		    (if (pair? body)
			(print "\\numberofauthors{" (length body) "}"))
		    (print "\\author{")))
      :after "}\n")
   (markup-writer 'author le
      :options (writer-options oa)
      :before ""
      :action (lambda (n e)
		 (let ((name (markup-option n :name))
		       (affiliation (markup-option n :affiliation))
		       (address (markup-option n :address))
		       (email (markup-option n :email)))
		    (define (row pre n post)
		       (display pre)
		       (output n e)
		       (display post)
		       (display "\\\\\n"))
		    ;; name
		    (if name (row "\\alignauthor " name ""))
		    ;; affiliation
		    (if affiliation (row "\\affaddr{" affiliation "}"))
		    ;; address
		    (if (pair? address)
			(for-each (lambda (x)
				     (row "\\affaddr{" x "}")) address))
		    ;; email
		    (if email (row "\\email{" email "}"))))
      :after "")
)

(define (include-biblio)
   (the-bibliography))