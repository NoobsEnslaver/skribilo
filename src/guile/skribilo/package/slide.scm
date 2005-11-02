;*=====================================================================*/
;*    serrano/prgm/project/skribe/skr/slide.skr                        */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Oct  3 12:22:13 2003                          */
;*    Last change :  Mon Aug 23 09:08:21 2004 (serrano)                */
;*    Copyright   :  2003-04 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    Skribe style for slides                                          */
;*=====================================================================*/

(define-skribe-module (skribilo package slide))

;*---------------------------------------------------------------------*/
;*    slide-options                                                    */
;*---------------------------------------------------------------------*/
(define &slide-load-options (skribe-load-options))

;*---------------------------------------------------------------------*/
;*    &slide-seminar-predocument ...                                   */
;*---------------------------------------------------------------------*/
(define &slide-seminar-predocument
   "\\special{landscape}
   \\slideframe{none}
   \\centerslidesfalse
   \\raggedslides[0pt]
   \\renewcommand{\\slideleftmargin}{0.2in}
   \\renewcommand{\\slidetopmargin}{0.3in}
   \\newdimen\\slidewidth \\slidewidth 9in")

;*---------------------------------------------------------------------*/
;*    &slide-seminar-maketitle ...                                     */
;*---------------------------------------------------------------------*/
(define &slide-seminar-maketitle
   "\\def\\labelitemi{$\\bullet$}
   \\def\\labelitemii{$\\circ$}
   \\def\\labelitemiii{$\\diamond$}
   \\def\\labelitemiv{$\\cdot$}
   \\pagestyle{empty}
   \\slideframe{none}
   \\centerslidestrue
   \\begin{slide}
   \\date{}
   \\maketitle
   \\end{slide}
   \\slideframe{none}
   \\centerslidesfalse")

;*---------------------------------------------------------------------*/
;*    &slide-prosper-predocument ...                                   */
;*---------------------------------------------------------------------*/
(define &slide-prosper-predocument
   "\\slideCaption{}\n")

;*---------------------------------------------------------------------*/
;*    %slide-the-slides ...                                            */
;*---------------------------------------------------------------------*/
(define %slide-the-slides '())
(define %slide-the-counter 0)
(define %slide-initialized #f)
(define %slide-latex-mode 'seminar)

;*---------------------------------------------------------------------*/
;*    %slide-initialize! ...                                           */
;*---------------------------------------------------------------------*/
(define (%slide-initialize!)
   (unless %slide-initialized
      (set! %slide-initialized #t)
      (case %slide-latex-mode
	 ((seminar)
	  (%slide-seminar-setup!))
	 ((advi)
	  (%slide-advi-setup!))
	 ((prosper)
	  (%slide-prosper-setup!))
	 (else
	  (skribe-error 'slide "Illegal latex mode" %slide-latex-mode)))))

;*---------------------------------------------------------------------*/
;*    slide ...                                                        */
;*---------------------------------------------------------------------*/
(define-markup (slide #!rest opt
		      #!key
		      (ident #f) (class #f)
		      (toc #t)
		      title (number #t)
		      (vspace #f) (vfill #f)
		      (transition #f)
		      (bg #f) (image #f))
   (%slide-initialize!)
   (let ((s (new container
	       (markup 'slide)
	       (ident (if (not ident)
			  (symbol->string (gensym 'slide))
			  ident))
	       (class class)
	       (required-options '(:title :number :toc))
	       (options `((:number
			   ,(cond
			       ((number? number)
				(set! %slide-the-counter number)
				number)
			       (number
				(set! %slide-the-counter
				      (+ 1 %slide-the-counter))
				%slide-the-counter)
			       (else
				#f)))
			  (:toc ,toc)
			  ,@(the-options opt :ident :class :vspace :toc)))
	       (body (if vspace
			 (list (slide-vspace vspace) (the-body opt))
			 (the-body opt))))))
      (set! %slide-the-slides (cons s %slide-the-slides))
      s))

;*---------------------------------------------------------------------*/
;*    ref ...                                                          */
;*---------------------------------------------------------------------*/
(define %slide-old-ref ref)

(define-markup (ref #!rest opt #!key (slide #f))
   (if (not slide)
       (apply %slide-old-ref opt)
       (new unresolved
	  (proc (lambda (n e env)
		   (cond
		      ((eq? slide 'next)
		       (let ((c (assq n %slide-the-slides)))
			  (if (pair? c)
			      (handle (cadr c))
			      #f)))
		      ((eq? slide 'prev)
		       (let ((c (assq n (reverse %slide-the-slides))))
			  (if (pair? c)
			      (handle (cadr c))
			      #f)))
		      ((number? slide)
		       (let loop ((s %slide-the-slides))
			  (cond
			     ((null? s)
			      #f)
			     ((= slide (markup-option (car s) :number))
			      (handle (car s)))
			     (else
			      (loop (cdr s))))))
		      (else
		       #f)))))))

;*---------------------------------------------------------------------*/
;*    slide-pause ...                                                  */
;*---------------------------------------------------------------------*/
(define-markup (slide-pause)
   (new markup
      (markup 'slide-pause)))

;*---------------------------------------------------------------------*/
;*    slide-vspace ...                                                 */
;*---------------------------------------------------------------------*/
(define-markup (slide-vspace #!rest opt #!key (unit 'cm))
   (new markup
      (markup 'slide-vspace)
      (options `((:unit ,unit) ,@(the-options opt :unit)))
      (body (the-body opt))))

;*---------------------------------------------------------------------*/
;*    slide-embed ...                                                  */
;*---------------------------------------------------------------------*/
(define-markup (slide-embed #!rest opt
			    #!key
			    command
			    (geometry-opt "-geometry")
			    (geometry #f) (rgeometry #f)
			    (transient #f) (transient-opt #f)
			    (alt #f)
			    &skribe-eval-location)
   (if (not (string? command))
       (skribe-error 'slide-embed
		     "No command provided"
		     command)
       (new markup
	  (markup 'slide-embed)
	  (loc &skribe-eval-location)
	  (required-options '(:alt))
	  (options `((:geometry-opt ,geometry-opt)
		     (:alt ,alt)
		     ,@(the-options opt :geometry-opt :alt)))
	  (body (the-body opt)))))

;*---------------------------------------------------------------------*/
;*    slide-record ...                                                 */
;*---------------------------------------------------------------------*/
(define-markup (slide-record #!rest opt #!key ident class tag (play #t))
   (if (not tag)
       (skribe-error 'slide-record "Tag missing" tag)
       (new markup
	  (markup 'slide-record)
	  (ident ident)
	  (class class)
	  (options `((:play ,play) ,@(the-options opt)))
	  (body (the-body opt)))))

;*---------------------------------------------------------------------*/
;*    slide-play ...                                                   */
;*---------------------------------------------------------------------*/
(define-markup (slide-play #!rest opt #!key ident class tag color)
   (if (not tag)
       (skribe-error 'slide-play "Tag missing" tag)
       (new markup
	  (markup 'slide-play)
	  (ident ident)
	  (class class)
	  (options `((:color ,(if color (skribe-use-color! color) #f))
		     ,@(the-options opt :color)))
	  (body (the-body opt)))))

;*---------------------------------------------------------------------*/
;*    slide-play* ...                                                  */
;*---------------------------------------------------------------------*/
(define-markup (slide-play* #!rest opt
			    #!key ident class color (scolor "#000000"))
   (let ((body (the-body opt)))
      (for-each (lambda (lbl)
		   (match-case lbl
		      ((?id ?col)
		       (skribe-use-color! col))))
		body)
      (new markup
	 (markup 'slide-play*)
	 (ident ident)
	 (class class)
	 (options `((:color ,(if color (skribe-use-color! color) #f))
		    (:scolor ,(if color (skribe-use-color! scolor) #f))
		    ,@(the-options opt :color :scolor)))
	 (body body))))

;*---------------------------------------------------------------------*/
;*    base                                                             */
;*---------------------------------------------------------------------*/
(let ((be (find-engine 'base)))
   (skribe-message "Base slides setup...\n")
   ;; slide-pause
   (markup-writer 'slide-pause be
      :action #f)
   ;; slide-vspace
   (markup-writer 'slide-vspace be
      :options '()
      :action #f)
   ;; slide-embed
   (markup-writer 'slide-embed be
      :options '(:alt :geometry-opt)
      :action (lambda (n e)
		 (output (markup-option n :alt) e)))
   ;; slide-record
   (markup-writer 'slide-record be
      :options '(:tag :play)
      :action (lambda (n e)
		 (output (markup-body n) e)))
   ;; slide-play
   (markup-writer 'slide-play be
      :options '(:tag :color)
      :action (lambda (n e)
		 (output (markup-option n :alt) e)))
   ;; slide-play*
   (markup-writer 'slide-play* be
      :options '(:tag :color :scolor)
      :action (lambda (n e)
		 (output (markup-option n :alt) e))))

;*---------------------------------------------------------------------*/
;*    slide-body-width ...                                             */
;*---------------------------------------------------------------------*/
(define (slide-body-width e)
   (let ((w (engine-custom e 'body-width)))
      (if (or (number? w) (string? w)) w 95.)))

;*---------------------------------------------------------------------*/
;*    html-slide-title ...                                             */
;*---------------------------------------------------------------------*/
(define (html-slide-title n e)
   (let* ((title (markup-body n))
	  (authors (markup-option n 'author))
	  (tbg (engine-custom e 'title-background))
	  (tfg (engine-custom e 'title-foreground))
	  (tfont (engine-custom e 'title-font)))
      (printf "<center><table cellspacing='0' cellpadding='0' width=\"~a\" class=\"skribetitle\"><tbody>\n<tr>"
	      (html-width (slide-body-width e)))
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
		    (printf "<font ~a><strong>" tfont)
		    (output title e)
		    (display "</strong></font>"))
		 (begin
		    (printf "<div class=\"skribetitle\"><strong><big><big><big>")
		    (output title e)
		    (display "</big></big></big></strong</div>")))
	     (display "</center>\n")))
      (if (not authors)
	  (display "\n")
	  (html-title-authors authors e))
      (if (string? tfg)
	  (display "</font>"))
      (display "</td></tr></tbody></table></center>\n")))

;*---------------------------------------------------------------------*/
;*    slide-number ...                                                 */
;*---------------------------------------------------------------------*/
(define (slide-number)
   (length (filter (lambda (n)
		      (and (is-markup? n 'slide)
			   (markup-option n :number)))
		   %slide-the-slides)))

;*---------------------------------------------------------------------*/
;*    html                                                             */
;*---------------------------------------------------------------------*/
(let ((he (find-engine 'html)))
   (skribe-message "HTML slides setup...\n")
   ;; &html-page-title
   (markup-writer '&html-document-title he
      :predicate (lambda (n e) %slide-initialized)
      :action html-slide-title)
   ;; slide
   (markup-writer 'slide he
      :options '(:title :number :transition :toc :bg)
      :before (lambda (n e)
		 (printf "<a name=\"~a\">" (markup-ident n))
		 (display "<br>\n"))
      :action (lambda (n e)
		 (let ((nb (markup-option n :number))
		       (t (markup-option n :title)))
		    (skribe-eval
		     (center
			(color :width (slide-body-width e)
			   :bg (or (markup-option n :bg) "#ffffff")
			   (table :width 100.
			      (tr (th :align 'left
				     (list
				      (if nb
					  (format "~a / ~a -- " nb
						  (slide-number)))
				      t)))
			      (tr (td (hrule)))
			      (tr (td :width 100. :align 'left
				     (markup-body n))))
			   (linebreak)))
		     e)))
      :after "<br>")
   ;; slide-vspace
   (markup-writer 'slide-vspace he
      :action (lambda (n e) (display "<br>"))))

;*---------------------------------------------------------------------*/
;*    latex                                                            */
;*---------------------------------------------------------------------*/
(define &latex-slide #f)
(define &latex-pause #f)
(define &latex-embed #f)
(define &latex-record #f)
(define &latex-play #f)
(define &latex-play* #f)

(let ((le (find-engine 'latex)))
   ;; slide-vspace
   (markup-writer 'slide-vspace le
      :options '(:unit)
      :action (lambda (n e)
		 (display "\n\\vspace{")
		 (output (markup-body n) e)
		 (printf " ~a}\n\n" (markup-option n :unit))))
   ;; slide-slide
   (markup-writer 'slide le
      :options '(:title :number :transition :vfill :toc :vspace :image)
      :action (lambda (n e)
		 (if (procedure? &latex-slide)
		     (&latex-slide n e))))
   ;; slide-pause
   (markup-writer 'slide-pause le
      :options '()
      :action (lambda (n e)
		 (if (procedure? &latex-pause)
		     (&latex-pause n e))))
   ;; slide-embed
   (markup-writer 'slide-embed le
      :options '(:alt :command :geometry-opt :geometry
		      :rgeometry :transient :transient-opt)
      :action (lambda (n e)
		 (if (procedure? &latex-embed)
		     (&latex-embed n e))))
   ;; slide-record
   (markup-writer 'slide-record le
      :options '(:tag :play)
      :action (lambda (n e)
		 (if (procedure? &latex-record)
		     (&latex-record n e))))
   ;; slide-play
   (markup-writer 'slide-play le
      :options '(:tag :color)
      :action (lambda (n e)
		 (if (procedure? &latex-play)
		     (&latex-play n e))))
   ;; slide-play*
   (markup-writer 'slide-play* le
      :options '(:tag :color :scolor)
      :action (lambda (n e)
		 (if (procedure? &latex-play*)
		     (&latex-play* n e)))))

;*---------------------------------------------------------------------*/
;*    %slide-seminar-setup! ...                                        */
;*---------------------------------------------------------------------*/
(define (%slide-seminar-setup!)
   (skribe-message "Seminar slides setup...\n")
   (let ((le (find-engine 'latex))
	 (be (find-engine 'base)))
      ;; latex configuration
      (define (seminar-slide n e)
	 (let ((nb (markup-option n :number))
	       (t (markup-option n :title)))
	    (display "\\begin{slide}\n")
	    (if nb (printf "~a/~a -- " nb (slide-number)))
	    (output t e)
	    (display "\\hrule\n"))
	 (output (markup-body n) e)
	 (if (markup-option n :vill) (display "\\vfill\n"))
	 (display "\\end{slide}\n"))
      (engine-custom-set! le 'documentclass
	 "\\documentclass[landscape]{seminar}\n")
      (let ((o (engine-custom le 'predocument)))
	 (engine-custom-set! le 'predocument
	    (if (string? o)
		(string-append &slide-seminar-predocument o)
		&slide-seminar-predocument)))
      (engine-custom-set! le 'maketitle
	 &slide-seminar-maketitle)
      (engine-custom-set! le 'hyperref-usepackage
	 "\\usepackage[setpagesize=false]{hyperref}\n")
      ;; slide-slide
      (set! &latex-slide seminar-slide)))

;*---------------------------------------------------------------------*/
;*    %slide-advi-setup! ...                                           */
;*---------------------------------------------------------------------*/
(define (%slide-advi-setup!)
   (skribe-message "Generating `Advi Seminar' slides...\n")
   (let ((le (find-engine 'latex))
	 (be (find-engine 'base)))
      (define (advi-geometry geo)
	 (let ((r (pregexp-match "([0-9]+)x([0-9]+)" geo)))
	    (if (pair? r)
		(let* ((w (cadr r))
		       (w' (string->integer w))
		       (w'' (number->string (/ w' *skribe-slide-advi-scale*)))
		       (h (caddr r))
		       (h' (string->integer h))
		       (h'' (number->string (/ h' *skribe-slide-advi-scale*))))
		   (values "" (string-append w "x" h "+!x+!y")))
		(let ((r (pregexp-match "([0-9]+)x([0-9]+)[+](-?[0-9]+)[+](-?[0-9]+)" geo)))
		   (if (pair? r)
		       (let ((w (number->string (/ (string->integer (cadr r))
						   *skribe-slide-advi-scale*)))
			     (h (number->string (/ (string->integer (caddr r))
						   *skribe-slide-advi-scale*)))
			     (x (cadddr r))
			     (y (car (cddddr r))))
			  (values (string-append "width=" w "cm,height=" h "cm")
				  "!g"))
		       (values "" geo))))))
      (define (advi-transition trans)
	 (cond
	    ((string? trans)
	     (printf "\\advitransition{~s}" trans))
	    ((and (symbol? trans)
		  (memq trans '(wipe block slide)))
	     (printf "\\advitransition{~s}" trans))
	    (else
	     #f)))
      ;; latex configuration
      (define (advi-slide n e)
	 (let ((i (markup-option n :image))
	       (n (markup-option n :number))
	       (t (markup-option n :title))
	       (lt (markup-option n :transition))
	       (gt (engine-custom e 'transition)))
	    (if (and i (engine-custom e 'advi))
		(printf "\\advibg[global]{image=~a}\n"
			(if (and (pair? i)
				 (null? (cdr i))
				 (string? (car i)))
			    (car i)
			    i)))
	    (display "\\begin{slide}\n")
	    (advi-transition (or lt gt))
	    (if n (printf "~a/~a -- " n (slide-number)))
	    (output t e)
	    (display "\\hrule\n"))
	 (output (markup-body n) e)
	 (if (markup-option n :vill) (display "\\vfill\n"))
	 (display "\\end{slide}\n\n\n"))
      ;; advi record
      (define (advi-record n e)
	 (display "\\advirecord")
	 (when (markup-option n :play) (display "[play]"))
	 (printf "{~a}{" (markup-option n :tag))
	 (output (markup-body n) e)
	 (display "}"))
      ;; advi play
      (define (advi-play n e)
	 (display "\\adviplay")
	 (let ((c (markup-option n :color)))
	    (when c
	       (display "[")
	       (display (skribe-get-latex-color c))
	       (display "]")))
	 (printf "{~a}" (markup-option n :tag)))
      ;; advi play*
      (define (advi-play* n e)
	 (let ((c (skribe-get-latex-color (markup-option n :color)))
	       (d (skribe-get-latex-color (markup-option n :scolor))))
	    (let loop ((lbls (markup-body n))
		       (last #f))
	       (when last
		  (display "\\adviplay[")
		  (display d)
		  (printf "]{~a}" last))
	       (when (pair? lbls)
		  (let ((lbl (car lbls)))
		     (match-case lbl
			((?id ?col)
			 (display "\\adviplay[")
			 (display (skribe-get-latex-color col))
			 (printf "]{" ~a "}" id)
			 (skribe-eval (slide-pause) e)
			 (loop (cdr lbls) id))
			(else
			 (display "\\adviplay[")
			 (display c)
			 (printf "]{~a}" lbl)
			 (skribe-eval (slide-pause) e)
			 (loop (cdr lbls) lbl))))))))
      (engine-custom-set! le 'documentclass
	 "\\documentclass{seminar}\n")
      (let ((o (engine-custom le 'predocument)))
	 (engine-custom-set! le 'predocument
	    (if (string? o)
		(string-append &slide-seminar-predocument o)
		&slide-seminar-predocument)))
      (engine-custom-set! le 'maketitle
	 &slide-seminar-maketitle)
      (engine-custom-set! le 'usepackage
	 (string-append "\\usepackage{advi}\n"
			(engine-custom le 'usepackage)))
      ;; slide
      (set! &latex-slide advi-slide)
      (set! &latex-pause
	    (lambda (n e) (display "\\adviwait\n")))
      (set! &latex-embed
	    (lambda (n e)
	       (let ((geometry-opt (markup-option n :geometry-opt))
		     (geometry (markup-option n :geometry))
		     (rgeometry (markup-option n :rgeometry))
		     (transient (markup-option n :transient))
		     (transient-opt (markup-option n :transient-opt))
		     (cmd (markup-option n :command)))
		  (let* ((a (string-append "ephemeral="
					   (symbol->string (gensym))))
			 (c (cond
			       (geometry
				(string-append cmd " "
					       geometry-opt " "
					       geometry))
			       (rgeometry
				(multiple-value-bind (aopt dopt)
				   (advi-geometry rgeometry)
				   (set! a (string-append a "," aopt))
				   (string-append cmd " "
						  geometry-opt " "
						  dopt)))
			       (else
				cmd)))
			 (c (if (and transient transient-opt)
				(string-append c " " transient-opt " !p")
				c)))
		     (printf "\\adviembed[~a]{~a}\n" a c)))))
      (set! &latex-record advi-record)
      (set! &latex-play advi-play)
      (set! &latex-play* advi-play*)))

;*---------------------------------------------------------------------*/
;*    %slide-prosper-setup! ...                                        */
;*---------------------------------------------------------------------*/
(define (%slide-prosper-setup!)
   (skribe-message "Generating `Prosper' slides...\n")
   (let ((le (find-engine 'latex))
	 (be (find-engine 'base))
	 (overlay-count 0))
      ;; transitions
      (define (prosper-transition trans)
	 (cond
	    ((string? trans)
	     (printf "[~s]" trans))
	    ((eq? trans 'slide)
	     (printf "[Blinds]"))
	    ((and (symbol? trans)
		  (memq trans '(split blinds box wipe dissolve glitter)))
	     (printf "[~s]"
		     (string-upcase (symbol->string trans))))
	    (else
	     #f)))
      ;; latex configuration
      (define (prosper-slide n e)
	 (let* ((i (markup-option n :image))
		(t (markup-option n :title))
		(lt (markup-option n :transition))
		(gt (engine-custom e 'transition))
		(pa (search-down (lambda (x) (is-markup? x 'slide-pause)) n))
		(lpa (length pa)))
	    (set! overlay-count 1)
	    (if (>= lpa 1) (printf "\\overlays{~a}{%\n" (+ 1 lpa)))
	    (display "\\begin{slide}")
	    (prosper-transition (or lt gt))
	    (display "{")
	    (output t e)
	    (display "}\n")
	    (output (markup-body n) e)
	    (display "\\end{slide}\n")
	    (if (>= lpa 1) (display "}\n"))
	    (newline)
	    (newline)))
      (engine-custom-set! le 'documentclass "\\documentclass[pdf,skribe,slideColor,nototal]{prosper}\n")
      (let* ((cap (engine-custom le 'slide-caption))
	     (o (engine-custom le 'predocument))
	     (n (if (string? cap)
		    (format "~a\\slideCaption{~a}\n"
			    &slide-prosper-predocument
			    cap)
		    &slide-prosper-predocument)))
	 (engine-custom-set! le 'predocument
	    (if (string? o) (string-append n o) n)))
      (engine-custom-set! le 'hyperref-usepackage "\\usepackage{hyperref}\n")
      ;; writers
      (set! &latex-slide prosper-slide)
      (set! &latex-pause
	    (lambda (n e)
	       (set! overlay-count (+ 1 overlay-count))
	       (printf "\\FromSlide{~s}%\n" overlay-count)))))

;*---------------------------------------------------------------------*/
;*    Setup ...                                                        */
;*---------------------------------------------------------------------*/
(let* ((opt &slide-load-options)
       (p (memq :prosper opt)))
   (if (and (pair? p) (pair? (cdr p)) (cadr p))
       ;; prosper
       (set! %slide-latex-mode 'prosper)
       (let ((a (memq :advi opt)))
	  (if (and (pair? a) (pair? (cdr a)) (cadr a))
	      ;; advi
	      (set! %slide-latex-mode 'advi)))))
