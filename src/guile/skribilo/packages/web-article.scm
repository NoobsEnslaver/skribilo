;*=====================================================================*/
;*    serrano/prgm/project/skribe/skr/web-article.skr                  */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sat Jan 10 09:09:43 2004                          */
;*    Last change :  Wed Mar 24 16:45:08 2004 (serrano)                */
;*    Copyright   :  2004 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    A Skribe style for producing web articles                        */
;*=====================================================================*/

(define-skribe-module (skribilo packages web-article))

;*---------------------------------------------------------------------*/
;*    &web-article-load-options ...                                    */
;*---------------------------------------------------------------------*/
(define &web-article-load-options (skribe-load-options))

;*---------------------------------------------------------------------*/
;*    web-article-body-width ...                                       */
;*---------------------------------------------------------------------*/
(define (web-article-body-width e)
   (let ((w (engine-custom e 'body-width)))
      (if (or (number? w) (string? w)) w 98.)))

;*---------------------------------------------------------------------*/
;*    html-document-title-web ...                                      */
;*---------------------------------------------------------------------*/
(define (html-document-title-web n e)
   (let* ((title (markup-body n))
	  (authors (markup-option n 'author))
	  (tbg (engine-custom e 'title-background))
	  (tfg (engine-custom e 'title-foreground))
	  (tfont (engine-custom e 'title-font)))
      (printf "<center><table cellspacing='0' cellpadding='0' width=\"~a\" class=\"skribetitle\"><tbody>\n<tr>"
	      (html-width (web-article-body-width e)))
      (if (string? tbg)
	  (printf "<td bgcolor=\"~a\">" tbg)
	  (display "<td>"))
      (if (string? tfg)
	  (printf "<font color=\"~a\">" tfg))
      (if title
	  (begin
	     (display "<center>")
	     (if (string? tfont)
		 (begin
		    (printf "<font ~a><b>" tfont)
		    (output title e)
		    (display "</b></font>"))
		 (begin
		    (printf "<h1>")
		    (output title e)
		    (display "</h1>")))
	     (display "</center>\n")))
      (if (not authors)
	  (display "\n")
	  (html-title-authors authors e))
      (if (string? tfg)
	  (display "</font>"))
      (display "</td></tr></tbody></table></center>\n")))

;*---------------------------------------------------------------------*/
;*    web-article-css-document-title ...                               */
;*---------------------------------------------------------------------*/
(define (web-article-css-document-title n e)
   (let* ((title (markup-body n))
	  (authors (markup-option n 'author))
	  (id (markup-ident n)))
      ;; the title
      (printf "<div id=\"~a\" class=\"document-title-title\">\n"
	      (string-canonicalize id))
      (output title e)
      (display "</div>\n")
      ;; the authors
      (printf "<div id=\"~a\" class=\"document-title-authors\">\n"
	      (string-canonicalize id))
      (for-each (lambda (a) (output a e))
		(cond
		   ((is-markup? authors 'author)
		    (list authors))
		   ((list? authors)
		    authors)
		   (else
		    '())))
      (display "</div>\n")))

;*---------------------------------------------------------------------*/
;*    web-article-css-author ...                                       */
;*---------------------------------------------------------------------*/
(define (web-article-css-author n e)
   (let ((name (markup-option n :name))
	 (title (markup-option n :title))
	 (affiliation (markup-option n :affiliation))
	 (email (markup-option n :email))
	 (url (markup-option n :url))
	 (address (markup-option n :address))
	 (phone (markup-option n :phone))
	 (nfn (engine-custom e 'author-font))
	 (align (markup-option n :align)))
      (when name
	 (printf "<span class=\"document-author-name\" id=\"~a\">"
		 (string-canonicalize (markup-ident n)))
	 (output name e)
	 (display "</span>\n"))
      (when title
	 (printf "<span class=\"document-author-title\" id=\"~a\">"
		 (string-canonicalize (markup-ident n)))
	 (output title e)
	 (display "</span>\n"))
      (when affiliation
	 (printf "<span class=\"document-author-affiliation\" id=\"~a\">"
		 (string-canonicalize (markup-ident n)))
	 (output affiliation e)
	 (display "</span>\n"))
      (when (pair? address)
	 (printf "<span class=\"document-author-address\" id=\"~a\">"
		 (string-canonicalize (markup-ident n)))
	 (for-each (lambda (a)
		      (output a e)
		      (newline))
		   address)
	 (display "</span>\n"))
      (when phone
	 (printf "<span class=\"document-author-phone\" id=\"~a\">"
		 (string-canonicalize (markup-ident n)))
	 (output phone e)
	 (display "</span>\n"))
      (when email
	 (printf "<span class=\"document-author-email\" id=\"~a\">"
		 (string-canonicalize (markup-ident n)))
	 (output email e)
	 (display "</span>\n"))
      (when url
	 (printf "<span class=\"document-author-url\" id=\"~a\">"
		 (string-canonicalize (markup-ident n)))
	 (output url e)
	 (display "</span>\n"))))

;*---------------------------------------------------------------------*/
;*    HTML settings                                                    */
;*---------------------------------------------------------------------*/
(define (web-article-modern-setup he)
   (let ((sec (markup-writer-get 'section he))
	 (ft (markup-writer-get '&html-footnotes he)))
      ;; &html-document-title
      (markup-writer '&html-document-title he
	 :action html-document-title-web)
      ;; section
      (markup-writer 'section he
	 :options 'all
	 :before "<br>"
	 :action (lambda (n e)
		    (let ((e1 (make-engine 'html-web :delegate e))
			  (bg (engine-custom he 'section-background)))
		       (markup-writer 'section e1
			  :options 'all
			  :action (lambda (n e2) (output n e sec)))
		       (skribe-eval
			(center (color :width (web-article-body-width e)
				   :margin 5 :bg bg n))
			e1))))
      ;; &html-footnotes
      (markup-writer '&html-footnotes he
	 :options 'all
	 :before "<br>"
	 :action (lambda (n e)
		    (let ((e1 (make-engine 'html-web :delegate e))
			  (bg (engine-custom he 'section-background))
			  (fg (engine-custom he 'subsection-title-foreground)))
		       (markup-writer '&html-footnotes e1
			  :options 'all
			  :action (lambda (n e2)
				     (invoke (writer-action ft) n e)))
		       (skribe-eval
			(center (color :width (web-article-body-width e)
				   :margin 5 :bg bg :fg fg n))
			e1))))))

;*---------------------------------------------------------------------*/
;*    web-article-css-setup ...                                        */
;*---------------------------------------------------------------------*/
(define (web-article-css-setup he)
   (let ((sec (markup-writer-get 'section he))
	 (ft (markup-writer-get '&html-footnotes he)))
      ;; &html-document-title
      (markup-writer '&html-document-title he
	 :before (lambda (n e)
		    (printf "<div id=\"~a\" class=\"document-title\">\n"
			    (string-canonicalize (markup-ident n))))
	 :action web-article-css-document-title
	 :after "</div>\n")
      ;; author
      (markup-writer 'author he
	 :options '(:name :title :affiliation :email :url :address :phone :photo :align)
	 :before (lambda (n e)
		    (printf "<span id=\"~a\" class=\"document-author\">\n"
			    (string-canonicalize (markup-ident n))))
	 :action web-article-css-author
	 :after "</span\n")
      ;; section
      (markup-writer 'section he
	 :options 'all
	 :before (lambda (n e)
		    (printf "<div class=\"section\" id=\"~a\">"
			    (string-canonicalize (markup-ident n))))
	 :action (lambda (n e) (output n e sec))
	 :after "</div>\n")
      ;; &html-footnotes
      (markup-writer '&html-footnotes he
	 :options 'all
	 :before (lambda (n e)
		    (printf "<div class=\"footnotes\" id=\"~a\">"
			    (string-canonicalize (markup-ident n))))
	 :action (lambda (n e)
		    (output n e ft))
	 :after "</div>\n")))

;*---------------------------------------------------------------------*/
;*    Setup ...                                                        */
;*---------------------------------------------------------------------*/
(let* ((opt &web-article-load-options)
       (p (memq :style opt))
       (css (memq :css opt))
       (he (find-engine 'html)))
   (cond
      ((and (pair? p) (pair? (cdr p)) (eq? (cadr p) 'css))
       (web-article-css-setup he))
      ((and (pair? css) (pair? (cdr css)) (string? (cadr css)))
       (engine-custom-set! he 'css (cadr css))
       (web-article-css-setup he))
      (else
       (web-article-modern-setup he))))
