;;; lout.scm  --  A Lout engine.
;;; -*- coding: iso-8859-1 -*-
;;;
;;; Copyright 2004, 2005, 2006, 2007, 2008, 2009, 2010,
;;;  2012  Ludovic Court�s <ludo@gnu.org>
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

(define-module (skribilo engine lout)
  :use-module (skribilo lib)
  :use-module (skribilo ast)
  :use-module (skribilo config)
  :use-module (skribilo engine)
  :use-module (skribilo writer)
  :use-module (skribilo condition)
  :use-module (skribilo utils keywords)
  :use-module (skribilo utils strings)
  :use-module (skribilo utils syntax)
  :use-module (skribilo package base)
  :autoload   (skribilo utils images)  (convert-image)
  :autoload   (skribilo evaluator)     (evaluate-document)
  :autoload   (skribilo output)        (output)
  :autoload   (skribilo color)         (color->rgb)
  :use-module (srfi srfi-1)
  :use-module (srfi srfi-2)
  :use-module (srfi srfi-11)
  :use-module (srfi srfi-13)
  :use-module (srfi srfi-14)
  :autoload   (srfi srfi-34)  (raise)
  :use-module (srfi srfi-35)
  :autoload   (ice-9 popen)   (open-output-pipe)
  :autoload   (ice-9 rdelim)  (read-line)

  :export (lout-engine
           lout-illustration !lout

           lout-verbatim-encoding lout-encoding
           lout-french-encoding
           lout-tagify lout-embedded-postscript-code
           lout-color-specification lout-make-url-breakable
           lout-output-pdf-meta-info))

