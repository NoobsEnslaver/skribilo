;*=====================================================================*/
;*    serrano/prgm/project/skribe/skr/letter.skr                       */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Oct  3 12:22:13 2003                          */
;*    Last change :  Thu Sep 23 20:00:42 2004 (serrano)                */
;*    Copyright   :  2003-04 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    Skribe style for letters                                         */
;*=====================================================================*/

(define-skribe-module (skribilo packages letter))

;*---------------------------------------------------------------------*/
;*    document                                                         */
;*---------------------------------------------------------------------*/
(define %letter-document document)

(define-markup (document #!rest opt 
		  #!key (ident #f) (class "letter") 
		  where date author
		  &skribe-eval-location)
   (let* ((ubody (the-body opt))
	  (body (list (new markup
			 (markup '&letter-where)
			 (loc &skribe-eval-location)
			 (options `((:where ,where)
				    (:date ,date)
				    (:author ,author))))
		      ubody)))
      (apply %letter-document
	     :author #f :title #f 
	     (append (apply append 
			    (the-options opt :where :date :author :title))
		     body))))

;*---------------------------------------------------------------------*/
;*    LaTeX configuration                                              */
;*---------------------------------------------------------------------*/
(let ((le (find-engine 'latex)))
   (engine-custom-set! le 'documentclass "\\documentclass[12pt]{letter}\n")
   (engine-custom-set! le 'maketitle #f)
   ;; &letter-where
   (markup-writer '&letter-where le
      :before "\\begin{raggedright}\n"
      :action (lambda (n e)
		 (let* ((w (markup-option n :where))
			(d (markup-option n :date))
			(a (markup-option n :author))
			(hd (if (and w d)
				(list w ", " d)
				(or w d)))
			(ne (copy-engine 'author e)))
		    ;; author
		    (markup-writer 'author ne
		       :options '(:name :title :affiliation :email :url :address :phone :photo :align :header)
		       :action (lambda (n e)
				  (let ((name (markup-option n :name))
					(title (markup-option n :title))
					(affiliation (markup-option n :affiliation))
					(email (markup-option n :email))
					(url (markup-option n :url))
					(address (markup-option n :address))
					(phone (markup-option n :phone)))
				     (define (row n)
					(output n e)
					(when hd
					   (display "\\hfill ")
					   (output hd e)
					   (set! hd #f))
					(display "\\\\\n"))
				     ;; name
				     (if name (row name))
				     ;; title
				     (if title (row title))
				     ;; affiliation
				     (if affiliation (row affiliation))
				     ;; address
				     (if (pair? address)
					 (for-each row address))
				     ;; telephone
				     (if phone (row phone))
				     ;; email
				     (if email (row email))
				     ;; url
				     (if url (row url)))))
		    ;; emit the author
		    (if a 
			(output a ne)
			(output hd e))))
      :after "\\end{raggedright}\n\\vspace{1cm}\n\n"))
		 
;*---------------------------------------------------------------------*/
;*    HTML configuration                                               */
;*---------------------------------------------------------------------*/
(let ((he (find-engine 'html)))
   ;; &letter-where
   (markup-writer '&letter-where he
      :before "<table width=\"100%\">\n"
      :action (lambda (n e)
		 (let* ((w (markup-option n :where))
			(d (markup-option n :date))
			(a (markup-option n :author))
			(hd (if (and w d)
				(list w ", " d)
				(or w d)))
			(ne (copy-engine 'author e)))
		    ;; author
		    (markup-writer 'author ne
		       :options '(:name :title :affiliation :email :url :address :phone :photo :align :header)
		       :action (lambda (n e)
				  (let ((name (markup-option n :name))
					(title (markup-option n :title))
					(affiliation (markup-option n :affiliation))
					(email (markup-option n :email))
					(url (markup-option n :url))
					(address (markup-option n :address))
					(phone (markup-option n :phone)))
				     (define (row n)
					(display "<tr><td align='left'>")
					(output n e)
					(when hd
					   (display "</td><td align='right'>")
					   (output hd e)
					   (set! hd #f))
					(display "</td></tr>\n"))
				     ;; name
				     (if name (row name))
				     ;; title
				     (if title (row title))
				     ;; affiliation
				     (if affiliation (row affiliation))
				     ;; address
				     (if (pair? address)
					 (for-each row address))
				     ;; telephone
				     (if phone (row phone))
				     ;; email
				     (if email (row email))
				     ;; url
				     (if url (row url)))))
		    ;; emit the author
		    (if a 
			(output a ne)
			(output hd e))))
      :after "</table>\n<hr>\n\n"))
		 

