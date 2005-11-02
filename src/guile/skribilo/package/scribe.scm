;*=====================================================================*/
;*    serrano/prgm/project/skribe/skr/scribe.skr                       */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Tue Jul 29 10:07:21 2003                          */
;*    Last change :  Wed Oct  8 09:56:52 2003 (serrano)                */
;*    Copyright   :  2003 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    Scribe Compatibility kit                                         */
;*=====================================================================*/

(define-skribe-module (skribilo package scribe))

;*---------------------------------------------------------------------*/
;*    style ...                                                        */
;*---------------------------------------------------------------------*/
(define (style . styles)
   (define (load-style style)
      (let ((name (cond
		     ((string? style)
		      style)
		     ((symbol? style)
		      (string-append (symbol->string style) ".scr")))))
	 (skribe-load name :engine *skribe-engine*)))
   (for-each load-style styles))

;*---------------------------------------------------------------------*/
;*    chapter ...                                                      */
;*---------------------------------------------------------------------*/
(define skribe-chapter chapter)

(define-markup (chapter #!rest opt #!key title subtitle split number toc file)
   (apply skribe-chapter 
	  :title (or title subtitle)
	  :number number
	  :toc toc
	  :file file
	  (the-body opt)))

;*---------------------------------------------------------------------*/
;*    table-of-contents ...                                            */
;*---------------------------------------------------------------------*/
(define-markup (table-of-contents #!rest opts #!key chapter section subsection)
   (apply toc opts))

;*---------------------------------------------------------------------*/
;*    frame ...                                                        */
;*---------------------------------------------------------------------*/
(define skribe-frame frame)

(define-markup (frame #!rest opt #!key width margin)
   (apply skribe-frame 
	  :width (if (real? width) (* 100 width) width)
	  :margin margin
	  (the-body opt)))

;*---------------------------------------------------------------------*/
;*    copyright ...                                                    */
;*---------------------------------------------------------------------*/
(define (copyright)
   (symbol 'copyright))

;*---------------------------------------------------------------------*/
;*    sect ...                                                         */
;*---------------------------------------------------------------------*/
(define (sect)
   (symbol 'section))

;*---------------------------------------------------------------------*/
;*    euro ...                                                         */
;*---------------------------------------------------------------------*/
(define (euro)
   (symbol 'euro))

;*---------------------------------------------------------------------*/
;*    tab ...                                                          */
;*---------------------------------------------------------------------*/
(define (tab)
   (char #\tab))

;*---------------------------------------------------------------------*/
;*    space ...                                                        */
;*---------------------------------------------------------------------*/
(define (space)
   (char #\space))

;*---------------------------------------------------------------------*/
;*    print-bibliography ...                                           */
;*---------------------------------------------------------------------*/
(define-markup (print-bibliography #!rest opts 
				   #!key all (sort bib-sort/authors))
   (the-bibliography all sort))

;*---------------------------------------------------------------------*/
;*    linebreak ...                                                    */
;*---------------------------------------------------------------------*/
(define skribe-linebreak linebreak)

(define-markup (linebreak . lnum)
   (cond
      ((null? lnum)
       (skribe-linebreak))
      ((string? (car lnum))
       (skribe-linebreak (string->number (car lnum))))
      (else
       (skribe-linebreak (car lnum)))))

;*---------------------------------------------------------------------*/
;*    ref ...                                                          */
;*---------------------------------------------------------------------*/
(define skribe-ref ref)

(define-markup (ref #!rest opts 
		    #!key scribe url id page figure mark 
		    chapter section subsection subsubsection subsubsection
		    bib bib+ number)
   (let ((bd (the-body opts))
	 (args (apply append (the-options opts :id))))
      (if id (set! args (cons* :mark id args)))
      (if (pair? bd) (set! args (cons* :text bd args)))
      (apply skribe-ref args)))

;*---------------------------------------------------------------------*/
;*    indexes ...                                                      */
;*---------------------------------------------------------------------*/
(define *scribe-indexes*
   (list (cons "theindex" (make-index "theindex"))))

(define skribe-index index)
(define skribe-make-index make-index)

(define-markup (make-index index)
   (let ((i (skribe-make-index index)))
      (set! *scribe-indexes* (cons (cons index i) *scribe-indexes*))
      i))

(define-markup (index #!rest opts #!key note index shape)
   (let ((i (if (not index)
		"theindex"
		(let ((i (assoc index *scribe-indexes*)))
		   (if (pair? i)
		       (cdr i)
		       (make-index index))))))
      (apply skribe-index :note note :index i :shape shape (the-body opts))))

(define-markup (print-index #!rest opts 
			    #!key split (char-offset 0) (header-limit 100))
   (apply the-index 
	  :split split 
	  :char-offset char-offset
	  :header-limit header-limit
	  (map (lambda (i)
		(let ((c (assoc i *scribe-indexes*)))
		   (if (pair? c)
		       (cdr c)
		       (skribe-error 'the-index "Unknown index" i))))
	       (the-body opts))))
	      
;*---------------------------------------------------------------------*/
;*    format?                                                          */
;*---------------------------------------------------------------------*/
(define (scribe-format? fmt) #f)

;*---------------------------------------------------------------------*/
;*    scribe-url ...                                                   */
;*---------------------------------------------------------------------*/
(define (scribe-url) (skribe-url))

;*---------------------------------------------------------------------*/
;*    Various configurations                                           */
;*---------------------------------------------------------------------*/
(define *scribe-background* #f)
(define *scribe-foreground* #f)
(define *scribe-tbackground* #f)
(define *scribe-tforeground* #f)
(define *scribe-title-font* #f)
(define *scribe-author-font* #f)
(define *scribe-chapter-numbering* #f)
(define *scribe-footer* #f)
(define *scribe-prgm-color* #f)

;*---------------------------------------------------------------------*/
;*    prgm ...                                                         */
;*---------------------------------------------------------------------*/
(define-markup (prgm #!rest opts
		     #!key lnum lnumwidth language bg frame (width 1.)
		     colors (monospace #t))
   (let* ((w (cond
		((real? width) (* width 100.))
		((number? width) width)
		(else 100.)))
	  (body (if language 
		    (source :language language (the-body opts))
		    (the-body opts)))
	  (body (if monospace
		    (prog :line lnum body)
		    body))
	  (body (if bg
		    (color :width 100. :bg bg body)
		    body)))
      (skribe-frame :width w
		    :border (if frame 1 #f)
		    body)))
   
;*---------------------------------------------------------------------*/
;*    latex configuration                                              */
;*---------------------------------------------------------------------*/
(define *scribe-tex-predocument* #f)

;*---------------------------------------------------------------------*/
;*    latex-prelude ...                                                */
;*---------------------------------------------------------------------*/
(define (latex-prelude e)
   (if (engine-format? "latex" e)
       (begin
	  (if *scribe-tex-predocument*
	      (engine-custom-set! e 'predocument *scribe-tex-predocument*)))))
      
;*---------------------------------------------------------------------*/
;*    html-prelude ...                                                 */
;*---------------------------------------------------------------------*/
(define (html-prelude e)
   (if (engine-format? "html" e)
       (begin
	  #f)))
      
;*---------------------------------------------------------------------*/
;*    prelude                                                          */
;*---------------------------------------------------------------------*/
(let ((p (user-prelude)))
   (user-prelude-set! (lambda (e) (p e) (latex-prelude e))))