;;;    Taken from `lcourtes@laas.fr--2004-libre',
;;;               `skribe-lout--main--0.2--patch-15'.
;;;    Based on `latex.skr', copyright 2003, 2004 Manuel Serrano.
;;;
;;;    For more information on Lout, see http://lout.sf.net/ .

(skribilo-module-syntax)



;*---------------------------------------------------------------------*/
;*    lout-verbatim-encoding ...                                       */
;*---------------------------------------------------------------------*/
(define lout-verbatim-encoding
   '((#\/ "\"/\"")
     (#\\ "\"\\\\\"")
     (#\| "\"|\"")
     (#\& "\"&\"")
     (#\@ "\"@\"")
     (#\" "\"\\\"\"")
     (#\{ "\"{\"")
     (#\} "\"}\"")
     (#\$ "\"$\"")
     (#\# "\"#\"")
     (#\_ "\"_\"")
     (#\~ "\"~\"")))

;*---------------------------------------------------------------------*/
;*    lout-encoding ...                                                */
;*---------------------------------------------------------------------*/
(define lout-encoding
  `(,@lout-verbatim-encoding
    (#\� "{ @Char ccedilla }")
    (#\� "{ @Char Ccdeilla }")
    (#\� "{ @Char acircumflex }")
    (#\� "{ @Char Acircumflex }")
    (#\� "{ @Char agrave }")
    (#\� "{ @Char Agrave }")
    (#\� "{ @Char eacute }")
    (#\� "{ @Char Eacute }")
    (#\� "{ @Char egrave }")
    (#\� "{ @Char Egrave }")
    (#\� "{ @Char ecircumflex }")
    (#\� "{ @Char Ecircumflex }")
    (#\� "{ @Char ugrave }")
    (#\� "{ @Char Ugrave }")
    (#\� "{ @Char ucircumflex }")
    (#\� "{ @Char Ucircumflex }")
    (#\� "{ @Char oslash }")
    (#\� "{ @Char ocircumflex }")
    (#\� "{ @Char Ocircumflex }")
    (#\� "{ @Char odieresis }")
    (#\� "{ @Char Odieresis }")
    (#\� "{ @Char icircumflex }")
    (#\� "{ @Char Icircumflex }")
    (#\� "{ @Char idieresis }")
    (#\� "{ @Char Idieresis }")
    (#\] "\"]\"")
    (#\[ "\"[\"")
    (#\� "{ @Char guillemotright }")
    (#\� "{ @Char guillemotleft }")))


;; XXX:  This is just here for experimental purposes.
(define lout-french-punctuation-encoding
  (let ((space (lambda (before after thing)
		 (string-append "{ "
				(if before
				    (string-append "{ " before " @Wide {} }")
				    "")
				"\"" thing "\""
				(if after
				    (string-append "{ " after " @Wide {} }")
				    "")
				" }"))))
    `((#\; ,(space "0.5s" #f ";"))
      (#\? ,(space "0.5s" #f ";"))
      (#\! ,(space "0.5s" #f ";")))))

(define lout-french-encoding
  (let ((punctuation (map car lout-french-punctuation-encoding)))
    (append (let loop ((ch lout-encoding)
		       (purified '()))
	      (if (null? ch)
		  purified
		  (loop (cdr ch)
			(if (member (car ch) punctuation)
			    purified
			    (cons (car ch) purified)))))
	    lout-french-punctuation-encoding)))

;*---------------------------------------------------------------------*/
;*    lout-symbol-table ...                                            */
;*---------------------------------------------------------------------*/
(define (lout-symbol-table sym math)
   `(("iexcl" "{ @Char exclamdown }")
     ("cent" "{ @Char cent }")
     ("pound" "{ @Char sterling }")
     ("yen" "{ @Char yen }")
     ("section" "{ @Char section }")
     ("mul" "{ @Char multiply }")
     ("copyright" "{ @Char copyright }")
     ("lguillemet" "{ @Char guillemotleft }")
     ("not" "{ @Char logicalnot }")
     ("degree" "{ @Char degree }")
     ("plusminus" "{ @Char plusminus }")
     ("micro" "{ @Char mu }")
     ("paragraph" "{ @Char paragraph }")
     ("middot" "{ @Char periodcentered }")
     ("rguillemet" "{ @Char guillemotright }")
     ("1/4" "{ @Char onequarter }")
     ("1/2" "{ @Char onehalf }")
     ("3/4" "{ @Char threequarters }")
     ("iquestion" "{ @Char questiondown }")
     ("Agrave" "{ @Char Agrave }")
     ("Aacute" "{ @Char Aacute }")
     ("Acircumflex" "{ @Char Acircumflex }")
     ("Atilde" "{ @Char Atilde }")
     ("Amul" "{ @Char Adieresis }") ;;; FIXME:  Why `mul' and not `uml'?!
     ("Aring" "{ @Char Aring }")
     ("AEligature" "{ @Char oe }")
     ("Oeligature" "{ @Char OE }")  ;;; FIXME:  Should be `OEligature'?!
     ("Ccedilla" "{ @Char Ccedilla }")
     ("Egrave" "{ @Char Egrave }")
     ("Eacute" "{ @Char Eacute }")
     ("Ecircumflex" "{ @Char Ecircumflex }")
     ("Euml" "{ @Char Edieresis }")
     ("Igrave" "{ @Char Igrave }")
     ("Iacute" "{ @Char Iacute }")
     ("Icircumflex" "{ @Char Icircumflex }")
     ("Iuml" "{ @Char Idieresis }")
     ("ETH" "{ @Char Eth }")
     ("Ntilde" "{ @Char Ntilde }")
     ("Ograve" "{ @Char Ograve }")
     ("Oacute" "{ @Char Oacute }")
     ("Ocircumflex" "{ @Char Ocircumflex }")
     ("Otilde" "{ @Char Otilde }")
     ("Ouml" "{ @Char Odieresis }")
     ("times" ,(sym "multiply"))
     ("Oslash" "{ @Char oslash }")
     ("Ugrave" "{ @Char Ugrave }")
     ("Uacute" "{ @Char Uacute }")
     ("Ucircumflex" "{ @Char Ucircumflex }")
     ("Uuml" "{ @Char Udieresis }")
     ("Yacute" "{ @Char Yacute }")
     ("szlig" "{ @Char germandbls }")
     ("agrave" "{ @Char agrave }")
     ("aacute" "{ @Char aacute }")
     ("acircumflex" "{ @Char acircumflex }")
     ("atilde" "{ @Char atilde }")
     ("amul" "{ @Char adieresis }")
     ("aring" "{ @Char aring }")
     ("aeligature" "{ @Char ae }")
     ("oeligature" "{ @Char oe }")
     ("ccedilla" "{ @Char ccedilla }")
     ("egrave" "{ @Char egrave }")
     ("eacute" "{ @Char eacute }")
     ("ecircumflex" "{ @Char ecircumflex }")
     ("euml" "{ @Char edieresis }")
     ("igrave" "{ @Char igrave }")
     ("iacute" "{ @Char iacute }")
     ("icircumflex" "{ @Char icircumflex }")
     ("iuml" "{ @Char idieresis }")
     ("ntilde" "{ @Char ntilde }")
     ("ograve" "{ @Char ograve }")
     ("oacute" "{ @Char oacute }")
     ("ocurcumflex" "{ @Char ocircumflex }") ;; FIXME: `ocIrcumflex'
     ("otilde" "{ @Char otilde }")
     ("ouml" "{ @Char odieresis }")
     ("divide" "{ @Char divide }")
     ("oslash" "{ @Char oslash }")
     ("ugrave" "{ @Char ugrave }")
     ("uacute" "{ @Char uacute }")
     ("ucircumflex" "{ @Char ucircumflex }")
     ("uuml" "{ @Char udieresis }")
     ("yacute" "{ @Char yacute }")
     ("ymul" "{ @Char ydieresis }")  ;; FIXME: `yUMl'
     ;; Greek
     ("Alpha" ,(sym "Alpha"))
     ("Beta" ,(sym "Beta"))
     ("Gamma" ,(sym "Gamma"))
     ("Delta" ,(sym "Delta"))
     ("Epsilon" ,(sym "Epsilon"))
     ("Zeta" ,(sym "Zeta"))
     ("Eta" ,(sym "Eta"))
     ("Theta" ,(sym "Theta"))
     ("Iota" ,(sym "Iota"))
     ("Kappa" ,(sym "Kappa"))
     ("Lambda" ,(sym "Lambda"))
     ("Mu" ,(sym "Mu"))
     ("Nu" ,(sym "Nu"))
     ("Xi" ,(sym "Xi"))
     ("Omicron" ,(sym "Omicron"))
     ("Pi" ,(sym "Pi"))
     ("Rho" ,(sym "Rho"))
     ("Sigma" ,(sym "Sigma"))
     ("Tau" ,(sym "Tau"))
     ("Upsilon" ,(sym "Upsilon"))
     ("Phi" ,(sym "Phi"))
     ("Chi" ,(sym "Chi"))
     ("Psi" ,(sym "Psi"))
     ("Omega" ,(sym "Omega"))
     ("alpha" ,(sym "alpha"))
     ("beta" ,(sym "beta"))
     ("gamma" ,(sym "gamma"))
     ("delta" ,(sym "delta"))
     ("epsilon" ,(sym "epsilon"))
     ("zeta" ,(sym "zeta"))
     ("eta" ,(sym "eta"))
     ("theta" ,(sym "theta"))
     ("iota" ,(sym "iota"))
     ("kappa" ,(sym "kappa"))
     ("lambda" ,(sym "lambda"))
     ("mu" ,(sym "mu"))
     ("nu" ,(sym "nu"))
     ("xi" ,(sym "xi"))
     ("omicron" ,(sym "omicron"))
     ("pi" ,(sym "pi"))
     ("rho" ,(sym "rho"))
     ("sigmaf" ,(sym "sigmaf")) ;; FIXME!
     ("sigma" ,(sym "sigma"))
     ("tau" ,(sym "tau"))
     ("upsilon" ,(sym "upsilon"))
     ("phi" ,(sym "phi"))
     ("chi" ,(sym "chi"))
     ("psi" ,(sym "psi"))
     ("omega" ,(sym "omega"))
     ("thetasym" ,(sym "thetasym"))
     ("piv" ,(sym "piv")) ;; FIXME!
     ;; punctuation
     ("bullet" ,(sym "bullet"))
     ("ellipsis" ,(sym "ellipsis"))
     ("weierp" "{ @Sym  weierstrass }")
     ("image" ,(sym "Ifraktur"))
     ("real" ,(sym "Rfraktur"))
     ("tm" ,(sym "trademarksans")) ;; alt: @Sym trademarkserif
     ("alef" ,(sym "aleph"))
     ("<-" ,(sym "arrowleft"))
     ("<--" "{ { 1.6 1 } @Scale { @Sym arrowleft } }") ;; copied from `eqf'
     ("uparrow" ,(sym "arrowup"))
     ("->" ,(sym "arrowright"))
     ("-->" "{ { 1.6 1 } @Scale { @Sym arrowright } }")
     ("downarrow" ,(sym "arrowdown"))
     ("<->" ,(sym "arrowboth"))
     ("<-->" "{ { 1.6 1 } @Scale { @Sym arrowboth } }")
     ("<+" ,(sym "carriagereturn"))
     ("<=" ,(sym "arrowdblleft"))
     ("<==" "{ { 1.6 1 } @Scale { @Sym arrowdblleft } }")
     ("Uparrow" ,(sym "arrowdblup"))
     ("=>" ,(sym "arrowdblright"))
     ("==>" "{ { 1.6 1 } @Scale { @Sym arrowdblright } }")
     ("Downarrow" ,(sym "arrowdbldown"))
     ("<=>" ,(sym "arrowdblboth"))
     ("<==>" "{ { 1.6 1 } @Scale { @Sym arrowdblboth } }")
     ;; Mathematical operators (we try to avoid `@M' since it
     ;; requires to `@SysInclude { math }' -- one solution consists in copying
     ;; the symbol definition from `mathf')
     ("forall" "{ { Symbol Base } @Font \"\\042\" }")
     ("partial" ,(sym "partialdiff"))
     ("exists" "{ { Symbol Base } @Font \"\\044\" }")
     ("emptyset" "{ { Symbol Base } @Font \"\\306\" }")
     ("infinity" ,(sym "infinity"))
     ("nabla" "{ { Symbol Base } @Font \"\\321\" }")
     ("in" ,(sym "element"))
     ("notin" ,(sym "notelement"))
     ("ni" "{ 180d @Rotate @Sym element }")
     ("prod" ,(sym "product"))
     ("sum" ,(sym "summation"))
     ("asterisk" ,(sym "asteriskmath"))
     ("sqrt" ,(sym "radical"))
     ("propto" ,(math "propto"))
     ("angle" ,(sym "angle"))
     ("and" ,(math "bwedge"))
     ("or" ,(math "bvee"))
     ("cap" ,(math "bcap"))
     ("cup" ,(math "bcup"))
     ("integral" ,(math "int"))
     ("models" ,(math "models"))
     ("vdash" ,(math "vdash"))
     ("dashv" ,(math "dashv"))
     ("sim" ,(sym "similar"))
     ("cong" ,(sym "congruent"))
     ("approx" ,(sym "approxequal"))
     ("neq" ,(sym "notequal"))
     ("equiv" ,(sym "equivalence"))
     ("le" ,(sym "lessequal"))
     ("ge" ,(sym "greaterequal"))
     ("subset" ,(sym "propersubset"))
     ("supset" ,(sym "propersuperset"))
     ("subseteq" ,(sym "reflexsubset"))
     ("supseteq" ,(sym "reflexsuperset"))
     ("oplus" ,(sym "circleplus"))
     ("otimes" ,(sym "circlemultiply"))
     ("perp" ,(sym "perpendicular"))
     ("mid" ,(sym "bar"))
     ("lceil" ,(sym "bracketlefttp"))
     ("rceil" ,(sym "bracketrighttp"))
     ("lfloor" ,(sym "bracketleftbt"))
     ("rfloor" ,(sym "bracketrightbt"))
     ("langle" ,(sym "angleleft"))
     ("rangle" ,(sym "angleright"))
     ;; Misc
     ("loz" "{ @Lozenge }")
     ("spades" ,(sym "spade"))
     ("clubs" ,(sym "club"))
     ("hearts" ,(sym "heart"))
     ("diams" ,(sym "diamond"))
     ("euro" "{ @Euro }")
     ;; Lout
     ("dag" "{ @Dagger }")
     ("ddag" "{ @DaggerDbl }")
     ("circ" ,(math "circle"))
     ("top" ,(math "top"))
     ("bottom" ,(math "bot"))
     ("lhd" ,(math "triangleleft"))
     ("rhd" ,(math "triangleright"))
     ("parallel" ,(math "dbar"))))


;;; Debugging support

(define *lout-debug?* #f)

(define-macro (lout-debug fmt . args)
  `(and *lout-debug?*
        (format (current-error-port) (string-append ,fmt "~%") ,@args)))

(define (lout-tagify ident)
  ;; Return an "clean" identifier (a string) based on `ident' (a string),
  ;; suitable for Lout as an `@Tag' value.
  (let ((tag-encoding '((#\, "-")
			(#\( "-")
			(#\) "-")
			(#\[ "-")
			(#\] "-")
			(#\/ "-")
			(#\| "-")
			(#\& "-")
			(#\@ "-")
			(#\! "-")
			(#\? "-")
			(#\: "-")
			(#\; "-")))
	(tag (string-canonicalize ident)))
    ((make-string-replace tag-encoding) tag)))


;; Default values of various customs (procedures)

(define (lout-definitions engine)
  ;; Return a string containing a set of useful Lout definitions that should
  ;; be inserted at the beginning of the output document.
  (let ((leader (engine-custom engine 'toc-leader))
	(leader-space (engine-custom engine 'toc-leader-space)))
    (string-concatenate
	   `("# @SkribiloMark implements Skribe's marks "
	     "(i.e. cross-references)\n"
	     "def @SkribiloMark\n"
	     "    right @Tag\n"
	     "{\n"
	     "    @PageMark @Tag\n"
	     "}\n\n"

	     "# @SkribiloLeaders is used in `toc'\n"
	     "# (this is mostly copied from the expert's guide)\n"
	     "def @SkribiloLeaders { "
	     ,leader " |" ,leader-space " @SkribiloLeaders }\n\n"

             "# Embedding an application in PDF (``Launch'' actions)\n"
             "# (tested with XPdf 3.1 and Evince 0.4.0)\n"
             "def @SkribiloEmbed\n"
             "  left command\n"
             "  import @PSLengths\n"
             "    named borderwidth { 1p }\n"
             "  right body\n"
             "{\n"
             "  {\n"
             "    \"[ /Rect [0 0 xsize ysize]\"\n"
             "    \"  /Color [0 0 1]\"\n"
             "    \"  /Border [ 0 0 \" borderwidth \" ]\"\n"
             "    \"  /Action /Launch\"\n"
             "    \"  /File  (\" command \")\"\n"
             "    \"  /Subtype /Link\"\n"
             "    \"/ANN\"\n"
             "    \"pdfmark\"\n"
             "  }\n"
             "  @Graphic body\n"
             "}\n\n"))))


(define (lout-make-doc-cover-sheet doc engine)
  ;; Create a cover sheet for node `doc' which is a doc-style Lout document.
  ;; This is the default implementation, i.e. the default value of the
  ;; `doc-cover-sheet-proc' custom.
  (let ((title (markup-option doc :title))
	(author (markup-option doc :author))
	(date-line (engine-custom engine 'date-line))
	(multi-column? (> (engine-custom engine 'column-number) 1)))

    (if multi-column?
	;; In single-column document, `@FullWidth' yields a blank page.
	(display "\n@FullWidth {"))
    (display "\n//3.0fx\n")
    (display "\n@Center 1.4f @Font @B { cragged nohyphen 1.4fx } @Break { ")
    (if title
       (output title engine)
       (display "The Lout Document"))
    (display " }\n")
    (display "//2.0fx\n")
    (if author
       (begin
         (display "@Center { ")
         (output author engine)
         (display " }\n")
         (display "//4.6fx\n")))
    (if date-line
	(begin
	  (display "@Center { ")
	  (output (if (eq? #t date-line)
                      (strftime "%e %B %Y" (localtime (current-time)))
                      date-line)
                  engine)
	  (display " }\n//1.7fx\n")))
    (display "//0.5fx\n")
    (if multi-column?
	(display "\n} # @FullWidth\n"))))

(define (lout-split-external-link markup)
  ;; Shorten `markup', an URL `url-ref' markup, by splitting it into an URL
  ;; `ref' followed by plain text.  This is useful because Lout's
  ;; @ExternalLink symbols are unbreakable to the embodied text should _not_
  ;; be too large (otherwise it is scaled down).
  (let* ((url (markup-option markup :url))
	 (text (or (markup-option markup :text) url)))
    (lout-debug "lout-split-external-link: text=~a" text)
    (cond ((pair? text)
	   ;; no need to go recursive here: we'll get called again later
	   `(,(ref :url url :text (car text)) ,@(cdr text)))

	  ((string? text)
	   (let ((len (string-length text)))
	     (if (> (- len 8) 2)
		 ;; don't split on a whitespace or it will vanish
		 (let ((split (let loop ((where 10))
				(if (= 0 where)
				    10
				    (if (char-set-contains?
                                         char-set:whitespace
                                         (string-ref text (- where 1)))
					(loop (- where 1))
					where)))))
		   `(,(ref :url url :text (substring text 0 split))
		     ,(!lout (lout-make-url-breakable
                              (substring text split len)))))
		 (list markup))))

	  ((markup? text)
	   (let ((kind (markup-markup text)))
	     (lout-debug "lout-split-external-link: kind=~a" kind)
	     (if (member kind '(bold it underline))
		 ;; get the ornament markup out of the `:text' argument
		 (list (apply (eval kind (interaction-environment))
			      (list (ref :url url
					 :text (markup-body text)))))
 		 ;; otherwise, leave it as is
		 (list markup))))

	  (else (list markup)))))

(define (lout-make-toc-entry node engine)
  ;; Default implementation of the `toc-entry-proc' custom that produces the
  ;; number and title of `node' for use in the table of contents.
  (let ((num (markup-option node :number))
	(title (markup-option node :title)))
    (if num
	(begin
	  (if (is-markup? node 'chapter) (display "@B { "))
	  (format #t "~a. |2s " (markup-number-string node))
	  (output title engine)
	  (if (is-markup? node 'chapter) (display " }")))
	(if (is-markup? node 'chapter)
	    (output (bold title) engine)
	    (output title engine)))))

(define (lout-pdf-bookmark-title node engine)
  ;; Default implementation of the `pdf-bookmark-title-proc' custom that
  ;; returns a title (a string) for the PDF bookmark of `node'.
  (let ((number (markup-number-string node)))
    (string-append  (if (string=? number "") "" (string-append number ". "))
		    (ast->string (markup-option node :title)))))

(define (lout-pdf-bookmark-node? node engine)
  ;; Default implementation of the `pdf-bookmark-node-pred' custom that
  ;; returns a boolean.
  (or (is-markup? node 'chapter)
      (is-markup? node 'section)
      (is-markup? node 'subsection)
      (is-markup? node 'slide)
      (is-markup? node 'slide-topic)
      (is-markup? node 'slide-subtopic)))




;*---------------------------------------------------------------------*/
;*    lout-engine ...                                                  */
;*---------------------------------------------------------------------*/
(define lout-engine
  (make-engine 'lout
	       :version 0.2
	       :format "lout"
	       :delegate (find-engine 'base)
	       :filter (make-string-replace lout-encoding)
	       :custom `(;; The underlying Lout document type, i.e. one
			 ;; of `doc', `report', `book' or `slides'.
			 (document-type doc)

			 ;; Document style file include line (a string
			 ;; such as `@Include { doc-style.lout }') or
			 ;; `auto' (symbol) in which case the include
			 ;; file is deduced from `document-type'.
			 (document-include auto)

                         ;; Encoding of the output file.
                         (encoding "ISO-8859-1")

			 (includes "@SysInclude { tbl }\n")
			 (initial-font "Palatino Base 10p")
			 (initial-break
			  ,(string-append "unbreakablefirst "
					  "unbreakablelast "
					  "hyphen adjust 1.2fx"))

			 ;; The document's language, used for hyphenation
			 ;; and other things.
			 (initial-language "English")

			 ;; Number of columns.
			 (column-number 1)

			 ;; First page number.
			 (first-page-number 1)

			 ;; Page orientation, `portrait', `landscape',
			 ;; `reverse-portrait' or `reverse-landscape'.
			 (page-orientation portrait)

			 ;; For reports, whether to produce a cover
			 ;; sheet.  The `doc-cover-sheet-proc' custom may
			 ;; also honor this custom for `doc' documents.
			 (cover-sheet? #t)

			 ;; For reports and slides, the date line.
			 (date-line #t)

			 ;; For reports, an abstract.
			 (abstract #f)

			 ;; For reports, title/name of the abstract.  If
			 ;; `#f', the no abstract title will be
			 ;; produced.  If `#t', a default name in the
			 ;; current language is chosen.
			 (abstract-title #t)

                         ;; For books.
                         (publisher #f)
                         (edition #f)
                         (before-title-page #f)
                         (on-title-page #f)
                         (after-title-page #f)
                         (at-end #f)

			 ;; Whether to optimize pages.
			 (optimize-pages? #f)

			 ;; For docs, the procedure that produces the
			 ;; Lout code for the cover sheet or title.
			 (doc-cover-sheet-proc
			  ,lout-make-doc-cover-sheet)

                         ;; Kept for backward compability, do not use.
			 (bib-refs-sort-proc #f)

			 ;; Lout code for paragraph gaps (similar to
			 ;; `@PP' with `@ParaGap' equal to `1.0vx' by
			 ;; default)
			 (paragraph-gap
			  "\n//1.0vx @ParaIndent @Wide &{0i}\n")

                         ;; Gap for the first paragraph within a container
                         ;; (e.g., the first paragraph of a chapter).
                         (first-paragraph-gap "\n@LP\n")

                         ;; A boolean or predicate indicating whether drop
                         ;; capitals should be used at the beginning of
                         ;; paragraphs.
                         (drop-capital? #f)

                         ;; Number of lines over which drop capitals span.
                         ;; Only 2 and 3 are currently supported.
                         (drop-capital-lines 2)

			 ;; For multi-page tables, it may be
			 ;; useful to set this to `#t'.  However,
			 ;; this looks kind of buggy.
			 (use-header-rows? #f)

			 ;; Tells whether to use Lout's footnote numbering
			 ;; scheme or Skribilo's number (the former may be
			 ;; better, typography-wise).
			 (use-lout-footnote-numbers? #f)

			 ;; A procedure that is passed the engine
			 ;; and returns Lout definitions (a string).
			 (inline-definitions-proc ,lout-definitions)

			 ;; A procedure that takes a URL `ref' markup and
			 ;; returns a list containing (maybe) one such
			 ;; `ref' markup.  This custom can be used to
			 ;; modified the way URLs are rendered.  The
			 ;; default value is a procedure that limits the
			 ;; size of Lout's @ExternalLink symbols since
			 ;; they are unbreakable.  In order to completely
			 ;; disable use of @ExternalLinks, just set it to
			 ;; `markup-body'.
			 (transform-url-ref-proc
			  ,lout-split-external-link)

			 ;; Leader used in the table of contents entries.
			 (toc-leader ".")

			 ;; Inter-leader spacing in the TOC entries.
			 (toc-leader-space "2.5s")

			 ;; Procedure that takes a large-scale structure
			 ;; (chapter, section, etc.) and the engine and
			 ;; produces the number and possibly title of
			 ;; this structure for use the TOC.
			 (toc-entry-proc ,lout-make-toc-entry)

			 ;; The Lout program name, only useful when using
			 ;; `lout-illustration' on other back-ends.
			 (lout-program-name "lout")

                         ;; Additional arguments that should be passed to
                         ;; Lout, e.g., `("-I foo" "-I bar")'.
                         (lout-program-arguments ())

			 ;; Title and author information in the PDF
			 ;; document information.  If `#t', the
			 ;; document's `:title' and `:author' are used.
			 (pdf-title #t)
			 (pdf-author #t)

			 ;; Keywords (a list of string) in the PDF
			 ;; document information.  This custom is deprecated,
                         ;; use the `:keywords' option of `document' instead.
			 (pdf-keywords #f)

			 ;; Extra PDF information, an alist of key-value
			 ;; pairs (string pairs).
			 (pdf-extra-info (("SkribiloVersion"
					   ,(skribilo-version))))

			 ;; Tells whether to produce PDF "docinfo"
			 ;; (meta-information with title, author,
			 ;; keywords, etc.).
			 (make-pdf-docinfo? #t)

			 ;; Tells whether a PDF outline
			 ;; (aka. "bookmarks") should be produced.
			 (make-pdf-outline? #t)

			 ;; Procedure that takes a node and an engine and
			 ;; return a string representing the title of
			 ;; that node's PDF bookmark.
			 (pdf-bookmark-title-proc ,lout-pdf-bookmark-title)

			 ;; Procedure that takes a node and an engine and
			 ;; returns true if that node should have a PDF
			 ;; outline entry.
			 (pdf-bookmark-node-pred ,lout-pdf-bookmark-node?)

			 ;; Procedure that takes a node and an engine and
			 ;; returns true if the bookmark for that node
			 ;; should be closed ("folded") when the user
			 ;; opens the PDF document.
			 (pdf-bookmark-closed-pred
			  ,(lambda (n e)
			     (not (and (markup? n)
                                       (memq (markup-markup n)
                                             '(chapter slide slide-topic))))))

			 ;; color
			 (color? #t)

			 ;; source fontification
			 (source-color #t)
			 (source-comment-color "#ffa600")
			 (source-define-color "#6959cf")
			 (source-module-color "#1919af")
			 (source-markup-color "#1919af")
			 (source-thread-color "#ad4386")
			 (source-string-color "red")
			 (source-bracket-color "red")
			 (source-type-color "#00cf00"))

	       :symbol-table (lout-symbol-table
			      (lambda (m)
				;; We don't use `@Sym' because it doesn't
				;; work within `@M'.
				(string-append "{ { Symbol Base } @Font "
					       "@Char \"" m "\" }"))
			      (lambda (m)
                                ;; This form requires `@SysInclude { math }'.
				(format #f "{ @M { ~a } }" m)))))


;; So that calls to `markup-writer' automatically use `lout-engine'...
(push-default-engine lout-engine)



;; User-level implementation of PDF bookmarks.
;;
;; Basically, Lout code is produced that produces (via `@Graphic') PostScript
;; code.  That PostScript code is a `pdfmark' command (see Adobe's "pdfmark
;; Reference Manual") which, when converted to PDF (e.g. with `ps2pdf'),
;; produces a PDF outline, aka. "bookmarks" (see "PDF Reference, Fifth
;; Edition", section 8.2.2).

(define (lout-internal-dest-name ident)
  ;; Return the Lout-generated `pdfmark' named destination for `ident'.  This
  ;; function mimics Lout's `ConvertToPDFName ()', in `z49.c' (Lout's
  ;; PostScript back-end).  In Lout, `ConvertToPDFName ()' produces
  ;; destination names for the `/Dest' function of the `pdfmark' operator.
  ;; This implementation is valid as of Lout 3.31 and hopefully it won't
  ;; change in the future.
  (string-append "LOUT"
		 (list->string (map (lambda (c)
				      (if (or (char-alphabetic? c)
					      (char-numeric? c))
					  c
					  #\_))
				    (string->list ident)))))

(define (lout-pdf-bookmark node children closed? engine)
  ;; Return the PostScript `pdfmark' operation (a string) that creates a PDF
  ;; bookmark for node `node'.  `children' is the number of children of
  ;; `node' in the PDF outline.  If `closed?' is true, then the bookmark will
  ;; be close (i.e. its children are hidden).
  ;;
  ;; Note:  Here, we use a `GoTo' action, while we could instead simply
  ;; produce a `/Page' attribute without having to use the
  ;; `lout-internal-dest-name' hack.  The point for doing this is that Lout's
  ;; `@PageOf' operator doesn't return an "actual" page number within the
  ;; document, but rather a "typographically correct" page number (e.g. `i'
  ;; for the cover sheet, `1' for the second page, etc.).  See
  ;; http://lists.planix.com/pipermail/lout-users/2005q1/003925.html for
  ;; details.
  (let* ((filter-title (make-string-replace `(,@lout-verbatim-encoding
					      (#\newline " "))))
	 (make-bookmark-title (lambda (n e)
				(filter-title
				 ((engine-custom
				   engine 'pdf-bookmark-title-proc)
				  n e))))
	 (ident (markup-ident node)))
    (string-append "["
		   (if (= 0 children)
		       ""
		       (string-append "\"/\"Count "
				      (if closed? "-" "")
				      (number->string children) " "))
		   "\"/\"Title \"(\"" (make-bookmark-title node engine)
		   "\")\" "
		   (if (not ident) ""
		       (string-append "\"/\"Action \"/\"GoTo \"/\"Dest \"/\""
				      (lout-internal-dest-name ident) " "))
		   "\"/\"OUT pdfmark\n")))

(define (lout-pdf-outline node engine . children)
  ;; Return the PDF outline string (in the form of a PostScript `pdfmark'
  ;; command) for `node' whose child nodes are assumed to be `children',
  ;; unless `node' is a document.
  (let* ((choose-node? (lambda (n)
			 ((engine-custom engine 'pdf-bookmark-node-pred)
			  n engine)))
	 (nodes (if (document? node)
		    (filter choose-node? (markup-body node))
		    children)))
    (string-concatenate
	   (map (lambda (node)
		  (let* ((children (filter choose-node? (markup-body node)))
			 (closed? ((engine-custom engine
						  'pdf-bookmark-closed-pred)
				   node engine))
			 (bm (lout-pdf-bookmark node (length children)
						closed? engine)))
		    (string-append bm (apply lout-pdf-outline
					     `(,node ,engine ,@children)))))
		nodes))))

(define (lout-embedded-postscript-code postscript)
  ;; Return a string embedding PostScript code `postscript' into Lout code.
  (string-append "\n"
		 "{ @BackEnd @Case {\n"
		 "    PostScript @Yield {\n"
		 postscript
		 "        }\n"
		 "} } @Graphic { }\n"))

(define (lout-pdf-docinfo doc engine)
  ;; Produce PostScript code that will produce PDF document information once
  ;; converted to PDF.
  (let* ((filter-string (make-string-replace `(,@lout-verbatim-encoding
					       (#\newline " "))))
	 (docinfo-field (lambda (key value)
			  (string-append "\"/\"" key " \"(\""
					 (filter-string value)
					 "\")\"\n")))
	 (author (let ((a (engine-custom engine 'pdf-author)))
		   (if (or (string? a) (ast? a))
		       a
		       (markup-option doc :author))))
	 (title  (let ((t (engine-custom engine 'pdf-title)))
		   (if (or (string? t) (ast? t))
		       t
		       (markup-option doc :title))))
	 (keywords (or (engine-custom engine 'pdf-keywords)
                       (map ast->string
                            (or (markup-option doc :keywords) '()))))
	 (extra-fields (engine-custom engine 'pdf-extra-info)))

    (string-append "[ "
		   (if title
		       (docinfo-field "Title" (ast->string title))
		       "")
		   (if author
		       (docinfo-field "Author"
				      (or (cond ((markup? author)
						 (ast->string
						  (or (markup-option
						       author :name)
						      (markup-option
						       author :affiliation))))
						((string? author) author)
						(else (ast->string author)))
					  ""))
		       "")
		   (if (pair? keywords)
		       (docinfo-field "Keywords"
                                      (string-concatenate
                                             (keyword-list->comma-separated
                                              keywords)))
		       "")
		   ;; arbitrary key-value pairs, see sect. 4.7, "Info
		   ;; dictionary" of the `pdfmark' reference.
		   (if (or (not extra-fields) (null? extra-fields))
		       ""
		       (string-concatenate
			      (map (lambda (p)
				     (docinfo-field (car p) (cadr p)))
				   extra-fields)))
		   "\"/\"DOCINFO pdfmark\n")))

(define (lout-output-pdf-meta-info doc engine)
  ;; Produce PDF bookmarks (aka. "outline") for document `doc', as well as
  ;; document meta-information (or "docinfo").  This function makes sure that
  ;; both are only produced once, and only if the relevant customs ask for
  ;; them.
  (if (and doc (engine-custom engine 'make-pdf-outline?)
	   (not (markup-option doc '&pdf-outline-produced?)))
      (begin
	(display
	 (lout-embedded-postscript-code (lout-pdf-outline doc engine)))
	(markup-option-add! doc '&pdf-outline-produced? #t)))
  (if (and doc (engine-custom engine 'make-pdf-docinfo?)
	   (not (markup-option doc '&pdf-docinfo-produced?)))
      (begin
	(display
	 (lout-embedded-postscript-code (lout-pdf-docinfo doc engine)))
	(markup-option-add! doc '&pdf-docinfo-produced? #t))))



;*---------------------------------------------------------------------*/
;*    lout ...                                                         */
;*---------------------------------------------------------------------*/
(define (!lout fmt . opt)
   (if (engine-format? "lout")
       (apply ! fmt opt)
       #f))

;*---------------------------------------------------------------------*/
;*    lout-width ...                                                   */
;*---------------------------------------------------------------------*/
(define (lout-width width)
   (cond ((inexact? width) ;; a relative size (XXX: was `flonum?')
	  ;; FIXME: Hack ahead: assuming A4 with a 2.5cm margin
	  ;; on both sides
	  (let* ((orientation (let ((lout (find-engine 'lout)))
				 (or (and lout
					  (engine-custom lout
							 'page-orientation))
				     'portrait)))
		 (margins 5)
		 (paper-width (case orientation
				 ((portrait reverse-portrait)
				  (- 21 margins))
				 (else (- 29.7 margins)))))
	     (string-append (number->string (* paper-width
					       (/ (abs width) 100.)))
			    "c")))
	 ((string? width) ;; an engine-dependent width
	  width)
	 (else ;; an absolute "pixel" size
	  (string-append (number->string width) "p"))))

;*---------------------------------------------------------------------*/
;*    lout-size-ratio ...                                              */
;*---------------------------------------------------------------------*/
(define (lout-size-ratio size)
  ;; Return a font or break ratio for SIZE, an integer.  If SIZE is zero, 1.0
  ;; is returned; if it's positive, then a ratio > 1 is returned; if it's
  ;; negative, a ratio < 1 is returned.
  (expt 1.2 size))

(define (lout-color-specification skribe-color)
  ;; Return a Lout color name, ie. a string which is either an English color
  ;; name or something like "rgb 0.5 0.2 0.6".  `skribe-color' is a string
  ;; representing a Skribe color such as "black" or "#ffffff".
   (let ((b&w? (let ((lout (find-engine 'lout)))
		  (and lout (not (engine-custom lout 'color?)))))
	 (actual-color
	  (if (and (string? skribe-color)
		   (char=? (string-ref skribe-color 0) #\#))
	      (string->number (substring skribe-color 1
					 (string-length skribe-color))
			      16)
	      skribe-color)))
     (let-values (((r g b)
                   (color->rgb actual-color)))
       (apply format #f
              (cons "rgb ~a ~a ~a"
                    (map (if b&w?
                             (let ((avg (exact->inexact (/ (+ r g b)
                                                           (* 256 3)))))
                               (lambda (x) avg))
                             (lambda (x)
                               (exact->inexact (/ x 256))))
                         (list r g b)))))))

;*---------------------------------------------------------------------*/
;*    ~ ...                                                           */
;*---------------------------------------------------------------------*/
(markup-writer '~ :before "~" :action #f)

;*---------------------------------------------------------------------*/
;*    breakable-space ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer 'breakable-space :before " &1s\n" :action #f)


;;;
;;; Document.
;;;

(define (lout-page-orientation orientation)
  ;; Return a string representing the Lout page orientation name for symbol
  ;; `orientation'.
  (let* ((alist '((portrait . "Portrait")
		  (landscape . "Landscape")
		  (reverse-portrait . "ReversePortrait")
		  (reverse-landscape . "ReverseLandscape")))
	 (which (assoc orientation alist)))
    (if (not which)
	(skribe-error 'lout
		      "`page-orientation' should be either `portrait' or `landscape'"
		      orientation)
	(cdr which))))

(define (output-report-options doc e)
  ;; Output document options specific to the `report' document type.
  (let ((cover-sheet?   (engine-custom e 'cover-sheet?))
        (abstract       (engine-custom e 'abstract))
        (abstract-title (engine-custom e 'abstract-title)))
    (display (string-append "  @CoverSheet { "
                            (if cover-sheet? "Yes" "No")
                            " }\n"))

    (if abstract
        (begin
          (if (not (eq? abstract-title #t))
              (begin
                (display "  @AbstractTitle { ")
                (cond
                 ((not abstract-title) #t)
                 (else (output abstract-title e)))
                (display " }\n")))

          (display "  @Abstract {\n")
          (output abstract e)
          (display "\n}\n")))))

(define (output-book-options doc engine)
  ;; Output document options specific to the `book' document type.
  (define (output-option lout opt)
    (let ((val (engine-custom engine opt)))
      (if val
          (begin
            (format #t "  ~a { " lout)
            (output val engine)
            (display " }\n")))))

  (output-option "@Edition"         'edition)
  (output-option "@Publisher"       'publisher)
  (output-option "@BeforeTitlePage" 'before-title-page)
  (output-option "@OnTitlePage"     'on-title-page)
  (output-option "@AfterTitlePage"  'after-title-page)
  (output-option "@AtEnd"           'at-end))


;*---------------------------------------------------------------------*/
;*    document ...                                                     */
;*---------------------------------------------------------------------*/
(markup-writer 'document
   :options '(:title :author :ending :keywords :env)
   :before (lambda (n e) ;; `e' is the engine
             (cond-expand
              (guile-2
               ;; Make sure the output is suitably encoded.
               (let ((encoding (engine-custom e 'encoding)))
                 (set-port-encoding! (current-output-port) encoding)
                 (set-port-conversion-strategy! (current-output-port) 'error)
                 (cond ((string-ci=? encoding "ISO-8859-2")
                        (display "@SysInclude { latin2 }\n"))
                       ((not (string-ci=? encoding "ISO-8859-1"))
                        (raise (condition
                                (&invalid-argument-error
                                 (proc-name 'lout)
                                 (argument encoding))))))))
              (else #t))

	     (let* ((doc-type (let ((d (engine-custom e 'document-type)))
				(if (string? d)
				    (begin
				      (engine-custom-set! e 'document-type
							  (string->symbol d))
				      (string->symbol d))
				    d)))
		    (doc-style? (eq? doc-type 'doc))
		    (slides? (eq? doc-type 'slides))
		    (doc-include (engine-custom e 'document-include))
		    (includes (engine-custom e 'includes))
		    (font (engine-custom e 'initial-font))
		    (lang (engine-custom e 'initial-language))
		    (break (engine-custom e 'initial-break))
		    (column-number (engine-custom e 'column-number))
		    (first-page-number (engine-custom e 'first-page-number))
		    (page-orientation (engine-custom e 'page-orientation))
		    (title (markup-option n :title)))

	       ;; Add this markup option, used by
	       ;; `lout-start-large-scale-structure' et al.
	       (markup-option-add! n '&substructs-started? #f)

	       (if (eq? doc-include 'auto)
		   (case doc-type
		     ((report)  (display "@SysInclude { report }\n"))
		     ((book)    (display "@SysInclude { book }\n"))
		     ((doc)     (display "@SysInclude { doc }\n"))
		     ((slides)  (display "@SysInclude { slides }\n"))
		     (else     (skribe-error
				'lout
				"`document-type' should be one of `book', `report', `doc' or `slides'"
				doc-type)))
		   (format #t "# Custom document includes\n~a\n" doc-include))

	       (if includes
		   (format #t "# Additional user includes\n~a\n" includes)
		   (display "@SysInclude { tbl }\n"))

	       ;; Write additional Lout definitions
	       (display ((engine-custom e 'inline-definitions-proc) e))

	       (case doc-type
		 ((report) (display "@Report\n"))
		 ((book)   (display "@Book\n"))
		 ((doc)    (display "@Document\n"))
		 ((slides) (display "@OverheadTransparencies\n")))

	       (display (string-append "  @InitialSpace { tex } "
				       "# avoid having too many spaces\n"))

	       ;; The `doc' style doesn't have @Title, @Author and the likes
	       (if (not doc-style?)
		   (begin
		     (display "  @Title { ")
		     (if title
			 (output title e)
			 (display "The Lout-Skribe Book"))
		     (display " }\n")

		     ;; The author
		     (let* ((author (markup-option n :author)))

		       (display "  @Author { ")
		       (output author e)
		       (display " }\n")

		       ;; Lout reports support `@Institution' while books
		       ;; don't.
		       (if (and (eq? doc-type 'report)
				(is-markup? author 'author))
			   (let ((institution (markup-option author
							     :affiliation)))
			     (if institution
				 (begin
				   (display "  @Institution { ")
				   (output institution e)
				   (display " }\n"))))))))

               (if (memq doc-type '(report slides))
                   (let ((date-line (engine-custom e 'date-line)))
		     (display "  @DateLine { ")
                     (case date-line
                       ((#t) (display "Yes"))
                       ((#f) (display "No"))
                       (else (output date-line e)))
		     (display " }\n")))

               ;; Output options specific to one of the document types.
	       (case doc-type
                 ((report)  (output-report-options n e))
                 ((book)    (output-book-options n e)))

	       (format #t "  @OptimizePages { ~a }\n"
		       (if (engine-custom e 'optimize-pages?)
			   "Yes" "No"))

	       (format #t "  @InitialFont { ~a }\n"
		       (cond ((string? font) font)
			     ((symbol? font)
			      (string-append (symbol->string font)
					     " Base 10p"))
			     ((number? font)
			      (string-append "Palatino Base "
					     (number->string font)
					     "p"))
			     (#t
			      (skribe-error
			       'lout 'initial-font
			       "Should be a Lout font name, a symbol, or a number"))))
	       (format #t "  @InitialBreak { ~a }\n"
		       (if break break "adjust 1.2fx hyphen"))
	       (if (not slides?)
		   (format #t "  @ColumnNumber { ~a }\n"
			   (if (number? column-number)
			       column-number 1)))
	       (format #t "  @FirstPageNumber { ~a }\n"
		       (if (number? first-page-number)
			   first-page-number 1))
	       (format #t "  @PageOrientation { ~a }\n"
		       (lout-page-orientation page-orientation))
	       (format #t "  @InitialLanguage { ~a }\n"
		       (if lang lang "English"))

	       ;; FIXME: Insert a preface for text preceding the first ch.
	       ;; FIXME: Create an @Introduction for the first chapter
	       ;;        if its title is "Introduction" (for books).

	       (display "//\n\n")

	       (if doc-style?
		   ;; `doc' documents don't have @Title and the likes so
		   ;; we need to implement them "by hand"
		   (let ((make-cover-sheet
			  (engine-custom e 'doc-cover-sheet-proc)))
		     (display "@Text @Begin\n")
		     (if make-cover-sheet
			 (make-cover-sheet n e)
			 (lout-make-doc-cover-sheet n e))))

	       (if doc-style?
		   ;; Putting it here will only work with `doc' documents.
		   (lout-output-pdf-meta-info n e))))

   :after (lambda (n e)
	    (let ((doc-type (engine-custom e 'document-type)))
	      (if (eq? doc-type 'doc)
		  (begin
		    (if (markup-option n '&substructs-started?)
			(display "\n@EndSections\n"))
		    (display "\n@End @Text\n")))
	      (display "\n\n# Lout document ends here.\n"))))


;*---------------------------------------------------------------------*/
;*    author ...                                                       */
;*---------------------------------------------------------------------*/
(markup-writer 'author
   :options '(:name :title :affiliation :email :url :address
	      :phone :photo :align)

   :action (lambda (n e)
	      (let ((doc-type (engine-custom e 'document-type))
		    (name (markup-option n :name))
		    (title (markup-option n :title))
		    (affiliation (markup-option n :affiliation))
		    (email (markup-option n :email))
		    (url (markup-option n :url))
		    (address (markup-option n :address))
		    (phone (markup-option n :phone))
		    (photo (markup-option n :photo)))

		(define (row x)
		  (display "\n//1.5fx\n@Center { ")
		  (output x e)
		  (display " }\n"))

		(if email
		    (row (list (if name name "")
			       (! " <@I{")
			       (cond ((string? email) email)
				     ((markup? email)
				      (markup-body email))
				     (#t ""))
			       (! "}> ")))
		    (if name (row name)))

		(if title (row title))

		;; In reports, the affiliation is passed to `@Institution'.
		;; However, books do not have an `@Institution' parameter.
		(if (and affiliation (not (eq? doc-type 'report)))
		    (row affiliation))

		(if address (row address))
		(if phone (row phone))
		(if url (row (it url)))
		(if photo (row photo)))))


(define (lout-toc-entry node depth engine)
  ;; Produce a TOC entry of depth `depth' (a integer greater than or equal to
  ;; zero) for `node' using engine `engine'.  The Lout code here is mostly
  ;; copied from Lout's `dsf' (see definition of `@Item').
  (let ((ident (markup-ident node))
	(entry-proc (engine-custom engine 'toc-entry-proc)))
    (if (markup-option node :toc)
	(begin
	  (display "@LP\n")
	  (if ident
	      ;; create an internal for PDF navigation
	      (format #t "{ ~a } @LinkSource { " (lout-tagify ident)))

	  (if (> depth 0)
	      (format #t "|~as " (number->string (* 6 depth))))
	  (display " @HExpand { ")

	  ;; output the number and title of this node
	  (entry-proc node engine)

	  (display " &1rt @OneCol { ")
	  (format #t " @SkribiloLeaders & @PageOf { ~a }"
		  (lout-tagify (markup-ident node)))
	  (display " &0io } }")

	  (if ident (display " }"))
	  (display "\n")))))

;*---------------------------------------------------------------------*/
;*    toc ...                                                          */
;*---------------------------------------------------------------------*/
(markup-writer 'toc
   :options '(:class :chapter :section :subsection)
   :action (lambda (n e)
	     (display "\n# toc\n")
	     (if (markup-option n :chapter)
		 (let* ((doc      (or (ast-document n)
                                      (*document-being-output*)))
                        (chapters (find-down (lambda (n)
                                               (or (is-markup? n 'chapter)
                                                   (is-markup? n 'slide)))
                                             doc)))
		   (for-each (lambda (c)
			       (let ((sections
				      (find-down (lambda (n)
                                                   (is-markup? n 'section))
                                                 c)))
				 (lout-toc-entry c 0 e)
				 (if (markup-option n :section)
				     (for-each
				      (lambda (s)
					(lout-toc-entry s 1 e)
					(if (markup-option n :subsection)
					    (let ((subs
						   (search-down
						    (lambda (n)
						      (is-markup?
						       n 'subsection))
						    s)))
					      (for-each
					       (lambda (s)
						 (lout-toc-entry s 2 e))
					       subs))))
				      sections))))
			     chapters)))))

(define lout-book-markup-alist
  '((chapter . "Chapter")
    (section . "Section")
    (subsection . "SubSection")
    (subsubsection . "SubSubSection")))

(define lout-report-markup-alist
  '((chapter . "Section")
    (section . "SubSection")
    (subsection . "SubSubSection")
    (subsubsection . #f)))

(define lout-slides-markup-alist
  '((slide . "Overhead")))

(define lout-doc-markup-alist lout-report-markup-alist)

(define (lout-structure-markup skribe-markup engine)
  ;; Return the Lout structure name for `skribe-markup' (eg. "Chapter" for
  ;; `chapter' markups when `engine''s document type is `book').
  (let ((doc-type (engine-custom engine 'document-type))
	(assoc-ref (lambda (alist key)
		      (and-let* ((as (assoc key alist))) (cdr as)))))
    (case doc-type
      ((book)    (assoc-ref lout-book-markup-alist skribe-markup))
      ((report)  (assoc-ref lout-report-markup-alist skribe-markup))
      ((doc)     (assoc-ref lout-doc-markup-alist skribe-markup))
      ((slides)  (assoc-ref lout-slides-markup-alist skribe-markup))
      (else
       (skribe-error 'lout
		     "`document-type' should be one of `book', `report', `doc' or `slides'"
		     doc-type)))))


;*---------------------------------------------------------------------*/
;*    lout-block-before ...                                            */
;*---------------------------------------------------------------------*/
(define (lout-block-before n e)
  ;; Produce the Lout code that introduces node `n', a large-scale
  ;; structure (chapter, section, etc.).
  (let ((lout-markup (lout-structure-markup (markup-markup n) e))
	(title (markup-option n :title))
	(number (markup-option n :number))
        (word (markup-option n :word))
	(ident (markup-ident n)))

    (if (not lout-markup)
	(begin
	   ;; the fallback method (i.e. when there exists no equivalent
	   ;; Lout markup)
	   (display "\n//1.8vx\n@B { ")
	   (output title e)
	   (display " }\n@SkribiloMark { ")
	   (display (lout-tagify ident))
	   (display " }\n//0.8vx\n\n"))
	(begin
	   (format #t "\n@~a\n  @Title { " lout-markup)
	   (output title e)
	   (display " }\n")

	   (if number
	       (format #t "  @BypassNumber { ~a }\n"
		       (markup-number-string n))
               (display "  @BypassNumber { } # unnumbered\n"))

           (if (and word
                    (eq? (engine-custom e 'document-type)
                         'book))
               (format #t "  @BypassWord { ~a }~%"
                       word))

	   (cond ((string? ident)
		  (begin
		     (display "  @Tag { ")
		     (display (lout-tagify ident))
		     (display " }\n")))
		 ((symbol? ident)
		  (begin
		     (display "  @Tag { ")
		     (display (lout-tagify (symbol->string ident)))
		     (display " }\n")))
		 (#t
		  (skribe-error 'lout
				"Node identifiers should be strings"
				ident)))

	   (display "\n@Begin\n")))))

(define (lout-block-after n e)
  ;; Produce the Lout code that terminates node `n', a large-scale
  ;; structure (chapter, section, etc.).
  (let ((lout-markup (lout-structure-markup (markup-markup n) e)))
     (if (not lout-markup)
	 (display "\n\n//0.3vx\n\n") ;; fallback method
	 (format #t "\n\n@End @~a\n\n" lout-markup))))


(define (lout-markup-child-type skribe-markup)
  ;; Return the child markup type of `skribe-markup' (e.g. for `chapter',
  ;; return `section').
  (let loop ((structs '(document chapter section subsection subsubsection)))
    (if (null? structs)
	#f
	(if (eq? (car structs) skribe-markup)
	    (cadr structs)
	    (loop (cdr structs))))))

(define (lout-start-large-scale-structure markup engine)
  ;; Perform the necessary step and produce output as a result of starting
  ;; large-scale structure `markup' (ie. a chapter, section, subsection,
  ;; etc.).
  (let* ((doc-type (engine-custom engine 'document-type))
	 (doc-style? (eq? doc-type 'doc))
	 (parent (ast-parent markup))
	 (markup-type (markup-markup markup))
	 (lout-markup-name (lout-structure-markup markup-type
						  engine)))
    (lout-debug "start-struct: markup=~a parent=~a"
		markup parent)

    ;; add an `&substructs-started?' option to the markup
    (markup-option-add! markup '&substructs-started? #f)

    (if (and lout-markup-name
	     parent (or doc-style? (not (document? parent))))
	(begin
	  (if (not (markup-option parent '&substructs-started?))
	      ;; produce an `@BeginSubSections' or equivalent; `doc'-style
	      ;; documents need to preprend an `@BeginSections' before the
	      ;; first section while other styles don't.
	      (format #t "\n@Begin~as\n" lout-markup-name))

	  ;; FIXME: We need to make sure that PARENT is a large-scale
	  ;; structure, otherwise it won't have the `&substructs-started?'
	  ;; option (e.g., if PARENT is a `color' markup).  I need to clarify
	  ;; this.
	  (if (memq (markup-markup parent)
		    '(document chapter section subsection subsubsection))
	      ;; update the `&substructs-started?' option of the parent
	      (markup-option-set! parent '&substructs-started? #t))

	  (lout-debug "start-struct: updated parent: ~a"
		      (markup-option parent '&substructs-started?))))

    ;; output the `@Section @Title { ... } @Begin' thing
    (lout-block-before markup engine)))

(define (lout-end-large-scale-structure markup engine)
  ;; Produce Lout code for ending structure `markup' (a chapter, section,
  ;; subsection, etc.).
  (let* ((doc-type (engine-custom engine 'document-type))
	 (doc-style? (eq? doc-type 'doc))
	 (markup-type (markup-markup markup))
	 (lout-markup-name (lout-structure-markup markup-type
						  engine)))

    (if (and lout-markup-name
	     (markup-option markup '&substructs-started?)
	     (or doc-style? (not (document? markup))))
	(begin
	  ;; produce an `@EndSubSections' or equivalent; `doc'-style
	  ;; documents need to issue an `@EndSections' after the last section
	  ;; while other types of documents don't.
	  (lout-debug "end-struct: closing substructs for ~a" markup)
	  (format #t "\n@End~as\n"
		  (lout-structure-markup (lout-markup-child-type markup-type)
					 engine))
	  (markup-option-set! markup '&substructs-started? #f)))

    (lout-block-after markup engine)))


;*---------------------------------------------------------------------*/
;*    section ... .. @label chapter@                                   */
;*---------------------------------------------------------------------*/
(markup-writer 'chapter
   :options '(:title :number :toc :file :env :word)
   :validate (lambda (n e)
	       (document? (ast-parent n)))

   :before (lambda (n e)
	     (lout-start-large-scale-structure n e)

	     ;; `doc' documents produce their PDF outline right after
	     ;; `@Text @Begin'; other types of documents must produce it
	     ;; as part of their first chapter.
	     (lout-output-pdf-meta-info (ast-document n) e))

   :after lout-end-large-scale-structure)

;*---------------------------------------------------------------------*/
;*    section ... . @label section@                                    */
;*---------------------------------------------------------------------*/
(markup-writer 'section
   :options '(:title :number :toc :file :env :word)
   :validate (lambda (n e)
	       (is-markup? (ast-parent n) 'chapter))
   :before lout-start-large-scale-structure
   :after lout-end-large-scale-structure)

;*---------------------------------------------------------------------*/
;*    subsection ... @label subsection@                                */
;*---------------------------------------------------------------------*/
(markup-writer 'subsection
   :options '(:title :number :toc :file :env :word)
   :validate (lambda (n e)
	       (is-markup? (ast-parent n) 'section))
   :before lout-start-large-scale-structure
   :after lout-end-large-scale-structure)

;*---------------------------------------------------------------------*/
;*    subsubsection ... @label subsubsection@                          */
;*---------------------------------------------------------------------*/
(markup-writer 'subsubsection
   :options '(:title :number :toc :file :env :word)
   :validate (lambda (n e)
	       (is-markup? (ast-parent n) 'subsection))
   :before lout-start-large-scale-structure
   :after lout-end-large-scale-structure)


;*---------------------------------------------------------------------*/
;*    support for paragraphs ...                                       */
;*---------------------------------------------------------------------*/

(define (make-drop-capital? n e)
  ;; Return true if the first letter of N's body should be output as a drop
  ;; capital.
  (let ((pred (engine-custom e 'drop-capital?)))
    (cond ((procedure? pred)
           (pred n e))
          ((not pred)
           #f)
          (else
           (and (is-markup? (ast-parent n) 'chapter)
                (first-paragraph? n))))))

(define (output-with-drop-capital n e)
  ;; Assuming N is a paragraph, try producing a drop capital.

  (define (drop-capital-function)
    (let ((lines (engine-custom e 'drop-capital-lines)))
      (if (integer? lines)
          (case lines
            ((3)  "@DropCapThree")
            (else "@DropCapTwo"))
          "@DropCapTwo")))

  (define (try)
    (let loop ((body (markup-body n)))
      (cond ((string? body)
             (let ((body (string-trim body)))
               (and (not (string=? body ""))
                    (begin
                      (display "{ ")
                      (output (string (string-ref body 0)) e)
                      (format #t " } ~a { " (drop-capital-function))
                      (output (string-drop body 1) e)
                      #t))))
            ((pair? body)
             (let ((did-it? (loop (car body))))
               (output (cdr body) e)
               did-it?))
            (else
             (output body e)
             #f))))

  (let ((did-it? (try)))
    (if did-it?
        (display " } "))))

;*---------------------------------------------------------------------*/
;*    paragraph ...                                                    */
;*---------------------------------------------------------------------*/
(markup-writer 'paragraph
   :options '()
   :validate (lambda (n e)
	       (or (eq? 'doc (engine-custom e 'document-type))
		   (memq (and (markup? (ast-parent n))
			      (markup-markup (ast-parent n)))
			 '(chapter section subsection subsubsection slide))))
   :before (lambda (n e)
	     (let ((gap (if (first-paragraph? n)
                            (engine-custom e 'first-paragraph-gap)
                            (engine-custom e 'paragraph-gap))))
	       (display (if (string? gap) gap "\n@PP\n"))))

   :action (lambda (n e)
             (if (make-drop-capital? n e)
                 (output-with-drop-capital n e)
                 (output (markup-body n) e))))


;*---------------------------------------------------------------------*/
;*    footnote ...                                                     */
;*---------------------------------------------------------------------*/
(markup-writer 'footnote
   :options '(:label)
   :before (lambda (n e)
	     (let ((label (markup-option n :label))
		   (use-number?
		    (not (engine-custom e 'use-lout-footnote-numbers?))))
	       (if (or (and (number? label) use-number?) label)
		   (format #t "{ @FootNote @Label { ~a } { "
			   (if label label ""))
		   (format #t "{ @FootNote ~a{ "
			   (if (not label) "@Label { } " "")))))
   :after (lambda (n e)
	    (display " } }")))

;*---------------------------------------------------------------------*/
;*    linebreak ...                                                    */
;*---------------------------------------------------------------------*/
(markup-writer 'linebreak
   :action (lambda (n e)
	      (display "\n@LP\n")))

;*---------------------------------------------------------------------*/
;*    hrule ...                                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'hrule
   :options '()
   :action "\n@LP\n@FullWidthRule\n@LP\n")

;*---------------------------------------------------------------------*/
;*    color ...                                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'color
   :options '(:fg :bg :width)
   ;; FIXME: `:bg' not supported
   ;; FIXME: `:width' is not supported either.  Rather use `frame' for that
   ;; kind of options.
   :before (lambda (n e)
	     (let ((fg (markup-option n :fg)))
               ;; Skip a line to avoid hitting Basser Lout's length limit.
	       (format #t "{ { ~a }\n@Color { " (lout-color-specification fg))))

   :after (lambda (n e)
	    (display " } }")))

;*---------------------------------------------------------------------*/
;*    frame ...                                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'frame
   ;; @Box won't span over several pages so this may cause
   ;; problems if large frames are used.  The workaround here consists
   ;; in using an @Tbl with one single cell.
   :options '(:width :border :margin :bg)
   :before (lambda (n e)
	     (let ((width (markup-option n :width))
		   (margin (markup-option n :margin))
		   (border (markup-option n :border))
		   (bg (markup-option n :bg)))

	       ;; The user manual seems to expect `frame' to imply a
	       ;; linebreak.  However, the LaTeX engine doesn't seem to
	       ;; agree.
	       ;(display "\n@LP")
	       (format #t (string-append "\n@Tbl # frame\n"
				      "  rule { yes }\n"))
	       (if border (format #t     "  rulewidth { ~a }\n"
				      (lout-width border)))
	       (if width  (format #t     "  width { ~a }\n"
				      (lout-width width)))
	       (if margin (format #t     "  margin { ~a }\n"
				      (lout-width margin)))
	       (if bg     (format #t     "  paint { ~a }\n"
				      (lout-color-specification bg)))
	       (display "{ @Row format { @Cell A } A { "))

; 	     (format #t "\n@Box linewidth { ~a } margin { ~a } { "
; 		     (lout-width (markup-option n :width))
; 		     (lout-width (markup-option n :margin)))
	     )
   :after (lambda (n e)
	    (display " } }\n")))

;*---------------------------------------------------------------------*/
;*    font ...                                                         */
;*---------------------------------------------------------------------*/
(markup-writer 'font
   :options '(:size :face)
   :before (lambda (n e)
             (if (markup-option n :size)
                 (let ((ratio (lout-size-ratio (markup-option n :size))))
                   (format #t "\n~af @Font ~avx @Break { " ratio ratio))
                 (display "{")))
   :after (lambda (n e)
	    (display " }\n")))

;*---------------------------------------------------------------------*/
;*    flush ...                                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'flush
   :options '(:side)
   :before (lambda (n e)
	      (display "\n@LP")
	      (case (markup-option n :side)
		 ((center)
		  (display "\n@Center { # flush-center\n"))
		 ((left)
		  (display "\n# flush-left\n"))
		 ((right)
		  (display (string-append "\n@Right "
					  "{ rragged hyphen } @Break "
					  "{ # flush-right\n")))))
   :after (lambda (n e)
	     (case (markup-option n :side)
		((left)
		 (display ""))
		(else
		 (display "\n}")))
	     (display " # flush\n")))

;*---------------------------------------------------------------------*/
;*    center ...                                                       */
;*---------------------------------------------------------------------*/
(markup-writer 'center
   ;; Note: We prepend and append a newline in order to make sure
   ;; things work as expected.
   :before "\n@LP\n@Center {"
   :after "}\n@LP\n")

;*---------------------------------------------------------------------*/
;*    pre ...                                                          */
;*---------------------------------------------------------------------*/
(markup-writer 'pre
   :before "\n@LP lines @Break lout @Space { # pre\n"
   :after "\n} # pre\n")

;*---------------------------------------------------------------------*/
;*    prog ...                                                         */
;*---------------------------------------------------------------------*/
(markup-writer 'prog
   :options '(:line :mark)
   :before "\nlines @Break lout @Space {\n"
   :after "\n} # @Break\n")

;*---------------------------------------------------------------------*/
;*    &prog-line ...                                                   */
;*---------------------------------------------------------------------*/
;; Program lines appear within a `lines @Break' block.
(markup-writer '&prog-line
   :action (lambda (n e)
             (let ((num (markup-option n :number)))
               (and (number? num)
                    (format #t "{ 3f @Wide { ~a. } } "
                            num))
               (output (markup-body n) e)
               (display "\n"))))

;*---------------------------------------------------------------------*/
;*    itemize ...                                                      */
;*---------------------------------------------------------------------*/
(markup-writer 'itemize
   :options '(:symbol)
   :before (lambda (n e)
	     (let ((symbol (markup-option n :symbol)))
	       (if symbol
		   (begin
		     (display "\n@List style { ")
		     (output symbol e)
		     (display " } # itemize\n"))
		   (display "\n@BulletList # itemize\n"))))
   :after "\n@EndList\n")

;*---------------------------------------------------------------------*/
;*    enumerate ...                                                    */
;*---------------------------------------------------------------------*/
(markup-writer 'enumerate
   :options '(:symbol)
   :before (lambda (n e)
	     (let ((symbol (markup-option n :symbol)))
	       (if symbol
		   (format #t "\n@List style { ~a } # enumerate\n"
			   symbol)
		   (display "\n@NumberedList # enumerate\n"))))
   :after "\n@EndList\n")

;*---------------------------------------------------------------------*/
;*    description ...                                                  */
;*---------------------------------------------------------------------*/
(markup-writer 'description
   :options '(:symbol) ;; `symbol' doesn't make sense here
   :before "\n@TaggedList # description\n"
   :action (lambda (n e)
	      (for-each (lambda (item)
			   (let ((k (markup-option item :key)))
			     (display "@DropTagItem { ")
			     (for-each (lambda (i)
					 (output i e)
					 (display " "))
				       (if (pair? k) k (list k)))
			     (display " } { ")
			     (output (markup-body item) e)
			     (display " }\n")))
			(markup-body n)))
   :after "\n@EndList\n")

;*---------------------------------------------------------------------*/
;*    item ...                                                         */
;*---------------------------------------------------------------------*/
(markup-writer 'item
   :options '(:key)
   :before "\n@LI { "
   :after  " }")

;*---------------------------------------------------------------------*/
;*    blockquote ...                                                   */
;*---------------------------------------------------------------------*/
(markup-writer 'blockquote
   :before "\n@ID {"
   :after  "\n} # @ID\n")

;*---------------------------------------------------------------------*/
;*    figure ... @label figure@                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'figure
   :options '(:legend :number :multicolumns)
   :action (lambda (n e)
	      (let ((ident (markup-ident n))
		    (number (markup-option n :number))
		    (legend (markup-option n :legend))
		    (mc? (markup-option n :multicolumns)))
		 (display "\n@Figure\n")
		 (display "  @Tag { ")
		 (display (lout-tagify ident))
		 (display " }\n")
		 (format #t  "  @BypassNumber { ~a }\n"
			  (cond ((number? number) number)
				((not number)     "")
				(else             number)))
                 (display "  @OnePage { Yes }\n")
		 (display "  @InitialLanguage { ")
		 (display (engine-custom e 'initial-language))
		 (display " }\n")

		 (if legend
		     (begin
		       (lout-debug "figure: ~a, \"~a\"" ident legend)
		       (display  "  @Caption { ")
		       (output legend e)
		       (display  " }\n")))
		 (format #t "  @Location { ~a }\n"
			 (if mc? "PageTop" "ColTop"))
		 (display  "{\n")
		 (output (markup-body n) e)))
   :after (lambda (n e)
	    (display "}\n")))


;;;
;;; Table layout.
;;;

(define (lout-table-cell-indent align)
  ;; Return the Lout name (a string) for cell alignment `align' (a symbol).
  (case align
    ((center #f #t) "ctr")
    ((right)        "right")
    ((left)         "left")
    (else (skribe-error 'td align
			"Unknown alignment type"))))

(define (lout-table-cell-vindent align)
  ;; Return the Lout name (a string) for cell alignment `align' (a symbol).
  (case align
    ((center #f #t) "ctr")
    ((top)          "top")
    ((bottom)       "foot")
    (else (skribe-error 'td align
			"Unknown alignment type"))))

(define (lout-table-cell-vspan cell-letter row-vspan)
   ;; Return the vspan information (an alist) for the cell whose
   ;; letter is `cell-letter', within the row whose vspan information
   ;; is given by `row-vspan'.  If the given cell doesn't span over
   ;; rows, then #f is returned.
   (and-let* ((as (assoc cell-letter row-vspan)))
	     (cdr as)))

(define (lout-table-cell-vspan-start? vspan-alist)
   ;; For the cell whose vspan information is given by `vspan-alist',
   ;; return #t if that cell starts spanning vertically.
   (and vspan-alist
	(cdr (assoc 'start? vspan-alist))))

(define-macro (char+int c i)
  `(integer->char (+ ,i (char->integer ,c))))

(define-macro (-- i)
  `(- ,i 1))


(define (lout-table-cell-option-string cell)
  ;; Return the Lout cell option string for `cell'.
  (let ((align (markup-option cell :align))
	(valign (markup-option cell :valign))
	(width (markup-option cell :width))
	(bg (markup-option cell :bg)))
    (string-append (lout-table-cell-rules cell) " "
		   (string-append
		    "indent { "
		    (lout-table-cell-indent align)
		    " } ")
		   (string-append
		    "indentvertical { "
		    (lout-table-cell-vindent valign)
		    " } ")
		   (if (not width) ""
		       (string-append "width { "
				      (lout-width width)
				      " } "))
		   (if (not bg) ""
		       (string-append "paint { "
				      (lout-color-specification bg)
				      " } ")))))

(define (lout-table-cell-format-string cell vspan-alist)
  ;; Return a Lout cell format string for `cell'.  It uses the `&cell-name'
  ;; markup option of its cell as its Lout cell name and `vspan-alist' as the
  ;; source of information regarding its vertical spanning (#f means that
  ;; `cell' is not vertically spanned).
  (let ((cell-letter (markup-option cell '&cell-name))
	(cell-options (lout-table-cell-option-string cell))
	(colspan (if vspan-alist
		     (cdr (assoc 'hspan vspan-alist))
		     (markup-option cell :colspan)))
	(vspan-start? (and vspan-alist
			   (cdr (assoc 'start? vspan-alist)))))
    (if (and (not vspan-start?) vspan-alist)
	"@VSpan"
	(let* ((cell-fmt (string-append "@Cell " cell-options
					(string cell-letter))))
          (if (> colspan 1)
              (string-append (if (and vspan-start? vspan-alist)
                                 "@StartHVSpan " "@StartHSpan ")
                             cell-fmt
                             (let pool ((cnt (- colspan 1))
                                        (span-cells ""))
                               (if (= cnt 0)
                                   span-cells
                                   (pool (- cnt 1)
                                         (string-append span-cells
                                                        " | @HSpan")))))
              (string-append (if (and vspan-alist vspan-start?)
                                 "@StartVSpan " "")
                             cell-fmt))))))


(define (lout-table-row-format-string row)
  ;; Return a Lout row format string for row `row'.  It uses the `&cell-name'
  ;; markup option of its cell as its Lout cell name.

  ;; FIXME: This function has become quite ugly
  (let ((cells (markup-body row))
	(row-vspan (markup-option row '&vspan-alist)))

    (let loop ((cells cells)
	       (cell-letter #\A)
	       (delim "")
	       (fmt ""))
      (lout-debug "looping on cell ~a" cell-letter)

      (if (null? cells)

	  ;; The final `|' prevents the rightmost column to be
	  ;; expanded to full page width (see sect. 6.11, p. 133).
	  (if row-vspan
	      ;; In the end, there can be vspan columns left so we need to
	      ;; mark them
	      (let final-loop ((cell-letter cell-letter)
			       (fmt fmt))
		(let* ((cell-vspan (lout-table-cell-vspan cell-letter
							  row-vspan))
		       (hspan (if cell-vspan
				  (cdr (assoc 'hspan cell-vspan))
				  1)))
		  (lout-debug "final-loop: ~a ~a" cell-letter cell-vspan)
		  (if (not cell-vspan)
		      (string-append fmt " |")
		      (final-loop (integer->char
				   (+ hspan (char->integer cell-letter)))
				  (string-append fmt " | @VSpan |")))))

	      (string-append fmt " |"))

	  (let* ((cell (car cells))
		 (vspan-alist (lout-table-cell-vspan cell-letter row-vspan))
		 (vspan-start? (lout-table-cell-vspan-start? vspan-alist))
		 (colspan (if vspan-alist
			      (cdr (assoc 'hspan vspan-alist))
			      (markup-option cell :colspan)))
		 (cell-format
		  (lout-table-cell-format-string cell vspan-alist)))

	    (loop (if (or (not vspan-alist) vspan-start?)
		      (cdr cells)
		      cells)  ;; don't skip pure vspan cells

		  ;; next cell name
		  (char+int cell-letter colspan)

		  " | "  ;; the cell delimiter
		  (string-append fmt delim cell-format)))))))



;; A row vspan alist describes the cells of a row that span vertically
;; and it looks like this:
;;
;;    ((#\A . ((start? . #t) (hspan . 1) (vspan . 3)))
;;     (#\C . ((start? . #f) (hspan . 2) (vspan . 1))))
;;
;; which means that cell `A' start spanning vertically over three rows
;; including this one, while cell `C' is an "empty" cell that continues
;; the vertical spanning of a cell appearing on some previous row.
;;
;; The running "global" (or "table-wide") vspan alist looks the same
;; except that it doesn't have the `start?' tags.

(define (lout-table-compute-row-vspan-alist row global-vspan-alist)
  ;; Compute the vspan alist of row `row' based on the current table vspan
  ;; alist `global-vspan-alist'.  As a side effect, this function stores the
  ;; Lout cell name (a character between #\A and #\Z) as the value of markup
  ;; option `&cell-name' of each cell.
  (if (pair? (markup-body row))
      ;; Mark the first cell as such.
      (markup-option-add! (car (markup-body row)) '&first-cell? #t))

  (let cell-loop ((cells (markup-body row))
		  (cell-letter #\A)
		  (row-vspan-alist '()))
    (lout-debug "cell: ~a ~a" cell-letter
		(if (null? cells) '() (car cells)))

    (if (null? cells)

	;; In the end, we must retain any vspan cell that occurs after the
	;; current cell name (note: we must add a `start?' tag at this point
	;; since the global table vspan alist doesn't have that).
	(let ((additional-cells (filter (lambda (c)
					  (char>=? (car c) cell-letter))
					global-vspan-alist)))
	  (lout-debug "compute-row-vspan-alist returning: ~a + ~a (~a)"
		      row-vspan-alist additional-cells
		      (length global-vspan-alist))
	  (append row-vspan-alist
		  (map (lambda (c)
			 `(,(car c) . ,(cons '(start? . #f) (cdr c))))
		       additional-cells)))

	(let* ((current-cell-vspan (assoc cell-letter global-vspan-alist))
	       (hspan (if current-cell-vspan
			  (cdr (assoc 'hspan (cdr current-cell-vspan)))
			  (markup-option (car cells) :colspan))))

	  (if (null? (cdr cells))
	      ;; Mark the last cell as such
	      (markup-option-add! (car cells) '&last-cell? #t))

	  (cell-loop (if current-cell-vspan
			 cells ;; this cell is vspanned, so don't skip it
			 (cdr cells))

		     ;; next cell name
		     (char+int cell-letter (or hspan 1))

		     (begin ;; updating the row vspan alist
		       (lout-debug "cells: ~a" (length cells))
		       (lout-debug "current-cell-vspan for ~a: ~a"
				   cell-letter current-cell-vspan)

		       (if current-cell-vspan

			   ;; this cell is currently vspanned, ie. a previous
			   ;; row defined a vspan for it and that it is still
			   ;; spanning on this row
			   (cons `(,cell-letter
				   . ((start? . #f)
				      (hspan  . ,(cdr
						  (assoc
						   'hspan
						   (cdr current-cell-vspan))))))
				 row-vspan-alist)

			   ;; this cell is not currently vspanned
			   (let ((vspan (markup-option (car cells) :rowspan)))
			     (lout-debug "vspan-option for ~a: ~a"
					 cell-letter vspan)

			     (markup-option-add! (car cells)
						 '&cell-name cell-letter)
			     (if (and vspan (> vspan 1))
				 (cons `(,cell-letter . ((start? . #t)
							 (hspan . ,hspan)
							 (vspan . ,vspan)))
				       row-vspan-alist)
				 row-vspan-alist)))))))))

(define (lout-table-update-table-vspan-alist table-vspan-alist
					     row-vspan-alist)
  ;; Update `table-vspan-alist' based on `row-vspan-alist', the alist
  ;; representing vspan cells for the last row that has been read."
  (lout-debug "update-table-vspan: ~a and ~a"
	      table-vspan-alist row-vspan-alist)

  (let ((new-vspan-cells (filter (lambda (cell)
				   (cdr (assoc 'start? (cdr cell))))
				 row-vspan-alist)))

    ;; Append the list of new vspan cells described in `row-vspan-alist'
    (let loop ((cells (append table-vspan-alist new-vspan-cells))
	       (result '()))
      (if (null? cells)
	  (begin
	    (lout-debug "update-table-vspan returning: ~a" result)
	    result)
	  (let* ((cell (car cells))
		 (cell-letter (car cell))
		 (cell-hspan (cdr (assoc 'hspan (cdr cell))))
		 (cell-vspan (-- (cdr (assoc 'vspan (cdr cell))))))
	    (loop (cdr cells)
		  (if (> cell-vspan 0)

		      ;; Keep information about this vspanned cell
		      (cons `(,cell-letter . ((hspan . ,cell-hspan)
					      (vspan . ,cell-vspan)))
			    result)

		      ;; Vspan for this cell has been done so we can remove
		      ;; it from the running table vspan alist
		      result)))))))

(define (lout-table-mark-vspan! tab)
  ;; Traverse the rows of table `tab' and add them an `&vspan-alist' option
  ;; that describes which of its cells are to be vertically spanned.
  (let loop ((rows (markup-body tab))
	     (global-vspan-alist '()))
    (if (null? rows)

	;; At this point, each row holds its own vspan information alist (the
	;; `&vspan-alist' option) so we don't care anymore about the running
	;; table vspan alist
	#t

	(let* ((row (car rows))
	       (row-vspan-alist (lout-table-compute-row-vspan-alist
				 row global-vspan-alist)))

	  ;; Bind the row-specific vspan information to the row object
	  (markup-option-add! row '&vspan-alist row-vspan-alist)

	  (if (null? (cdr rows))
	      ;; Mark the last row as such
	      (markup-option-add! row '&last-row? #t))

	  (loop (cdr rows)
		(lout-table-update-table-vspan-alist global-vspan-alist
						     row-vspan-alist))))))

(define (lout-table-first-row? row)
   (markup-option row '&first-row?))

(define (lout-table-last-row? row)
   (markup-option row '&last-row?))

(define (lout-table-first-cell? cell)
   (markup-option cell '&first-cell?))

(define (lout-table-last-cell? cell)
   (markup-option cell '&last-cell?))

(define (lout-table-row-rules row)
   ;; Return a string representing the Lout option string for
   ;; displaying rules of `row'.
   (let* ((table (ast-parent row))
	  (frames (markup-option table :frame))
	  (rules (markup-option table :rules))
	  (first? (lout-table-first-row? row))
	  (last? (lout-table-last-row? row)))
      (string-append (if (and first?
			      (member frames '(above hsides box border)))
			 "ruleabove { yes } " "")
		     (if (and last?
			      (member frames '(below hsides box border)))
			 "rulebelow { yes } " "")
		     ;; rules
		     (case rules
			((header)
			 ;; We consider the first row to be a header row.
			 (if first? "rulebelow { yes }" ""))
			((rows all)
			 ;; We use redundant rules because coloring
			 ;; might make them disappear otherwise.
			 (string-append (if first? "" "ruleabove { yes } ")
					(if last? "" "rulebelow { yes }")))
			(else "")))))

(define (lout-table-cell-rules cell)
   ;; Return a string representing the Lout option string for
   ;; displaying rules of `cell'.
   (let* ((row (ast-parent cell))
	  (table (ast-parent row))
	  (frames (markup-option table :frame))
	  (rules (markup-option table :rules))
	  (first? (lout-table-first-cell? cell))
	  (last? (lout-table-last-cell? cell)))
      (string-append (if (and first?
			      (member frames '(vsides lhs box border)))
			 "ruleleft { yes } " "")
		     (if (and last?
			      (member frames '(vsides rhs box border)))
			 "ruleright { yes } " "")
		     ;; rules
		     (case rules
			((cols all)
			 ;; We use redundant rules because coloring
			 ;; might make them disappear otherwise.
			 (string-append (if last? "" "ruleright { yes } ")
					(if first? "" "ruleleft { yes }")))
			(else "")))))

;*---------------------------------------------------------------------*/
;*    table ...                                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'table
   :options '(:frame :rules :border :width :cellpadding :rulecolor)
   ;; XXX: `:cellstyle' `separate' and `:cellspacing' not supported
   ;; by Lout's @Tbl.
   :before (lambda (n e)
	      (let ((border (markup-option n :border))
		    (cp (markup-option n :cellpadding)))

		 (if (pair? (markup-body n))
		     ;; Mark the first row as such
		     (markup-option-add! (car (markup-body n))
					 '&first-row? #t))

		 ;; Mark each row with vertical spanning information
		 (lout-table-mark-vspan! n)

                 (if (find1-up (lambda (n)
                                 (is-markup? n 'figure))
                               n)
                     ;; Work around a bug preventing `@VSpan' from working
                     ;; properly within floating figures:
                     ;; http://article.gmane.org/gmane.comp.type-setting.lout/1090 .
                     (display "\n@OneRow"))

		 (display "\n@Tbl # table\n")

		 (if (number? border)
		     (format #t "  rulewidth { ~a }\n"
			     (lout-width (markup-option n :border))))
		 (if (number? cp)
		     (format #t "  margin { ~ap }\n"
			     (number->string cp)))
                 (let ((rule-color (markup-option n :rulecolor)))
                   (and rule-color
                        (format #t "  rulecolor { ~a }~%"
                                (lout-color-specification rule-color))))

		 (display "{\n")))

   :after (lambda (n e)
	    (let ((header-rows (or (markup-option n '&header-rows) 0)))
	      ;; Issue an `@EndHeaderRow' symbol for each `@HeaderRow' symbol
	      ;; previously produced.
	      (let ((cnt header-rows))
		(if (> cnt 0)
		    (display "\n@EndHeaderRow"))))

	    (display "\n} # @Tbl\n")))

;*---------------------------------------------------------------------*/
;*    'tr ...                                                          */
;*---------------------------------------------------------------------*/
(markup-writer 'tr
   :options '(:bg)
   :action (lambda (row e)
	     (let* ((bg (markup-option row :bg))
		    (bg-color (if (not bg) ""
				  (string-append
				   "paint { "
				   (lout-color-specification bg) " } ")))
		    (first-row? (markup-option row '&first-row?))
		    (header-row? (any (lambda (n)
					(eq? (markup-option n 'markup)
					     'th))
				      (markup-body row)))
		    (fmt (lout-table-row-format-string row))
		    (rules (lout-table-row-rules row)))

	       ;; Use `@FirstRow' and `@HeaderFirstRow' for the first
	       ;; row.  `@HeaderFirstRow' seems to be buggy though.
	       ;; (see section 6.1, p.119 of the User's Guide).

	       (format #t "\n@~aRow ~aformat { ~a }"
		       (if first-row? "First" "")
		       bg-color fmt)
	       (display (string-append " " rules))
	       (output (markup-body row) e)

	       (if (and header-row? (engine-custom e 'use-header-rows?))
		   ;; `@HeaderRow' symbols are not actually printed
		   ;; (see section 6.11, p. 134 of the User's Guide)
		   ;; FIXME:  This all seems buggy on the Lout side.
		   (let* ((tab (ast-parent row))
			  (hrows (and (markup? tab)
				      (or (markup-option tab '&header-rows)
					  0))))
		     (if (not (is-markup? tab 'table))
			 (skribe-error 'lout
				       "tr's parent not a table!" tab))
		     (markup-option-add! tab '&header-rows (+ hrows 1))
		     (format #t "\n@Header~aRow ~aformat { ~a }"
			     ""   ; (if first-row? "First" "")
			     bg-color fmt)
		     (display (string-append " " rules))
		     
		     ;; the cells must be produced once here
		     (output (markup-body row) e))))))

;*---------------------------------------------------------------------*/
;*    tc                                                               */
;*---------------------------------------------------------------------*/
(markup-writer 'tc
   :options '(markup :width :align :valign :colspan :rowspan :bg)
   :before (lambda (cell e)
	     (format #t "\n  ~a { " (markup-option cell '&cell-name)))
   :after (lambda (cell e)
	    (display " }")))



;*---------------------------------------------------------------------*/
;*    image ...                                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'image
   :options '(:file :url :width :height :zoom)
   :action (lambda (n e)
	      (let* ((file (markup-option n :file))
		     (url (markup-option n :url))
		     (width (markup-option n :width))
		     (height (markup-option n :height))
		     (zoom (markup-option n :zoom))
		     (efmt (engine-custom e 'image-format))
		     (img (or url (convert-image file
						 (if (list? efmt)
						     efmt
						     '("eps"))))))
		(cond (url ;; maybe we should run `wget' then?  :-)
                       (skribe-warning/ast 1 n
                                           (_ "image URLs not supported")))

                      ((string? img)
                       (if width
                           (format #t "\n~a @Wide" (lout-width width)))
                       (if height
                           (format #t "\n~a @High" (lout-width height)))
                       (if zoom
                           (format #t "\n~a @Scale" zoom))
                       (format #t "\n@IncludeGraphic { \"~a\" }\n" img))

                      (else
                       (raise (condition
                               (&invalid-argument-error
                                (proc-name "image/lout")
                                (argument  img)))))))))

;*---------------------------------------------------------------------*/
;*    Ornaments ...                                                    */
;*---------------------------------------------------------------------*/
;; Each ornament is enclosed in braces to allow such things as
;; "he,(bold "ll")o" to work without adding an extra space.
(markup-writer 'roman :before "{ @R { " :after " } }")
(markup-writer 'underline :before  "{ @Underline { " :after " } }")
(markup-writer 'code :before "{ @F { " :after " } }")
(markup-writer 'var :before "{ @F { " :after " } }")
(markup-writer 'sc :before "{ @S {" :after " } }")
(markup-writer 'sf :before "{ { Helvetica Base } @Font { " :after " } }")
(markup-writer 'sub :before "{ @Sub { " :after " } }")
(markup-writer 'sup :before "{ @Sup { " :after " } }")
(markup-writer 'tt :before "{ @F { " :after " } }")


;; `(bold (it ...))' and `(it (bold ...))' should both lead to `@BI { ... }'
;; instead of `@B { @I { ... } }' (which is different).
;; Unfortunately, it is not possible to use `ast-parent' and
;; `find1-up' to check whether `it' (resp. `bold') was invoked within
;; a `bold' (resp. `it') markup, hence the `&italics' and `&bold'
;; option trick.   FIXME:  This would be much more efficient if
;; `ast-parent' would work as expected.

;; FIXME: See whether `@II' can be useful.  Use SRFI-39 parameters.

(markup-writer 'it
   :before (lambda (node engine)
	      (let ((bold-children (search-down (lambda (n)
						   (is-markup? n 'bold))
						node)))
		 (map (lambda (b)
			 (markup-option-add! b '&italics #t))
		      bold-children)
		 (format #t "{ ~a { "
		      (if (markup-option node '&bold)
			  "@BI" "@I"))))
   :after " } }")

(markup-writer 'emph
   :before (lambda (n e)
	      (invoke (writer-before (markup-writer-get 'it e))
		      n e))
   :after (lambda (n e)
	     (invoke (writer-after (markup-writer-get 'it e))
		     n e)))

(markup-writer 'bold
   :before (lambda (node engine)
	      (let ((it-children (search-down (lambda (n)
						 (or (is-markup? n 'it)
						     (is-markup? n 'emph)))
					      node)))
		 (map (lambda (i)
			 (markup-option-add! i '&bold #t))
		      it-children)
		 (format #t "{ ~a { "
			 (if (markup-option node '&italics)
			     "@BI" "@B"))))
   :after " } }")

;*---------------------------------------------------------------------*/
;*    q ... @label q@                                                  */
;*---------------------------------------------------------------------*/
(markup-writer 'q
   :before "{ @Char guillemotleft }\" \""
   :after "\" \"{ @Char guillemotright }")

;*---------------------------------------------------------------------*/
;*    mailto ... @label mailto@                                        */
;*---------------------------------------------------------------------*/
(markup-writer 'mailto
   :options '(:text)
   :before " @I { "
   :action (lambda (n e)
	      (let ((text (markup-option n :text)))
		 (output (or text (markup-body n)) e)))
   :after " }")

;*---------------------------------------------------------------------*/
;*    mark ... @label mark@                                            */
;*---------------------------------------------------------------------*/
(markup-writer 'mark
   :action (lambda (n e)
	     (if (markup-ident n)
		 (begin
		   (display "{ @SkribiloMark { ")
		   (display (lout-tagify (markup-ident n)))
		   (display " } }"))
		 (skribe-error 'lout "mark: Node has no identifier" n))))

(define (lout-page-of ident)
  ;; Return a string for the `@PageOf' statement for `ident'.
  (let ((tag (lout-tagify ident)))
    (string-append ", { " tag " } @CrossLink { "
		   "p. @PageOf { " tag " } }")))


;*---------------------------------------------------------------------*/
;*    ref ... @label ref@                                              */
;*---------------------------------------------------------------------*/
(markup-writer 'ref
   :options '(:text :page text kind
              :chapter :section :subsection :subsubsection
	      :figure :mark :handle :ident)

   :action (lambda (n e)
             ;; A handle to the target is passed as the body of each `ref'
             ;; instance (see `package/base.scm').
	     (let ((kind           (markup-option n 'kind))
		   (text           (markup-option n :text))
		   (show-page-num? (markup-option n :page))
                   (target         (handle-ast (markup-body n))))

               (let ((ident (markup-ident target)))
                 (lout-debug "ref: target=~a ident=~a" target ident)

                 (if text (output text e))

                 (if (and (eq? kind 'mark) ident show-page-num?)

                     ;; Marks don't have a number.
                     (format #t (lout-page-of ident))

                     ;; Don't output a section/whatever number when text is
                     ;; provided in order to be consistent with the HTML
                     ;; back-end.  Sometimes (e.g., for user-defined
                     ;; markups), we don't even know how to reference them
                     ;; anyway.
                     (if (not text)
                         (let ((number (if (eq? kind 'figure)
                                           (markup-option target :number)
                                           (markup-number-string target))))
                           (display " ")
                           (display number))
                         (if (and ident show-page-num?)
                             (format #t (lout-page-of ident)))))))))

;*---------------------------------------------------------------------*/
;*    lout-make-url-breakable ...                                      */
;*---------------------------------------------------------------------*/
(define lout-make-url-breakable
  ;; Make the given string (which is assumed to be a URL) breakable.
  (make-string-replace `((#\/ "\"/\"&0ik{}")
                         (#\. ".&0ik{}")
                         (#\- "-&0ik{}")
                         (#\_ "_&0ik{}")
                         (#\@ "\"@\"&0ik{}")
                         ,@lout-verbatim-encoding
                         (#\newline " "))))

;*---------------------------------------------------------------------*/
;*    url-ref ...                                                      */
;*---------------------------------------------------------------------*/
(markup-writer 'url-ref
   :options '(:url :text)
   :action (lambda (n e)
	     (let ((url (markup-option n :url))
		   (text (markup-option n :text))
		   (transform (engine-custom e 'transform-url-ref-proc)))
	       (if (or (not transform)
		       (markup-option n '&transformed))
		   (begin
		     (format #t "{ \"~a\" @ExternalLink { " url)
		     (if text
                         (output text e)
                         (display (lout-make-url-breakable url) e))
		     (display " } }"))
		   (begin
		     (markup-option-add! n '&transformed #t)
		     (output (transform n) e))))))

;*---------------------------------------------------------------------*/
;*    &the-bibliography ...                                            */
;*---------------------------------------------------------------------*/
(markup-writer '&the-bibliography
   :before (lambda (n e)
             (display "\n# the-bibliography\n@LP\n")

             (case (markup-option n 'labels)
               ((number)
                ;; Compute the length (in characters) of the longest entry
                ;; label so that the label width of the list is adjusted.
                (let loop ((entries (markup-body n))
                           (label-width 0))
                  (if (null? entries)
                      ;; usually, the tag with be something like "[7]", hence
                      ;; the `+ 1' below (`[]' is narrower than 2f)
                      (format #t "@TaggedList labelwidth { ~af }\n"
                               (+ 1 label-width))
                      (loop (cdr entries)
                            (let ((entry-length
                                   (let liip ((e (car entries)))
                                     (cond
                                      ((markup? e)
                                       (cond ((is-markup? e '&bib-entry)
                                              (liip (markup-option e :title)))
                                             ((is-markup? e '&bib-entry-ident)
                                              (liip (markup-option e 'number)))
                                             (else
                                              (liip (markup-body e)))))
                                      ((string? e)
                                       (string-length e))
                                      ((number? e)
                                       (liip (number->string e)))
                                      ((list? e)
                                       (apply + (map liip e)))
                                      (else 0)))))

                              (if (> label-width entry-length)
                                  label-width
                                  entry-length))))))

               (else  ;; `name+year' and others.
                (display "@TaggedList\n"))))

   :after (lambda (n e)
	     (display "\n@EndList # the-bibliography (end)\n")))

;*---------------------------------------------------------------------*/
;*    &bib-entry ...                                                   */
;*---------------------------------------------------------------------*/
(markup-writer '&bib-entry
   :options '(:title)

   :before (lambda (n e)
             (let ((ident (markup-option n :title)))
               (if (is-markup? ident '&bib-entry-ident)
                   (let ((number (markup-option ident 'number)))
                     (cond ((number? number)
                            (display "@TagItem "))
                           (else
                            ;; probably `name+year'-style.
                            (display "@DropTagItem "))))
                   (display "@TagItem "))))

   :action (lambda (n e)
	     (display " { ")
	     (output n e (markup-writer-get '&bib-entry-label e))
	     (display " }  { ")
	     (output n e (markup-writer-get '&bib-entry-body e))
	     (display " }"))

   :after "\n")

;*---------------------------------------------------------------------*/
;*    &bib-entry-title ...                                             */
;*---------------------------------------------------------------------*/
(markup-writer '&bib-entry-title
   :action (lambda (n e)
	      (let* ((t (markup-body n))
		     (en (handle-ast (ast-parent n)))
		     (url (markup-option en 'url))
		     (ht (if url (ref :url (markup-body url) :text t) t)))
		 (evaluate-document ht e))))

;*---------------------------------------------------------------------*/
;*    &bib-entry-label ...                                             */
;*---------------------------------------------------------------------*/
(markup-writer '&bib-entry-label
   :options '(:title)
   :before " \"[\""
   :action (lambda (n e) (output (markup-option n :title) e))
   :after "\"]\" ")

;*---------------------------------------------------------------------*/
;*    &bib-entry-url ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer '&bib-entry-url
   :action (lambda (n e)
	      (let* ((en (handle-ast (ast-parent n)))
		     (url (markup-option en 'url))
		     (t (it (markup-body url))))
		 (evaluate-document (ref :url (markup-body url) :text t) e))))

;*---------------------------------------------------------------------*/
;*    &the-index-header ...                                            */
;*---------------------------------------------------------------------*/
(markup-writer '&the-index-header
   :action (lambda (n e)
	      (display "@Center { ") ;; FIXME:  Needs to be rewritten.
	      (for-each (lambda (h)
			   (let ((f (engine-custom e 'index-header-font-size)))
			      (if f
				  (evaluate-document (font :size f (bold (it h))) e)
				  (output h e))
			      (display " ")))
			(markup-body n))
	      (display " }")
	      (evaluate-document (linebreak 2) e)))

;*---------------------------------------------------------------------*/
;*    &source-comment ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer '&source-comment
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-comment-color))
		     (n1 (it (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-line-comment ...                                         */
;*---------------------------------------------------------------------*/
(markup-writer '&source-line-comment
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-comment-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-keyword ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer '&source-keyword
   :action (lambda (n e)
	      (evaluate-document (bold (markup-body n)) e)))

;*---------------------------------------------------------------------*/
;*    &source-define ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer '&source-define
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-define-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-module ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer '&source-module
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-module-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-markup ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer '&source-markup
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-markup-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-thread ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer '&source-thread
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-thread-color))
		     (n1 (bold (markup-body n)))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-string ...                                               */
;*---------------------------------------------------------------------*/
(markup-writer '&source-string
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-string-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     n1)))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-bracket ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer '&source-bracket
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-bracket-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc (bold n1))
			     (it n1))))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-type ...                                                 */
;*---------------------------------------------------------------------*/
(markup-writer '&source-type
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-type-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc n1)
			     (it n1))))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-key ...                                                  */
;*---------------------------------------------------------------------*/
(markup-writer '&source-key
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-type-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg cc (bold n1))
			     (it n1))))
		 (evaluate-document n2 e))))

;*---------------------------------------------------------------------*/
;*    &source-bracket ...                                              */
;*---------------------------------------------------------------------*/
(markup-writer '&source-bracket
   :action (lambda (n e)
	      (let* ((cc (engine-custom e 'source-type-color))
		     (n1 (markup-body n))
		     (n2 (if (and (engine-custom e 'source-color) cc)
			     (color :fg "red" (bold n1))
			     (bold n1))))
		 (evaluate-document n2 e))))


;*---------------------------------------------------------------------*/
;*    Illustrations                                                    */
;*---------------------------------------------------------------------*/
(define (lout-illustration . args)
  ;; FIXME: This should be a markup.

  ;; Introduce a Lout illustration (such as a diagram) whose code is either
  ;; the body of `lout-illustration' or the contents of `file'.  For engines
  ;; other than Lout, an EPS file is produced and then converted if needed.
  ;; The `:alt' option is equivalent to HTML's `alt' attribute for the `img'
  ;; markup, i.e. it is passed as the body of the `image' markup for
  ;; non-Lout back-ends.

  (define (file-contents file)
    ;; Return the contents (a string) of file `file'.
    (with-input-from-file file
      (lambda ()
	(let loop ((contents "")
		   (line (read-line)))
	  (if (eof-object? line)
	      contents
	      (loop (string-append contents line "\n")
		    (read-line)))))))

  (define (illustration-header)
    ;; Return a string denoting the header of a Lout illustration.
    (let ((lout (find-engine 'lout)))
      (string-append "@SysInclude { picture }\n"
		     (engine-custom lout 'includes)
		     "\n\n@Illustration\n"
		     "  @InitialFont { "
		     (engine-custom lout 'initial-font)
		     " }\n"
		     "  @InitialBreak { "
		     (engine-custom lout 'initial-break)
		     " }\n"
		     "  @InitialLanguage { "
		     (engine-custom lout 'initial-language)
		     " }\n"
		     "  @InitialSpace { tex }\n"
		     "{\n")))

  (define (illustration-ending)
    ;; Return a string denoting the end of a Lout illustration.
    "\n}\n")

  (let* ((opts (the-options args '(file ident alt)))
	 (file* (assoc ':file opts))
	 (ident* (assoc ':ident opts))
	 (alt* (assoc ':alt opts))
	 (file (and file* (cadr file*)))
	 (ident (and ident* (cadr ident*)))
	 (alt (or (and alt* (cadr alt*)) "An illustration")))

    (let ((contents (if (not file)
			(car (the-body args))
			(file-contents file))))
      (if (engine-format? "lout")
	  (! contents) ;; simply inline the illustration
	  (let* ((lout (find-engine 'lout))
		 (output (string-append (or ident
					    (symbol->string
					     (gensym "lout-illustration")))
					".eps"))
		 (port (open-output-pipe
			(string-append
                         (or (engine-custom lout 'lout-program-name)
                             "lout")
                         " -o " output
                         " -EPS "
                         (string-join
                          (engine-custom lout
                                         'lout-program-arguments))))))

	    ;; send the illustration to Lout's standard input
	    (display (illustration-header) port)
	    (display contents port)
	    (display (illustration-ending) port)

	    (let ((exit-val (status:exit-val (close-pipe port))))
	      (if (not (eqv? 0 exit-val))
		  (skribe-error 'lout-illustration
				"lout exited with error code" exit-val)))

	    (if (not (file-exists? output))
		(skribe-error 'lout-illustration "file not created"
			      output))

	    (let ((file-info (false-if-exception (stat output))))
	      (if (or (not file-info)
		      (= 0 (stat:size file-info)))
		  (skribe-error 'lout-illustration
				"empty output file" output)))

	    ;; the image (FIXME: Should set its location)
	    (image :file output alt))))))


;*---------------------------------------------------------------------*/
;*    Restore the base engine                                          */
;*---------------------------------------------------------------------*/
(pop-default-engine)


;; Local Variables: --
;; mode: Scheme --
;; scheme-program-name: "guile" --
;; End: --
