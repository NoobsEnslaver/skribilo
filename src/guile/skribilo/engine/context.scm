;;;;
;;;; context.skr	-- ConTeXt mode for Skribe
;;;;
;;;; Copyright � 2004 Erick Gallesio - I3S-CNRS/ESSI <eg@essi.fr>
;;;;
;;;;
;;;; This program is free software; you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation; either version 2 of the License, or
;;;; (at your option) any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License
;;;; along with this program; if not, write to the Free Software
;;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;;;; USA.
;;;;
;;;;           Author: Erick Gallesio [eg@essi.fr]
;;;;    Creation date: 23-Sep-2004 17:21 (eg)
;;;; Last file update:  3-Nov-2004 12:54 (eg)
;;;;

(define-skribe-module (skribilo engine context))

;;;; ======================================================================
;;;;	context-customs ...
;;;; ======================================================================
(define context-customs
  '((source-comment-color "#ffa600")
    (source-error-color "red")
    (source-define-color "#6959cf")
    (source-module-color "#1919af")
    (source-markup-color "#1919af")
    (source-thread-color "#ad4386")
    (source-string-color "red")
    (source-bracket-color "red")
    (source-type-color "#00cf00")
    (index-page-ref #t)
    (image-format ("jpg"))
    (font-size 11)
    (font-type "roman")
    (user-style #f)
    (document-style "book")))

;;;; ======================================================================
;;;;	context-encoding ...
;;;; ======================================================================
(define context-encoding
  '((#\# "\\type{#}")
    (#\| "\\type{|}")
    (#\{ "$\\{$")
    (#\} "$\\}$")
    (#\~ "\\type{~}")
    (#\& "\\type{&}")
    (#\_ "\\type{_}")
    (#\^ "\\type{^}")
    (#\[ "\\type{[}")
    (#\] "\\type{]}")
    (#\< "\\type{<}")
    (#\> "\\type{>}")
    (#\$ "\\type{$}")
    (#\% "\\%")
    (#\\ "$\\backslash$")))

;;;; ======================================================================
;;;;	context-pre-encoding ...
;;;; ======================================================================
(define context-pre-encoding
  (append '((#\space "~")
	    (#\~ "\\type{~}"))
	  context-encoding))


;;;; ======================================================================
;;;;	context-symbol-table ...
;;;; ======================================================================
(define (context-symbol-table math)
   `(("iexcl" "!`")
     ("cent" "c")
     ("pound" "\\pounds")
     ("yen" "Y")
     ("section" "\\S")
     ("mul" ,(math "^-"))
     ("copyright" "\\copyright")
     ("lguillemet" ,(math "\\ll"))
     ("not" ,(math "\\neg"))
     ("degree" ,(math "^{\\small{o}}"))
     ("plusminus" ,(math "\\pm"))
     ("micro" ,(math "\\mu"))
     ("paragraph" "\\P")
     ("middot" ,(math "\\cdot"))
     ("rguillemet" ,(math "\\gg"))
     ("1/4" ,(math "\\frac{1}{4}"))
     ("1/2" ,(math "\\frac{1}{2}"))
     ("3/4" ,(math "\\frac{3}{4}"))
     ("iquestion" "?`")
     ("Agrave" "\\`{A}")
     ("Aacute" "\\'{A}")
     ("Acircumflex" "\\^{A}")
     ("Atilde" "\\~{A}")
     ("Amul" "\\\"{A}")
     ("Aring" "{\\AA}")
     ("AEligature" "{\\AE}")
     ("Oeligature" "{\\OE}")
     ("Ccedilla" "{\\c{C}}")
     ("Egrave" "{\\`{E}}")
     ("Eacute" "{\\'{E}}")
     ("Ecircumflex" "{\\^{E}}")
     ("Euml" "\\\"{E}")
     ("Igrave" "{\\`{I}}")
     ("Iacute" "{\\'{I}}")
     ("Icircumflex" "{\\^{I}}")
     ("Iuml" "\\\"{I}")
     ("ETH" "D")
     ("Ntilde" "\\~{N}")
     ("Ograve" "\\`{O}")
     ("Oacute" "\\'{O}")
     ("Ocurcumflex" "\\^{O}")
     ("Otilde" "\\~{O}")
     ("Ouml" "\\\"{O}")
     ("times" ,(math "\\times"))
     ("Oslash" "\\O")
     ("Ugrave" "\\`{U}")
     ("Uacute" "\\'{U}")
     ("Ucircumflex" "\\^{U}")
     ("Uuml" "\\\"{U}")
     ("Yacute" "\\'{Y}")
     ("szlig" "\\ss")
     ("agrave" "\\`{a}")
     ("aacute" "\\'{a}")
     ("acircumflex" "\\^{a}")
     ("atilde" "\\~{a}")
     ("amul" "\\\"{a}")
     ("aring" "\\aa")
     ("aeligature" "\\ae")
     ("oeligature" "{\\oe}")
     ("ccedilla" "{\\c{c}}")
     ("egrave" "{\\`{e}}")
     ("eacute" "{\\'{e}}")
     ("ecircumflex" "{\\^{e}}")
     ("euml" "\\\"{e}")
     ("igrave" "{\\`{\\i}}")
     ("iacute" "{\\'{\\i}}")
     ("icircumflex" "{\\^{\\i}}")
     ("iuml" "\\\"{\\i}")
     ("ntilde" "\\~{n}")
     ("ograve" "\\`{o}")
     ("oacute" "\\'{o}")
     ("ocurcumflex" "\\^{o}")
     ("otilde" "\\~{o}")
     ("ouml" "\\\"{o}")
     ("divide" ,(math "\\div"))
     ("oslash" "\\o")
     ("ugrave" "\\`{u}")
     ("uacute" "\\'{u}")
     ("ucircumflex" "\\^{u}")
     ("uuml" "\\\"{u}")
     ("yacute" "\\'{y}")
     ("ymul" "\\\"{y}")
     ;; Greek
     ("Alpha" "A")
     ("Beta" "B")
     ("Gamma" ,(math "\\Gamma"))
     ("Delta" ,(math "\\Delta"))
     ("Epsilon" "E")
     ("Zeta" "Z")
     ("Eta" "H")
     ("Theta" ,(math "\\Theta"))
     ("Iota" "I")
     ("Kappa" "K")
     ("Lambda" ,(math "\\Lambda"))
     ("Mu" "M")
     ("Nu" "N")
     ("Xi" ,(math "\\Xi"))
     ("Omicron" "O")
     ("Pi" ,(math "\\Pi"))
     ("Rho" "P")
     ("Sigma" ,(math "\\Sigma"))
     ("Tau" "T")
     ("Upsilon" ,(math "\\Upsilon"))
     ("Phi" ,(math "\\Phi"))
     ("Chi" "X")
     ("Psi" ,(math "\\Psi"))
     ("Omega" ,(math "\\Omega"))
     ("alpha" ,(math "\\alpha"))
     ("beta" ,(math "\\beta"))
     ("gamma" ,(math "\\gamma"))
     ("delta" ,(math "\\delta"))
     ("epsilon" ,(math "\\varepsilon"))
     ("zeta" ,(math "\\zeta"))
     ("eta" ,(math "\\eta"))
     ("theta" ,(math "\\theta"))
     ("iota" ,(math "\\iota"))
     ("kappa" ,(math "\\kappa"))
     ("lambda" ,(math "\\lambda"))
     ("mu" ,(math "\\mu"))
     ("nu" ,(math "\\nu"))
     ("xi" ,(math "\\xi"))
     ("omicron" ,(math "\\o"))
     ("pi" ,(math "\\pi"))
     ("rho" ,(math "\\rho"))
     ("sigmaf" ,(math "\\varsigma"))
     ("sigma" ,(math "\\sigma"))
     ("tau" ,(math "\\tau"))
     ("upsilon" ,(math "\\upsilon"))
     ("phi" ,(math "\\varphi"))
     ("chi" ,(math "\\chi"))
     ("psi" ,(math "\\psi"))
     ("omega" ,(math "\\omega"))
     ("thetasym" ,(math "\\vartheta"))
     ("piv" ,(math "\\varpi"))
     ;; punctuation
     ("bullet" ,(math "\\bullet"))
     ("ellipsis" ,(math "\\ldots"))
     ("weierp" ,(math "\\wp"))
     ("image" ,(math "\\Im"))
     ("real" ,(math "\\Re"))
     ("tm" ,(math "^{\\sc\\tiny{tm}}"))
     ("alef" ,(math "\\aleph"))
     ("<-" ,(math "\\leftarrow"))
     ("<--" ,(math "\\longleftarrow"))
     ("uparrow" ,(math "\\uparrow"))
     ("->" ,(math "\\rightarrow"))
     ("-->" ,(math "\\longrightarrow"))
     ("downarrow" ,(math "\\downarrow"))
     ("<->" ,(math "\\leftrightarrow"))
     ("<-->" ,(math "\\longleftrightarrow"))
     ("<+" ,(math "\\hookleftarrow"))
     ("<=" ,(math "\\Leftarrow"))
     ("<==" ,(math "\\Longleftarrow"))
     ("Uparrow" ,(math "\\Uparrow"))
     ("=>" ,(math "\\Rightarrow"))
     ("==>" ,(math "\\Longrightarrow"))
     ("Downarrow" ,(math "\\Downarrow"))
     ("<=>" ,(math "\\Leftrightarrow"))
     ("<==>" ,(math "\\Longleftrightarrow"))
     ;; Mathematical operators
     ("forall" ,(math "\\forall"))
     ("partial" ,(math "\\partial"))
     ("exists" ,(math "\\exists"))
     ("emptyset" ,(math "\\emptyset"))
     ("infinity" ,(math "\\infty"))
     ("nabla" ,(math "\\nabla"))
     ("in" ,(math "\\in"))
     ("notin" ,(math "\\notin"))
     ("ni" ,(math "\\ni"))
     ("prod" ,(math "\\Pi"))
     ("sum" ,(math "\\Sigma"))
     ("asterisk" ,(math "\\ast"))
     ("sqrt" ,(math "\\surd"))
     ("propto" ,(math "\\propto"))
     ("angle" ,(math "\\angle"))
     ("and" ,(math "\\wedge"))
     ("or" ,(math "\\vee"))
     ("cap" ,(math "\\cap"))
     ("cup" ,(math "\\cup"))
     ("integral" ,(math "\\int"))
     ("models" ,(math "\\models"))
     ("vdash" ,(math "\\vdash"))
     ("dashv" ,(math "\\dashv"))
     ("sim" ,(math "\\sim"))
     ("cong" ,(math "\\cong"))
     ("approx" ,(math "\\approx"))
     ("neq" ,(math "\\neq"))
     ("equiv" ,(math "\\equiv"))
     ("le" ,(math "\\leq"))
     ("ge" ,(math "\\geq"))
     ("subset" ,(math "\\subset"))
     ("supset" ,(math "\\supset"))
     ("subseteq" ,(math "\\subseteq"))
     ("supseteq" ,(math "\\supseteq"))
     ("oplus" ,(math "\\oplus"))
     ("otimes" ,(math "\\otimes"))
     ("perp" ,(math "\\perp"))
     ("mid" ,(math "\\mid"))
     ("lceil" ,(math "\\lceil"))
     ("rceil" ,(math "\\rceil"))
     ("lfloor" ,(math "\\lfloor"))
     ("rfloor" ,(math "\\rfloor"))
     ("langle" ,(math "\\langle"))
     ("rangle" ,(math "\\rangle"))
     ;; Misc
     ("loz" ,(math "\\diamond"))
     ("spades" ,(math "\\spadesuit"))
     ("clubs" ,(math "\\clubsuit"))
     ("hearts" ,(math "\\heartsuit"))
     ("diams" ,(math "\\diamondsuit"))
     ("euro" "\\euro{}")
     ;; ConTeXt
     ("dag" "\\dag")
     ("ddag" "\\ddag")
     ("circ" ,(math "\\circ"))
     ("top" ,(math "\\top"))
     ("bottom" ,(math "\\bot"))
     ("lhd" ,(math "\\triangleleft"))
     ("rhd" ,(math "\\triangleright"))
     ("parallel" ,(math "\\parallel"))))

;;;; ======================================================================
;;;;	context-width
;;;; ======================================================================
(define (context-width width)
  (cond
    ((string? width)
     width)
    ((and (number? width) (inexact? width))
     (string-append (number->string (/ width 100.)) "\\textwidth"))
    (else
     (string-append (number->string width) "pt"))))

;;;; ======================================================================
;;;;	context-dim
;;;; ======================================================================
(define (context-dim dimension)
  (cond
    ((string? dimension)
     dimension)
    ((number? dimension)
     (string-append (number->string (inexact->exact (round dimension)))
		    "pt"))))

;;;; ======================================================================
;;;;	context-url
;;;; ======================================================================
(define(context-url url text e)
  (let ((name (gensym 'url))
	(text (or text url)))
    (printf "\\useURL[~A][~A][][" name url)
    (output text e)
    (printf "]\\from[~A]" name)))

;;;; ======================================================================
;;;;	Color Management ...
;;;; ======================================================================
(define *skribe-context-color-table* (make-hashtable))

(define (skribe-color->context-color spec)
  (receive (r g b)
     (skribe-color->rgb spec)
     (let ((ff (exact->inexact #xff)))
       (format "r=~a,g=~a,b=~a"
	       (number->string (/ r ff))
	       (number->string (/ g ff))
	       (number->string (/ b ff))))))


(define (skribe-declare-used-colors)
  (printf "\n%%Colors\n")
  (for-each (lambda (spec)
	      (let ((c (hashtable-get *skribe-context-color-table* spec)))
		(unless (string? c)
		  ;; Color was never used before
		  (let ((name (symbol->string (gensym 'col))))
		    (hashtable-put! *skribe-context-color-table* spec name)
		    (printf "\\definecolor[~A][~A]\n"
			    name
			    (skribe-color->context-color spec))))))
	    (skribe-get-used-colors))
  (newline))

(define (skribe-declare-standard-colors engine)
  (for-each (lambda (x)
	      (skribe-use-color! (engine-custom engine x)))
	    '(source-comment-color source-define-color source-module-color
	      source-markup-color  source-thread-color source-string-color
	      source-bracket-color source-type-color)))

(define (skribe-get-color spec)
  (let ((c (and (hashtable? *skribe-context-color-table*)
		(hashtable-get *skribe-context-color-table* spec))))
    (if (not (string? c))
	(skribe-error 'context "Can't find color" spec)
	c)))

;;;; ======================================================================
;;;;	context-engine ...
;;;; ======================================================================
(define context-engine
   (default-engine-set!
      (make-engine 'context
	 :version 1.0
	 :format "context"
	 :delegate (find-engine 'base)
	 :filter (make-string-replace context-encoding)
	 :symbol-table (context-symbol-table (lambda (m) (format #f "$~a$" m)))
	 :custom context-customs)))

;;;; ======================================================================
;;;;	document ...
;;;; ======================================================================
(markup-writer 'document
   :options '(:title :subtitle :author :ending :env)
   :before (lambda (n e)
	     ;; Prelude
	     (printf "% interface=en output=pdftex\n")
	     (display "%%%% -*- TeX -*-\n")
	     (printf "%%%% File automatically generated by Skribe ~A on ~A\n\n"
		     (skribe-release) (date))
	     ;; Make URLs active
	     (printf "\\setupinteraction[state=start]\n")
	     ;; Choose the document font
	     (printf "\\setupbodyfont[~a,~apt]\n" (engine-custom e 'font-type)
		     (engine-custom e 'font-size))
	     ;; Color
	     (display "\\setupcolors[state=start]\n")
	     ;; Load Style
	     (printf "\\input skribe-context-~a.tex\n"
		     (engine-custom e 'document-style))
	     ;; Insert User customization
	     (let ((s (engine-custom e 'user-style)))
	       (when s (printf "\\input ~a\n" s)))
	     ;; Output used colors
	     (skribe-declare-standard-colors e)
	     (skribe-declare-used-colors)

	     (display "\\starttext\n\\StartTitlePage\n")
	     ;; title
	     (let ((t (markup-option n :title)))
	       (when t
		 (skribe-eval (new markup
				   (markup '&context-title)
				   (body t)
				   (options
				      `((subtitle ,(markup-option n :subtitle)))))
			      e
			      :env `((parent ,n)))))
	     ;; author(s)
	     (let ((a (markup-option n :author)))
	       (when a
		 (if (list? a)
		     ;; List of authors. Use multi-columns
		     (begin
		       (printf "\\defineparagraphs[Authors][n=~A]\n" (length a))
		       (display "\\startAuthors\n")
		       (let Loop ((l a))
			 (unless (null? l)
			   (output (car l) e)
			   (unless (null? (cdr l))
			     (display "\\nextAuthors\n")
			     (Loop (cdr l)))))
		       (display "\\stopAuthors\n\n"))
		     ;; One author, that's easy
		     (output a e))))
	     ;; End of the title
	     (display "\\StopTitlePage\n"))
   :after (lambda (n e)
	     (display "\n\\stoptext\n")))



;;;; ======================================================================
;;;;	&context-title ...
;;;; ======================================================================
(markup-writer '&context-title
   :before "{\\DocumentTitle{"
   :action (lambda (n e)
	     (output (markup-body n) e)
	     (let ((sub (markup-option n 'subtitle)))
	       (when sub
		 (display "\\\\\n\\switchtobodyfont[16pt]\\it{")
		 (output sub e)
		 (display "}\n"))))
   :after "}}")

;;;; ======================================================================
;;;;	author ...
;;;; ======================================================================
(markup-writer 'author
   :options '(:name :title :affiliation :email :url :address :phone :photo :align)
   :action (lambda (n e)
	     (let ((name        (markup-option n :name))
		   (title       (markup-option n :title))
		   (affiliation (markup-option n :affiliation))
		   (email       (markup-option n :email))
		   (url         (markup-option n :url))
		   (address     (markup-option n :address))
		   (phone       (markup-option n :phone))
		   (out         (lambda (n)
				  (output n e)
				  (display "\\\\\n"))))
	       (display "{\\midaligned{")
	       (when name	(out name))
	       (when title	(out title))
	       (when affiliation	(out affiliation))
	       (when (pair? address)	(for-each out address))
	       (when phone		(out phone))
	       (when email		(out email))
	       (when url		(out url))
	       (display "}}\n"))))


;;;; ======================================================================
;;;;	toc ...
;;;; ======================================================================
(markup-writer 'toc
   :options '()
   :action (lambda (n e) (display "\\placecontent\n")))

;;;; ======================================================================
;;;;	context-block-before ...
;;;; ======================================================================
(define (context-block-before name name-unnum)
   (lambda (n e)
      (let ((num (markup-option n :number)))
	 (printf "\n\n%% ~a\n" (string-canonicalize (markup-ident n)))
	 (printf "\\~a[~a]{" (if num name name-unnum)
		 (string-canonicalize (markup-ident n)))
	 (output (markup-option n :title) e)
	 (display "}\n"))))


;;;; ======================================================================
;;;;	chapter, section,  ...
;;;; ======================================================================
(markup-writer 'chapter
   :options '(:title :number :toc :file :env)
   :before (context-block-before 'chapter 'title))


(markup-writer 'section
   :options '(:title :number :toc :file :env)
   :before (context-block-before 'section 'subject))


(markup-writer 'subsection
   :options '(:title :number :toc :file :env)
   :before (context-block-before 'subsection 'subsubject))


(markup-writer 'subsubsection
   :options '(:title :number :toc :file :env)
   :before (context-block-before 'subsubsection 'subsubsubject))

;;;; ======================================================================
;;;;    paragraph ...
;;;; ======================================================================
(markup-writer 'paragraph
   :options '(:title :number :toc :env)
   :after "\\par\n")

;;;; ======================================================================
;;;;	footnote ...
;;;; ======================================================================
(markup-writer 'footnote
   :before "\\footnote{"
   :after "}")

;;;; ======================================================================
;;;;	linebreak ...
;;;; ======================================================================
(markup-writer 'linebreak
   :action "\\crlf ")

;;;; ======================================================================
;;;;	hrule ...
;;;; ======================================================================
(markup-writer 'hrule
   :options '(:width :height)
   :before (lambda (n e)
	     (printf "\\blackrule[width=~A,height=~A]\n"
		     (context-width  (markup-option n :width))
		     (context-dim    (markup-option n :height)))))

;;;; ======================================================================
;;;;	color ...
;;;; ======================================================================
(markup-writer 'color
   :options '(:bg :fg :width :margin :border)
   :before (lambda (n e)
	     (let ((bg (markup-option n :bg))
		   (fg (markup-option n :fg))
		   (w  (markup-option n :width))
		   (m  (markup-option n :margin))
		   (b  (markup-option n :border))
		   (c  (markup-option n :round-corner)))
	       (if (or bg w m b)
		   (begin
		     (printf "\\startframedtext[width=~a" (if w
							      (context-width w)
							      "fit"))
		     (printf ",rulethickness=~A" (if b (context-width b) "0pt"))
		     (when m
		       (printf ",offset=~A" (context-width m)))
		     (when bg
		       (printf ",background=color,backgroundcolor=~A"
			       (skribe-get-color bg)))
		     (when fg
		       (printf ",foregroundcolor=~A"
			       (skribe-get-color fg)))
		     (when c
		       (display ",framecorner=round"))
		     (printf "]\n"))
		   ;; Probably just a foreground was specified
		   (when fg
		     (printf "\\startcolor[~A] " (skribe-get-color fg))))))
   :after (lambda (n e)
	    (let ((bg (markup-option n :bg))
		   (fg (markup-option n :fg))
		   (w  (markup-option n :width))
		   (m  (markup-option n :margin))
		   (b  (markup-option n :border)))
	      (if (or bg w m b)
		(printf "\\stopframedtext ")
		(when fg
		  (printf "\\stopcolor "))))))
;;;; ======================================================================
;;;;	frame ...
;;;; ======================================================================
(markup-writer 'frame
   :options '(:width :border :margin)
   :before (lambda (n e)
	     (let ((m (markup-option n :margin))
		   (w (markup-option n :width))
		   (b (markup-option n :border))
		   (c (markup-option n :round-corner)))
	       (printf "\\startframedtext[width=~a" (if w
							(context-width w)
							"fit"))
	       (printf ",rulethickness=~A" (context-dim b))
	       (printf ",offset=~A" (context-width m))
	       (when c
		 (display ",framecorner=round"))
	       (printf "]\n")))
   :after "\\stopframedtext ")

;;;; ======================================================================
;;;;	font ...
;;;; ======================================================================
(markup-writer 'font
   :options '(:size)
   :action (lambda (n e)
	     (let* ((size (markup-option n :size))
		    (cs   (engine-custom e 'font-size))
		    (ns   (cond
			    ((and (integer? size) (exact? size))
			     (if (> size 0)
				 size
				 (+ cs size)))
			    ((and (number? size) (inexact? size))
			     (+ cs (inexact->exact size)))
			    ((string? size)
			     (let ((nb (string->number size)))
			       (if (not (number? nb))
				   (skribe-error
				    'font
				    (format #f "Illegal font size ~s" size)
				    nb)
				   (+ cs nb))))))
		     (ne (make-engine (gensym 'context)
				      :delegate e
				      :filter (engine-filter e)
				      :symbol-table (engine-symbol-table e)
				      :custom `((font-size ,ns)
						,@(engine-customs e)))))
	       (printf "{\\switchtobodyfont[~apt]" ns)
	       (output (markup-body n) ne)
	       (display "}"))))


;;;; ======================================================================
;;;;    flush ...
;;;; ======================================================================
(markup-writer 'flush
   :options '(:side)
   :before (lambda (n e)
	     (case (markup-option n :side)
		 ((center)
		  (display "\n\n\\midaligned{"))
		 ((left)
		  (display "\n\n\\leftaligned{"))
		 ((right)
		  (display "\n\n\\rightaligned{"))))
   :after "}\n")

;*---------------------------------------------------------------------*/
;*    center ...                                                       */
;*---------------------------------------------------------------------*/
(markup-writer 'center
   :before "\n\n\\midaligned{"
   :after "}\n")

;;;; ======================================================================
;;;;   pre ...
;;;; ======================================================================
(markup-writer 'pre
   :before "{\\tt\n\\startlines\n\\fixedspaces\n"
   :action (lambda (n e)
	     (let ((ne (make-engine
			  (gensym 'context)
			  :delegate e
			  :filter (make-string-replace context-pre-encoding)
			  :symbol-table (engine-symbol-table e)
			  :custom (engine-customs e))))
	       (output (markup-body n) ne)))
   :after  "\n\\stoplines\n}")

;;;; ======================================================================
;;;;	prog ...
;;;; ======================================================================
(markup-writer 'prog
   :options '(:line :mark)
   :before "{\\tt\n\\startlines\n\\fixedspaces\n"
   :action (lambda (n e)
	     (let ((ne (make-engine
			  (gensym 'context)
			  :delegate e
			  :filter (make-string-replace context-pre-encoding)
			  :symbol-table (engine-symbol-table e)
			  :custom (engine-customs e))))
	       (output (markup-body n) ne)))
   :after  "\n\\stoplines\n}")


;;;; ======================================================================
;;;;    itemize, enumerate ...
;;;; ======================================================================
(define (context-itemization-action n e descr?)
  (let ((symbol (markup-option n :symbol)))
    (for-each (lambda (item)
		(if symbol
		    (begin
		      (display "\\sym{")
		      (output symbol e)
		      (display "}"))
		    ;; output a \item iff not a description
		    (unless descr?
		      (display "  \\item ")))
		(output item e)
		(newline))
	      (markup-body n))))

(markup-writer 'itemize
   :options '(:symbol)
   :before "\\startnarrower[left]\n\\startitemize[serried]\n"
   :action (lambda (n e) (context-itemization-action n e #f))
   :after "\\stopitemize\n\\stopnarrower\n")


(markup-writer 'enumerate
   :options '(:symbol)
   :before "\\startnarrower[left]\n\\startitemize[n][standard]\n"
   :action (lambda (n e) (context-itemization-action n e #f))
   :after "\\stopitemize\n\\stopnarrower\n")

;;;; ======================================================================
;;;;    description ...
;;;; ======================================================================
(markup-writer 'description
   :options '(:symbol)
   :before "\\startnarrower[left]\n\\startitemize[serried]\n"
   :action (lambda (n e) (context-itemization-action n e #t))
   :after "\\stopitemize\n\\stopnarrower\n")

;;;; ======================================================================
;;;;    item ...
;;;; ======================================================================
(markup-writer 'item
   :options '(:key)
   :action (lambda (n e)
	     (let ((k (markup-option n :key)))
	       (when k
		 ;; Output the key(s)
		 (let Loop ((l (if (pair? k) k (list k))))
		   (unless (null? l)
		     (output (bold (car l)) e)
		     (unless (null? (cdr l))
		       (display "\\crlf\n"))
		     (Loop (cdr l))))
		 (display "\\nowhitespace\\startnarrower[left]\n"))
	       ;; Output body
	       (output (markup-body n) e)
	       ;; Terminate
	       (when k
		 (display "\n\\stopnarrower\n")))))

;;;; ======================================================================
;;;;	blockquote ...
;;;; ======================================================================
(markup-writer 'blockquote
   :before "\n\\startnarrower[left,right]\n"
   :after  "\n\\stopnarrower\n")


;;;; ======================================================================
;;;;	figure ...
;;;; ======================================================================
(markup-writer 'figure
   :options '(:legend :number :multicolumns)
   :action (lambda (n e)
	     (let ((ident (markup-ident n))
		   (number (markup-option n :number))
		   (legend (markup-option n :legend)))
	       (unless number
		 (display "{\\setupcaptions[number=off]\n"))
	       (display "\\placefigure\n")
	       (printf "  [~a]\n" (string-canonicalize ident))
	       (display "  {") (output legend e) (display "}\n")
	       (display "  {") (output (markup-body n) e) (display "}")
	       (unless number
		 (display "}\n")))))

;;;; ======================================================================
;;;;    table ...
;;;; ======================================================================
						;; width doesn't work
(markup-writer 'table
   :options '(:width :border :frame :rules :cellpadding)
   :before (lambda (n e)
	     (let ((width  (markup-option n :width))
		   (border (markup-option n :border))
		   (frame  (markup-option n :frame))
		   (rules  (markup-option n :rules))
		   (cstyle (markup-option n :cellstyle))
		   (cp     (markup-option n :cellpadding))
		   (cs     (markup-option n :cellspacing)))
	       (printf "\n{\\bTABLE\n")
	       (printf "\\setupTABLE[")
	       (printf "width=~A" (if width (context-width width) "fit"))
	       (when border
		 (printf ",rulethickness=~A" (context-dim border)))
	       (when cp
		 (printf ",offset=~A" (context-width cp)))
	       (printf ",frame=off]\n")

	       (when rules
		 (let ((hor  "\\setupTABLE[row][bottomframe=on,topframe=on]\n")
		       (vert "\\setupTABLE[c][leftframe=on,rightframe=on]\n"))
		   (case rules
		     ((rows) (display hor))
		     ((cols) (display vert))
		     ((all)  (display hor) (display vert)))))

	       (when frame
		 ;;  hsides, vsides, lhs, rhs, box, border
		 (let ((top   "\\setupTABLE[row][first][frame=off,topframe=on]\n")
		       (bot   "\\setupTABLE[row][last][frame=off,bottomframe=on]\n")
		       (left  "\\setupTABLE[c][first][frame=off,leftframe=on]\n")
		       (right "\\setupTABLE[c][last][frame=off,rightframe=on]\n"))
		 (case frame
		   ((above)      (display top))
		   ((below)      (display bot))
		   ((hsides)     (display top) (display bot))
		   ((lhs)        (display left))
		   ((rhs)        (display right))
		   ((vsides)     (display left) (diplay right))
		   ((box border) (display top)  (display bot)
				 (display left) (display right)))))))

   :after  (lambda (n e)
	     (printf "\\eTABLE}\n")))


;;;; ======================================================================
;;;;    tr ...
;;;; ======================================================================
(markup-writer 'tr
   :options '(:bg)
   :before (lambda (n e)
	     (display "\\bTR")
	     (let ((bg (markup-option n :bg)))
	       (when bg
		 (printf "[background=color,backgroundcolor=~A]"
			 (skribe-get-color bg)))))
   :after  "\\eTR\n")


;;;; ======================================================================
;;;;    tc ...
;;;; ======================================================================
(markup-writer 'tc
   :options '(:width :align :valign :colspan)
   :before (lambda (n e)
	     (let ((th?     (eq? 'th (markup-option n 'markup)))
		   (width   (markup-option n :width))
		   (align   (markup-option n :align))
		   (valign  (markup-option n :valign))
		   (colspan (markup-option n :colspan))
		   (rowspan (markup-option n :rowspan))
		   (bg      (markup-option n :bg)))
	       (printf "\\bTD[")
	       (printf "width=~a" (if width (context-width width) "fit"))
	       (when valign
		 ;; This is buggy. In fact valign an align can't be both
		 ;; specified in ConTeXt
		 (printf ",align=~a" (case valign
				       ((center) 'lohi)
				       ((bottom) 'low)
				       ((top)    'high))))
	       (when align
		 (printf ",align=~a" (case align
				       ((left) 'right) ; !!!!
				       ((right) 'left) ; !!!!
				       (else    'middle))))
	       (unless (equal? colspan 1)
		 (printf ",nx=~a" colspan))
	       (display "]")
	       (when th?
		 ;; This is a TH, output is bolded
		 (display "{\\bf{"))))

   :after (lambda (n e)
	     (when (equal? (markup-option n 'markup) 'th)
	       ;; This is a TH, output is bolded
	       (display "}}"))
	     (display "\\eTD")))

;;;; ======================================================================
;;;;	image ...
;;;; ======================================================================
(markup-writer 'image
   :options '(:file :url :width :height :zoom)
   :action (lambda (n e)
	     (let* ((file   (markup-option n :file))
		    (url    (markup-option n :url))
		    (width  (markup-option n :width))
		    (height (markup-option n :height))
		    (zoom   (markup-option n :zoom))
		    (body   (markup-body n))
		    (efmt   (engine-custom e 'image-format))
		    (img    (or url (convert-image file
						   (if (list? efmt)
						       efmt
						       '("jpg"))))))
	       (if (not (string? img))
		   (skribe-error 'context "Illegal image" file)
		   (begin
		     (printf "\\externalfigure[~A][frame=off" (strip-ref-base img))
		     (if zoom   (printf ",factor=~a"   (inexact->exact zoom)))
		     (if width  (printf ",width=~a"    (context-width width)))
		     (if height (printf ",height=~apt" (context-dim height)))
		     (display "]"))))))


;;;; ======================================================================
;;;;   Ornaments ...
;;;; ======================================================================
(markup-writer 'roman :before "{\\rm{" :after "}}")
(markup-writer 'bold :before "{\\bf{" :after "}}")
(markup-writer 'underline :before  "{\\underbar{" :after "}}")
(markup-writer 'emph :before "{\\em{" :after "}}")
(markup-writer 'it :before "{\\it{" :after "}}")
(markup-writer 'code :before "{\\tt{" :after "}}")
(markup-writer 'var :before "{\\tt{" :after "}}")
(markup-writer 'sc :before "{\\sc{" :after "}}")
;;//(markup-writer 'sf :before "{\\sf{" :after "}}")
(markup-writer 'sub :before "{\\low{" :after "}}")
(markup-writer 'sup :before "{\\high{" :after "}}")


;;//
;;//(markup-writer 'tt
;;//   :before "{\\texttt{"
;;//   :action (lambda (n e)
;;//	      (let ((ne (make-engine
;;//			   (gensym 'latex)
;;//			   :delegate e
;;//			   :filter (make-string-replace latex-tt-encoding)
;;//			   :custom (engine-customs e)
;;//			   :symbol-table (engine-symbol-table e))))
;;//		 (output (markup-body n) ne)))
;;//   :after "}}")

;;;; ======================================================================
;;;;    q ...
;;;; ======================================================================
(markup-writer 'q
   :before "\\quotation{"
   :after "}")

;;;; ======================================================================
;;;;    mailto ...
;;;; ======================================================================
(markup-writer 'mailto
   :options '(:text)
   :action (lambda (n e)
	     (let ((text (markup-option n :text))
		   (url  (markup-body n)))
	       (when (pair? url)
		 (context-url (format #f "mailto:~A" (car url))
			      (or text
				  (car url))
			      e)))))
;;;; ======================================================================
;;;;   mark ...
;;;; ======================================================================
(markup-writer 'mark
   :before (lambda (n e)
	      (printf "\\reference[~a]{}\n"
		      (string-canonicalize (markup-ident n)))))

;;;; ======================================================================
;;;;   ref ...
;;;; ======================================================================
(markup-writer 'ref
   :options '(:text :chapter :section :subsection :subsubsection
	      :figure :mark :handle :page)
   :action (lambda (n e)
	      (let* ((text (markup-option n :text))
		     (page (markup-option n :page))
		     (c    (handle-ast (markup-body n)))
		     (id   (markup-ident c)))
		(cond
		  (page ;; Output the page only (this is a hack)
		     (when text (output text e))
		     (printf "\\at[~a]"
			     (string-canonicalize id)))
		  ((or (markup-option n :chapter)
		       (markup-option n :section)
		       (markup-option n :subsection)
		       (markup-option n :subsubsection))
		   (if text
		       (printf "\\goto{~a}[~a]" (or text id)
			       (string-canonicalize id))
		       (printf "\\in[~a]" (string-canonicalize id))))
		  ((markup-option n :mark)
		     (printf "\\goto{~a}[~a]"
			     (or text id)
			     (string-canonicalize id)))
		  (else ;; Output a little image indicating the direction
		      (printf "\\in[~a]" (string-canonicalize id)))))))

;;;; ======================================================================
;;;;   bib-ref ...
;;;; ======================================================================
(markup-writer 'bib-ref
   :options '(:text :bib)
   :before (lambda (n e) (output "[" e))
   :action (lambda (n e)
	     (let* ((obj   (handle-ast (markup-body n)))
		    (title (markup-option obj :title))
		    (ref   (markup-option title 'number))
		    (ident (markup-ident obj)))
	       (printf "\\goto{~a}[~a]" ref (string-canonicalize ident))))
   :after (lambda (n e) (output "]" e)))

;;;; ======================================================================
;;;;   bib-ref+ ...
;;;; ======================================================================
(markup-writer 'bib-ref+
   :options '(:text :bib)
   :before (lambda (n e) (output "[" e))
   :action (lambda (n e)
	      (let loop ((rs (markup-body n)))
		 (cond
		    ((null? rs)
		     #f)
		    (else
		     (if (is-markup? (car rs) 'bib-ref)
			 (invoke (writer-action (markup-writer-get 'bib-ref e))
				 (car rs)
				 e)
			 (output (car rs) e))
		     (if (pair? (cdr rs))
			 (begin
			    (display ",")
			    (loop (cdr rs))))))))
   :after (lambda (n e) (output "]" e)))

;;;; ======================================================================
;;;;	url-ref ...
;;;; ======================================================================
(markup-writer 'url-ref
   :options '(:url :text)
   :action (lambda (n e)
	     (context-url (markup-option n :url) (markup-option n :text) e)))

;;//;*---------------------------------------------------------------------*/
;;//;*    line-ref ...                                                     */
;;//;*---------------------------------------------------------------------*/
;;//(markup-writer 'line-ref
;;//   :options '(:offset)
;;//   :before "{\\textit{"
;;//   :action (lambda (n e)
;;//	      (let ((o (markup-option n :offset))
;;//		    (v (string->number (markup-option n :text))))
;;//		 (cond
;;//		    ((and (number? o) (number? v))
;;//		     (display (+ o v)))
;;//		    (else
;;//		     (display v)))))
;;//   :after "}}")


;;;; ======================================================================
;;;;	&the-bibliography ...
;;;; ======================================================================
(markup-writer '&the-bibliography
   :before "\n% Bibliography\n\n")


;;;; ======================================================================
;;;;	&bib-entry ...
;;;; ======================================================================
(markup-writer '&bib-entry
   :options '(:title)
   :action (lambda (n e)
	     (skribe-eval (mark (markup-ident n)) e)
	     (output n e (markup-writer-get '&bib-entry-label e))
	     (output n e (markup-writer-get '&bib-entry-body e)))
   :after "\n\n")

;;;; ======================================================================
;;;;	&bib-entry-label ...
;;;; ======================================================================
(markup-writer '&bib-entry-label
   :options '(:title)
   :before (lambda (n e) (output "[" e))
   :action (lambda (n e) (output (markup-option n :title) e))
   :after  (lambda (n e) (output "] "e)))

;;;; ======================================================================
;;;;	&bib-entry-title ...
;;;; ======================================================================
(markup-writer '&bib-entry-title
   :action (lambda (n e)
	     (let* ((t  (bold (markup-body n)))
		    (en (handle-ast (ast-parent n)))
		    (url #f ) ;;;;;;;;;;;;;;;// (markup-option en 'url))
		    (ht (if url (ref :url (markup-body url) :text t) t)))
	       (skribe-eval ht e))))


;;//;*---------------------------------------------------------------------*/
;;//;*    &bib-entry-url ...                                               */
;;//;*---------------------------------------------------------------------*/
;;//(markup-writer '&bib-entry-url
;;//   :action (lambda (n e)
;;//	      (let* ((en (handle-ast (ast-parent n)))
;;//		     (url (markup-option en 'url))
;;//		     (t (bold (markup-body url))))
;;//		 (skribe-eval (ref :url (markup-body url) :text t) e))))


;;;; ======================================================================
;;;;	&the-index ...
;;;; ======================================================================
(markup-writer '&the-index
   :options '(:column)
   :action
   (lambda (n e)
     (define (make-mark-entry n)
       (display "\\blank[medium]\n{\\bf\\it\\tfc{")
       (skribe-eval (bold n) e)
       (display "}}\\crlf\n"))

     (define (make-primary-entry n)
       (let ((b (markup-body n)))
	 (markup-option-add! b :text (list (markup-option b :text) ", "))
	 (markup-option-add! b :page #t)
	 (output n e)))

     (define (make-secondary-entry n)
       (let* ((note (markup-option n :note))
	      (b    (markup-body n))
	      (bb   (markup-body b)))
	 (if note
	     (begin   ;; This is another entry
	       (display "\\crlf\n ... ")
	       (markup-option-add! b :text (list note ", ")))
	     (begin   ;; another line on an entry
	       (markup-option-add! b :text ", ")))
	 (markup-option-add! b :page #t)
	 (output n e)))

     ;; Writer body starts here
     (let ((col  (markup-option n :column)))
       (when col
	 (printf "\\startcolumns[n=~a]\n" col))
       (for-each (lambda (item)
		   ;;(DEBUG "ITEM= ~S" item)
		   (if (pair? item)
		       (begin
			 (make-primary-entry (car item))
			 (for-each (lambda (x) (make-secondary-entry x))
				   (cdr item)))
		       (make-mark-entry item))
		   (display "\\crlf\n"))
		 (markup-body n))
       (when col
	 (printf "\\stopcolumns\n")))))

;;;; ======================================================================
;;;;    &source-comment ...
;;;; ======================================================================
(markup-writer '&source-comment
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-comment-color))
		     (n1 (it (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-line-comment ...
;;;; ======================================================================
(markup-writer '&source-line-comment
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-comment-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-keyword ...
;;;; ======================================================================
(markup-writer '&source-keyword
   :action (lambda (n e)
	      (skribe-eval (it (markup-body n)) e)))

;;;; ======================================================================
;;;;    &source-error ...
;;;; ======================================================================
(markup-writer '&source-error
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-error-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'error-color) cc)
			     (color :fg cc (it n1))
			     (it n1))))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-define ...
;;;; ======================================================================
(markup-writer '&source-define
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-define-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-module ...
;;;; ======================================================================
(markup-writer '&source-module
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-module-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-markup ...
;;;; ======================================================================
(markup-writer '&source-markup
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-markup-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-thread ...
;;;; ======================================================================
(markup-writer '&source-thread
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-thread-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-string ...
;;;; ======================================================================
(markup-writer '&source-string
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-string-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-bracket ...
;;;; ======================================================================
(markup-writer '&source-bracket
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-bracket-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc (bold n1))
			     (it n1))))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-type ...
;;;; ======================================================================
(markup-writer '&source-type
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-type-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     (it n1))))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-key ...
;;;; ======================================================================
(markup-writer '&source-key
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-type-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc (bold n1))
			     (it n1))))
		 (skribe-eval n2 e))))

;;;; ======================================================================
;;;;    &source-type ...
;;;; ======================================================================
(markup-writer '&source-type
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-type-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg "red" (bold n1))
			     (bold n1))))
		 (skribe-eval n2 e))))



;;;; ======================================================================
;;;;	Context Only Markups
;;;; ======================================================================

;;;
;;; Margin -- put text in the margin
;;;
(define-markup (margin #!rest opts #!key (ident #f) (class "margin")
			(side 'right) text)
  (new markup
       (markup 'margin)
       (ident (or ident (symbol->string (gensym 'ident))))
       (class class)
       (required-options '(:text))
       (options (the-options opts :ident :class))
       (body (the-body opts))))

(markup-writer 'margin
   :options '(:text)
   :before (lambda (n e)
	     (display
	      "\\setupinmargin[align=right,style=\\tfx\\setupinterlinespace]\n")
	     (display "\\inright{")
	     (output (markup-option n :text) e)
	     (display "}{"))
   :after  "}")

;;;
;;; ConTeXt and TeX
;;;
(define-markup (ConTeXt #!key (space #t))
  (if (engine-format? "context")
      (! (if space "\\CONTEXT\\ " "\\CONTEXT"))
      "ConTeXt"))

(define-markup (TeX #!key (space #t))
  (if (engine-format? "context")
      (! (if space "\\TEX\\ " "\\TEX"))
      "ConTeXt"))

;;;; ======================================================================
;;;;    Restore the base engine
;;;; ======================================================================
(default-engine-set! (find-engine 'base))
