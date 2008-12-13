;;; info.scm  --  GNU Info engine.
;;;
;;; Copyright 2008  Ludovic Courtès <ludo@gnu.org>
;;; Copyright 2001, 2002  Manuel Serrano
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
;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;;; USA.

(define-module (skribilo engine info)
  :use-module (skribilo lib)
  :use-module (skribilo ast)
  :use-module (skribilo engine)
  :use-module (skribilo writer)
  :use-module (skribilo utils syntax)
  :use-module (skribilo package base)
  :autoload   (skribilo parameters)    (*destination-file*)
  :autoload   (skribilo output)        (output)
  :autoload   (skribilo utils justify) (output-justified make-justifier
                                        with-justification)
  :autoload   (skribilo utils text-table) (table->ascii)
  :use-module (srfi srfi-8)
  :use-module (srfi srfi-13)

  :export (info-engine))

(fluid-set! current-reader %skribilo-module-reader)


(define info-engine
  (make-engine 'info
     :version 1.0
     :format "info"
     :delegate (find-engine 'base)
     :filter (lambda (str)
               ;; Justify all the strings that are to be output.
               (with-output-to-string
                 (lambda ()
                   (output-justified str))))
     :custom '()))

;*---------------------------------------------------------------------*/
;*    info-dest ...                                                    */
;*---------------------------------------------------------------------*/
(define (info-dest)
   (if (string? (*destination-file*))
       (*destination-file*)
       "anonymous.info"))

;;
;; Convenience functions.
;;

(define (print . args)
  (for-each display args)
  (newline))

(define (%block? obj)
  (and (markup? obj)
       (memq (markup-markup obj)
             '(chapter section subsection subsubsection))))

;*---------------------------------------------------------------------*/
;*    info-node ...                                                    */
;*---------------------------------------------------------------------*/
(define (info-node node next prev up)
   (print "\n")
   (print "File: " (info-dest)
	  ",  Node: " node
	  ",  Next: " next
	  ",  Prev: " prev
	  ",  Up: " up)
   (newline))

;*---------------------------------------------------------------------*/
;*    node-next+prev+top ...                                           */
;*---------------------------------------------------------------------*/
(define (node-next+prev+top section e)
  (if (document? section)
      (let loop ((c (markup-body section)))
        (cond
         ((null? c)
          (values "Top" "(dir)" "(dir)"))
         ((or (is-markup? (car c) 'chapter)
              (is-markup? (car c) 'section))
          (values (block-title (car c) e) "(dir)" "(dir)"))
         (else
          (loop (cdr c)))))
      (let ((parent (ast-parent section)))
        (let ((top (if (document? parent)
                       "Top"
                       (block-title parent e))))
          (let loop ((els  (filter %block? (markup-body parent)))
                     (prev #f))
	    (cond
             ((null? els)
              (values top top top))
             ((eq? (car els) section)
              (let ((p (if prev
                           (block-title prev e)
                           top))
                    (n (if (null? (cdr els))
                           top
                           (block-title (cadr els) e))))
                (values n p top)))
             (else
              (loop (cdr els) (car els)))))))))

;*---------------------------------------------------------------------*/
;*    node-menu ...                                                    */
;*---------------------------------------------------------------------*/
(define (node-menu container e)
  (let ((children (markup-body container)))
      (if (pair? (filter (lambda (x)
                           (and (markup? x)
                                (memq (markup-markup x)
                                      '(chapter section))))
			 children))
	  (begin
	     (newline)
	     (print "* Menu:")
	     (newline)
	     (for-each (lambda (c)
			  (if (%block? c)
			      (print "* " (block-title c e) "::")))
		       children)))
      (newline)))

;*---------------------------------------------------------------------*/
;*    block-title ::%chapter ...                                       */
;*---------------------------------------------------------------------*/
(define (block-title obj e)
  (let ((title    (markup-option obj :title))
        (subtitle (markup-option obj :subtitle)))
      (let ((title (if title title subtitle)))
	 (if (string? title)
	     title
             (ast->string title)))))

;*---------------------------------------------------------------------*/
;*    info ::%document ...                                             */
;*---------------------------------------------------------------------*/
(markup-writer 'document info-engine
  :options '(:title :author :ending)
  :action (lambda (doc e)
            (let ((title     (markup-option doc :title))
                  (authors   (markup-option doc :author))
                  (body      (markup-body doc))
                  (footnotes (reverse!
                              (container-env-get doc 'footnote-env))))
              (scribe-document->info doc (if title title "")
                                     (if (list? authors)
                                         authors
                                         (list authors))
                                     body e)
              (if (pair? footnotes)
                  (begin
                    (with-justification
                     (make-justifier *text-column-width* 'left)
                     (lambda ()
                       (newline)
                       (newline)
                       (print "-------------")
                       (for-each (lambda (fn)
                                   (let ((label (markup-option fn :label))
                                         (note  (markup-body fn))
                                         (id    (markup-ident fn)))
                                     (output (list "*" label ": ") e)
                                     (output note e)
                                     (output-newline)))
                                 footnotes)
                       ))))
              ;; FIXME: Handle `:ending'.
              )))

;*---------------------------------------------------------------------*/
;*     scribe-document->info ...                                       */
;*---------------------------------------------------------------------*/
(define (scribe-document->info obj title authors body e)
   (define (info-authors1 author)
      (output author e)
      (output-newline)
      (output-newline))
   (define (info-authorsN authors cols first)
      (define (make-row authors . opt)
	 (apply tr (map (lambda (v)
			   (apply td :align 'center :valign 'top v opt))
			authors)))
      (define (make-rows authors)
	 (let loop ((authors authors)
		    (rows '())
		    (row '())
		    (cnum 0))
	    (cond
	       ((null? authors)
		(reverse! (cons (make-row (reverse! row)) rows)))
	       ((= cnum cols)
		(loop authors
		      (cons (make-row (reverse! row)) rows)
		      '()
		      0))
	       (else
		(loop (cdr authors)
		      rows
		      (cons (car authors) row)
		      (+ cnum 1))))))
      (output (apply table
		    (if first
			(cons (make-row (list (car authors)) :colspan cols)
			      (make-rows (cdr authors)))
			(make-rows authors)))
              e))
   (define (info-authors authors)
      (if (pair? authors)
	  (begin
	     (output-newline)
	     (output-justified "--o-0-o--")
	     (output-newline)
	     (output-newline)
	     (let ((len (length authors)))
		(case len
		   ((1)
		    (info-authors1 (car authors)))
		   ((2 3)
		    (info-authorsN authors len #f))
		   ((4)
		    (info-authorsN authors 2 #f))
		   (else
		    (info-authorsN authors 3 #t)))))))
   ;; display the title and the authors
   (define (info-title title authors)
      (with-justification
       (make-justifier (justification-width) 'center)
       (lambda ()
	  (output-justified (make-string *text-column-width* #\=))
	  (output-newline)
	  (if (string? title)
	      (output-justified
                (list->string
		       (apply append
			      (map (lambda (c) (list c #\bs))
				   (string->list title)))))
	      (output title e))
	  (output-newline)
	  (info-authors authors)
	  (output-justified (make-string *text-column-width* #\=))
	  (output-newline)
	  (output-newline)
	  (output-flush *margin*))))

   ;; the main node
   (receive (next prev top)
      (node-next+prev+top obj e)
      (newline)
      (info-node "Top" next prev top))
   ;; the title
   (info-title title authors)
   (output-flush 0)
   ;; the main info menu
   (node-menu obj e)
   ;; the body
   (output body e)
   (output-flush 0)
   ;; the footer of the document
   ;(info-footer)
   (output-flush 0)
   ;; we are done
   (newline)
   (newline))

;*---------------------------------------------------------------------*/
;*    info ::%author ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer 'author info-engine
  :options '(:name :title :affiliation :email :url :address :phone
             :photo :align)  ;; XXX: These two aren't actually supported.

  :action (lambda (n e)
            (let ((name        (markup-option n :name))
                  (title       (markup-option n :title))
                  (affiliation (markup-option n :affiliation))
                  (email       (markup-option n :email))
                  (url         (markup-option n :url))
                  (address     (markup-option n :address))
                  (phone       (markup-option n :phone)))
              (if (or (pair? name) (string? name))
                  (output name e))
              (if title (begin (output-newline) (output title e)))
              (if affiliation (begin (output-newline) (output affiliation e)))
              (if (pair? address)
                  (for-each (lambda (x) (output-newline) (output x e)) address))
              (if email (begin (output-newline) (output email e)))
              (if url (begin (output-newline) (output url e)))
              (if phone (begin (output-newline) (output phone e)))
              (output-newline))))
   
;*---------------------------------------------------------------------*/
;*    scribe->html ::%toc ...                                          */
;*---------------------------------------------------------------------*/
(markup-writer 'toc info-engine
  :action (lambda (n e)
            (node-menu (ast-document n) e)))

;*---------------------------------------------------------------------*/
;*    info ::%linebreak ...                                            */
;*---------------------------------------------------------------------*/
(markup-writer 'linebreak info-engine
  :action (lambda (n e)
            (output-newline)))

;*---------------------------------------------------------------------*/
;*    info ::%center ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer 'center info-engine
  :action (lambda (n e)
            (with-justification (make-justifier (justification-width) 'center)
                                (lambda ()
                                  (output (markup-body n) e)))))

;*---------------------------------------------------------------------*/
;*    info ::%flush ...                                                */
;*---------------------------------------------------------------------*/
(markup-writer 'flush info-engine
  :options '(:side)
  :action (lambda (n e)
            (let ((side (markup-option n :side)))
              (with-justification (make-justifier (justification-width) side)
                                  (lambda ()
                                    (output (markup-body n) e))))))

;*---------------------------------------------------------------------*/
;*    ~ ...                                                           */
;*---------------------------------------------------------------------*/
(markup-writer '~
  ;; FIXME: This isn't actually breakable.
  :action (lambda (n e) (output-justified " ")))

;*---------------------------------------------------------------------*/
;*    breakable-space ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer 'breakable-space
  :action (lambda (n e) (output-justified " ")))

;*---------------------------------------------------------------------*/
;*    *ornaments* ...                                                  */
;*---------------------------------------------------------------------*/
(define %ornaments
   `((bold      "*" "*")
     (emph      "_" "_")
     (underline "*" "*")
     (it        "_" "_")
     (samp      "_" "_")
     (sc        "" "")
     (sup       "^" "")
     (sub       "_" "")
     (code      "`" "'")
     (tt        "`" "'")
     (samp      "`" "'")))

;*---------------------------------------------------------------------*/
;*    info ::%ornament ...                                             */
;*---------------------------------------------------------------------*/
(for-each (lambda (ornament)
            (let ((name   (car ornament))
                  (before (cadr ornament))
                  (after  (caddr ornament)))
              (markup-writer name info-engine
                             :before (lambda (n e)
                                       (output-justified before))
                             :after  (lambda (n e)
                                       (output-justified after)))))
          %ornaments)

;*---------------------------------------------------------------------*/
;*    info ::%pre ...                                                  */
;*---------------------------------------------------------------------*/
(markup-writer 'pre info-engine
  :action (lambda (n e)
            (with-justification (make-justifier *text-column-width* 'verbatim)
                                (lambda ()
                                  (output (markup-body n) e)
                                  (output-newline)))))

;*---------------------------------------------------------------------*/
;*    info ::%mark ...                                                 */
;*---------------------------------------------------------------------*/
(markup-writer 'mark info-engine
  :action #f)

;*---------------------------------------------------------------------*/
;*    info ::%reference ...                                            */
;*---------------------------------------------------------------------*/
(markup-writer 'ref info-engine
  :options '(:text :page text kind
             :chapter :section :subsection :subsubsection
             :figure :mark :handle :ident)

  :action (lambda (n e)
            (let ((target (handle-ast (markup-body n))))
              (case (markup-markup target)
                ((chapter)
                 (info-chapter-ref target e))
                ((section)
                 (info-section-ref target e))
                ((subsection)
                 (info-subsection-ref target e))
                ((subsubsection)
                 (info-subsubsection-ref target e))
                (else
                 (skribe-warning/ast 1 target
                                     "ref: don't know how to refer to target")
                 (output-justified "section:???"))))))

;*---------------------------------------------------------------------*/
;*    info ::%url-ref ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer 'url-ref info-engine
  :options '(:url :text)
  :action (lambda (n e)
            (let ((url  (markup-option n :url))
                  (text (markup-option n :text)))
              (and text
                   (begin
                     (output text e)
                     (output-justified " (")))
              (output-justified url)
              (and text (output-justified ")")))))

;*---------------------------------------------------------------------*/
;*    info-chapter-ref ...                                             */
;*---------------------------------------------------------------------*/
(define (info-chapter-ref obj e)
   (output-justified "*Note ")
   (output (block-title obj e) e)
   (output-justified ":: "))

;*---------------------------------------------------------------------*/
;*    info-section-ref ...                                             */
;*---------------------------------------------------------------------*/
(define (info-section-ref obj e)
   (let ((title (markup-option obj :title)))
      (output-justified "*Note ")
      (output title e)
      (output-justified ":: ")))

;*---------------------------------------------------------------------*/
;*    info-subsection-ref ...                                          */
;*---------------------------------------------------------------------*/
(define (info-subsection-ref obj e)
   (let ((title (markup-option obj :title)))
      (output-justified "*Note ")
      (output title e)
      (output-justified ":: ")))

;*---------------------------------------------------------------------*/
;*    info-subsubsection-ref ...                                       */
;*---------------------------------------------------------------------*/
(define (info-subsubsection-ref obj e)
   (let ((title (markup-option obj :title)))
      (output-justified "*Note ")
      (output title e)
      (output-justified ":: ")))

;*---------------------------------------------------------------------*/
;*    info ::%biblio-ref ...                                           */
;*---------------------------------------------------------------------*/
(markup-writer 'bib-ref info-engine
  :options '(:text :bib)
  :action (lambda (n e)
            ;; XXX: Produce hyperlink to `the-bibliography'?
            (let ((text (markup-option n :text))
                  (bib  (markup-option n :bib)))
              (if text (output text e))
              (output-justified " [")
              (output bib e)
              (output-justified "]"))))

;*---------------------------------------------------------------------*/
;*    mailto ...                                                       */
;*---------------------------------------------------------------------*/
(markup-writer 'mailto info-engine
  :options '(:text)
  :action (lambda (n e)
            (let ((email (markup-body n))
                  (text  (markup-option n :text)))
              (if text (output text e))
              (output email e))))

;*---------------------------------------------------------------------*/
;*    info ::%item ...                                                 */
;*---------------------------------------------------------------------*/
(markup-writer 'item info-engine
 :options '(:key)
 :action (lambda (n e)
           (let ((k (markup-option n :key)))
             (if k
                 (begin
                   (output k e)
                   (display ": ")))
             (output (markup-body n) e))))

;*---------------------------------------------------------------------*/
;*    info ::%list ...                                                 */
;*---------------------------------------------------------------------*/
(markup-writer 'itemize info-engine
  :options '(:symbol)
  :action (lambda (n e)
            (for-each (lambda (item)
                        (with-justification (make-justifier
                                             (- (justification-width) 3)
                                             'left)
                                            (lambda ()
					      (output-justified "- ")
					      (output item e))
                                            3))
                      (markup-body n))))

(markup-writer 'enumerate info-engine
  :options '(:symbol)
  :action (lambda (n e)
            (let loop ((num   1)
                       (items (markup-body n)))
              (if (pair? items)
                  (let ((item (car items)))
		    (with-justification (make-justifier
					 (- (justification-width) 3)
					 'left)
					(lambda ()
                                          (output-justified (number->string num))
                                          (output-justified " - ")
                                          (output item e))
					3)
		    (loop (+ num 1) (cdr items)))))))

(markup-writer 'description info-engine
  :options '(:symbol)
  :action (lambda (n e)
            (for-each (lambda (item)
                        (with-justification
                         (make-justifier
                          (- (justification-width) 3)
                          'left)
                         (lambda ()
                           (output item e))
                         3))
                      (markup-body n))))

;*---------------------------------------------------------------------*/
;*    info ::%section ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer 'section info-engine
  :options '(:title :html-title :number :toc :file :env)
  :action (lambda (n e)
            (let ((body  (markup-body n))
                  (title (markup-option n :title)))
              (output-newline)
              (output-flush *margin*)
              (let ((t (block-title n e)))
                (receive (next prev top)
                    (node-next+prev+top n e)
                  (info-node t next prev top)
                  (print t)
                  (print (make-string (string-length t) #\=))))
              (node-menu n e)
              (with-justification (make-justifier *text-column-width*
                                                  *text-justification*)
                                  (lambda () (output body e))))))

;*---------------------------------------------------------------------*/
;*    info ::%subsection ...                                           */
;*---------------------------------------------------------------------*/
(markup-writer 'subsection info-engine
  :options '(:title :html-title :number :toc :env :file)
  :action (lambda (n e)
            (let ((body  (markup-body n))
                  (title (markup-option n :title)))
              (output-flush *margin*)
              (let ((t (block-title n e)))
                (receive (next prev top)
                    (node-next+prev+top n e)
                  (info-node t next prev top)
                  (print t)
                  (print (make-string (string-length t) #\-))))
              (output body e))))

;*---------------------------------------------------------------------*/
;*    info ::%subsubsection ...                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'subsubsection info-engine
  :options '(:title :html-title :number :toc :env :file)
  :action (lambda (n e)
            (let ((body  (markup-body n))
                  (title (markup-option n :title)))
              (output-flush *margin*)
              (let ((t (block-title n e)))
                (receive (next prev top)
                    (node-next+prev+top n e)
                  (info-node t next prev top)
                  (print t)
                  (print (make-string (string-length t) #\~))))
              (output body e))))

;*---------------------------------------------------------------------*/
;*    info ::%paragraph ...                                            */
;*---------------------------------------------------------------------*/
(markup-writer 'paragraph info-engine
  :action (lambda (n e)
            (output-newline)
            (output-flush *margin*)
            (output (markup-body n) e)))

;*---------------------------------------------------------------------*/
;*    info ::%chapter ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer 'chapter info-engine
  :options '(:title :number :file :toc :html-title :env)
  :action (lambda (n e)
            (let ((body   (markup-body n))
                  (file   (markup-option n :file))
                  (title  (markup-option n :title)))
              (output-newline)
              (output-flush *margin*)
              (let ((t (block-title n e)))
                (receive (next prev top)
                    (node-next+prev+top n e)
                  (info-node t next prev top)
                  (print t)
                  (print (make-string (string-length t) #\*))))
              (node-menu n e)
              (output body e))))

;*---------------------------------------------------------------------*/
;*    info ::%hrule ...                                                */
;*---------------------------------------------------------------------*/
(markup-writer 'hrule info-engine
  :options '(:width)
  :action (lambda (n e)
            (let ((width  (markup-option n :width)))
              (let ((w (if (= width 100)
                           (justification-width)
                           (inexact->exact
                            (* (exact->inexact (justification-width))
                               (/ (exact->inexact width) 100.))))))
                (output-justified (make-string w #\-))))))

;*---------------------------------------------------------------------*/
;*    info ::%table ...                                                */
;*---------------------------------------------------------------------*/
(markup-writer 'table info-engine
  :options '(:border :width
             ;; FIXME: We don't actually support the following.
             :frame :rules :cellpadding :rulecolor)
  :action (lambda (n e)
            (let ((border (markup-option n :border)))
              (output-flush *margin*)
              (if border
                  (border-table->info n)
                  (table->ascii n (lambda (obj)
                                    (output obj e))))
              (output-flush *margin*))))

;*---------------------------------------------------------------------*/
;*    info ::&the-bibliography ...                                     */
;*---------------------------------------------------------------------*/
(markup-writer '&the-bibliography info-engine
  :action (lambda (n e)
            (output-justified "[FIXME: Bibliography not implemented yet.]")))

;*---------------------------------------------------------------------*/
;*    border-table->info ...                                           */
;*---------------------------------------------------------------------*/
(define (border-table->info table)
   (table->ascii table (lambda (obj)
                         (output obj info-engine))))

;*---------------------------------------------------------------------*/
;*    info ::%figure ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer 'figure info-engine
  :options '(:legend :number :multicolumns)
  :action (lambda (n e)
            (let ((body   (markup-body n))
                  (legend (markup-option n :legend))
                  (number (markup-option n :number)))
              (output-newline)
              (output body e)
              (output-newline)
              (output-newline)
              (output-justified "Fig. ")
              (and (number? number)
                   (output-justified (number->string number)))
              (output-justified ": ")
              (output legend e)
              (output-newline))))

;*---------------------------------------------------------------------*/
;*    info ::%footnote ...                                             */
;*---------------------------------------------------------------------*/
(markup-writer 'footnote info-engine
  :options '(:label)
  :action (lambda (n e)
            (let ((label (markup-option n :label)))
              (output (markup-body n) e)
              (output "(*" e)
              (output label e)
              (output ")" e))))


;;; info.scm ends here
