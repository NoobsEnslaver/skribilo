#!/bin/sh
# aside from this initial boilerplate, this is actually -*- scheme -*- code
main='(module-ref (resolve-module '\''(skribilo)) '\'main')'
exec ${GUILE-guile} --debug -l $0 -c "(apply $main (cdr (command-line)))" "$@"
!#

;;;; skribilo.scm
;;;;
;;;; Copyright � 2003-2004 Erick Gallesio - I3S-CNRS/ESSI <eg@unice.fr>
;;;; Copyright 2005, 2006  Ludovic Court�s <ludovic.courtes@laas.fr>
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
;;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
;;;; USA.

;;;; Commentary:
;;;;
;;;; Usage: skribilo [ARGS]
;;;;
;;;; Process a skribilo document.
;;;;
;;;; Code:



(define-module (skribilo)
  :autoload (skribilo module) (make-run-time-module)
  :autoload (skribilo engine) (*current-engine*)
  :use-module (skribilo utils syntax))

(use-modules (skribilo evaluator)
	     (skribilo debug)
	     (skribilo parameters)
	     (skribilo lib)

	     (srfi srfi-39)
	     (ice-9 optargs)
	     (ice-9 getopt-long))


;; Install the Skribilo module syntax reader.
(fluid-set! current-reader %skribilo-module-reader)

(if (not (keyword? :kw))
    (error "guile-reader sucks"))




(define* (process-option-specs longname
			       :key (alternate #f) (arg #f) (help #f)
			       :rest thunk)
  "Process STkLos-like option specifications and return getopt-long option
specifications."
  `(,(string->symbol longname)
    ,@(if alternate
	  `((single-char ,(string-ref alternate 0)))
	  '())
    (value ,(if arg #t #f))))

(define (raw-options->getopt-long options)
  "Converts @var{options} to a getopt-long-compatible representation."
  (map (lambda (option-specs)
	 (apply process-option-specs (car option-specs)))
       options))

(define-macro (define-options binding . options)
  `(define ,binding (quote ,(raw-options->getopt-long options))))

(define-options skribilo-options
  (("target" :alternate "t" :arg target
    :help "sets the output format to <target>")
   (set! engine (string->symbol target)))
  (("load-path" :alternate "I" :arg path :help "adds <path> to Skribe path")
   (set! paths (cons path paths)))
  (("bib-path" :alternate "B" :arg path :help "adds <path> to bibliography path")
   (skribe-bib-path-set! (cons path (skribe-bib-path))))
  (("S" :arg path :help "adds <path> to source path")
   (skribe-source-path-set! (cons path (skribe-source-path))))
  (("P" :arg path :help "adds <path> to image path")
   (skribe-image-path-set! (cons path (skribe-image-path))))
  (("split-chapters" :alternate "C" :arg chapter
    :help "emit chapter's sections in separate files")
   (set! *skribe-chapter-split* (cons chapter *skribe-chapter-split*)))
  (("preload" :arg file :help "preload <file>")
   (set! *skribe-preload* (cons file *skribe-preload*)))
  (("use-variant" :alternate "u" :arg variant
    :help "use <variant> output format")
   (set! *skribe-variants* (cons variant *skribe-variants*)))
  (("base" :alternate "b" :arg base
    :help "base prefix to remove from hyperlinks")
   (set! *skribe-ref-base* base))
  (("rc-dir" :arg dir :alternate "d" :help "set the RC directory to <dir>")
   (set! *skribe-rc-directory* dir))

  ;;"File options:"
  (("no-init-file" :help "Dont load rc Skribe file")
   (set! *load-rc* #f))
  (("output" :alternate "o" :arg file :help "set the output to <file>")
   (set! *skribe-dest* file)
   (let* ((s (file-suffix file))
	  (c (assoc s *skribe-auto-mode-alist*)))
     (if (and (pair? c) (symbol? (cdr c)))
	 (set! *skribe-engine* (cdr c)))))

  ;;"Misc:"
  (("help" :alternate "h" :help "provides help for the command")
   (arg-usage (current-error-port))
   (exit 0))
  (("options" :help "display the skribe options and exit")
   (arg-usage (current-output-port) #t)
   (exit 0))
  (("version" :alternate "V" :help "displays the version of Skribe")
   (version)
   (exit 0))
  (("query" :alternate "q"
    :help "displays informations about Skribe conf.")
   (query)
   (exit 0))
  (("verbose" :alternate "v" :arg level
    :help "sets the verbosity to <level>. Use -v0 for crystal silence")
   (let ((val (string->number level)))
     (if (integer? val)
	 (set! *skribe-verbose* val))))
  (("warning" :alternate "w" :arg level
    :help "sets the verbosity to <level>. Use -w0 for crystal silence")
   (let ((val (string->number level)))
     (if (integer? val)
	 (set! *skribe-warning* val))))
  (("debug" :alternate "g" :arg level :help "sets the debug <level>")
   (let ((val (string->number level)))
     (if (integer? val)
	 (set-skribe-debug! val)
	 (begin
	   ;; Use the symbol for debug
	   (set-skribe-debug!	    1)
	   (add-skribe-debug-symbol (string->symbol level))))))
  (("no-color" :help "disable coloring for output")
   (no-debug-color))
  (("custom" :alternate "c" :arg key=val :help "Preset custom value")
   (let ((args (string-split key=val "=")))
     (if (and (list args) (= (length args) 2))
	 (let ((key (car args))
	       (val (cadr args)))
	   (set! *skribe-precustom* (cons (cons (string->symbol key) val)
					  *skribe-precustom*)))
	 (error 'parse-arguments "Bad custom ~S" key=val))))
  (("eval" :alternate "e" :arg expr :help "evaluate expression <expr>")
   (with-input-from-string expr
      (lambda () (eval (read))))))


; (define skribilo-options
;   ;; Skribilo options in getopt-long's format, as computed by
;   ;; `raw-options->getopt-long'.
;   `((target (single-char #\t) (value #f))
;     (I (value #f))
;     (B (value #f))
;     (S (value #f))
;     (P (value #f))
;     (split-chapters (single-char #\C) (value #f))
;     (preload (value #f))
;     (use-variant (single-char #\u) (value #f))
;     (base (single-char #\b) (value #f))
;     (rc-dir (single-char #\d) (value #f))
;     (no-init-file (value #f))
;     (output (single-char #\o) (value #f))
;     (help (single-char #\h) (value #f))
;     (options (value #f))
;     (version (single-char #\V) (value #f))
;     (query (single-char #\q) (value #f))
;     (verbose (single-char #\v) (value #f))
;     (warning (single-char #\w) (value #f))
;     (debug (single-char #\g) (value #f))
;     (no-color (value #f))
;     (custom (single-char #\c) (value #f))
;     (eval (single-char #\e) (value #f))))


(define (skribilo-show-help)
  (format #t "Usage: skribilo [OPTIONS] [INPUT]

Processes a Skribilo/Skribe source file and produces its output.

  --target=ENGINE  Use ENGINE as the underlying engine

  --help           Give this help list
  --version        Print program version
~%"))

(define (skribilo-show-version)
  (format #t "skribilo ~a~%" (skribilo-release)))

;;;; ======================================================================
;;;;
;;;;				P A R S E - A R G S
;;;;
;;;; ======================================================================
(define (parse-args args)

  (define (version)
    (format #t "skribe v~A\n" (skribe-release)))

  (define (query)
    (version)
    (for-each (lambda (x)
		(let ((s (keyword->string (car x))))
		  (printf "  ~a: ~a\n" s (cadr x))))
	      (skribe-configure)))

  ;;
  ;; parse-args starts here
  ;;
  (let ((paths '())
	(engine #f))
    (parse-arguments args
      "Usage: skribe [options] [input]"
      "General options:"
	(("target" :alternate "t" :arg target
		   :help "sets the output format to <target>")
	   (set! engine (string->symbol target)))
	(("I" :arg path :help "adds <path> to Skribe path")
	   (set! paths (cons path paths)))
	(("B" :arg path :help "adds <path> to bibliography path")
	   (skribe-bib-path-set! (cons path (skribe-bib-path))))
	(("S" :arg path :help "adds <path> to source path")
	   (skribe-source-path-set! (cons path (skribe-source-path))))
	(("P" :arg path :help "adds <path> to image path")
	   (skribe-image-path-set! (cons path (skribe-image-path))))
	(("split-chapters" :alternate "C" :arg chapter
			   :help "emit chapter's sections in separate files")
	   (set! *skribe-chapter-split* (cons chapter *skribe-chapter-split*)))
	(("preload" :arg file :help "preload <file>")
	 (set! *skribe-preload* (cons file *skribe-preload*)))
	(("use-variant" :alternate "u" :arg variant
			:help "use <variant> output format")
	  (set! *skribe-variants* (cons variant *skribe-variants*)))
	(("base" :alternate "b" :arg base
		 :help "base prefix to remove from hyperlinks")
	   (set! *skribe-ref-base* base))
	(("rc-dir" :arg dir :alternate "d" :help "set the RC directory to <dir>")
	   (set! *skribe-rc-directory* dir))

      "File options:"
	(("no-init-file" :help "Dont load rc Skribe file")
	   (set! *load-rc* #f))
	(("output" :alternate "o" :arg file :help "set the output to <file>")
	   (set! *skribe-dest* file)
	   (let* ((s (file-suffix file))
		  (c (assoc s *skribe-auto-mode-alist*)))
	     (if (and (pair? c) (symbol? (cdr c)))
	       (set! *skribe-engine* (cdr c)))))

      "Misc:"
	(("help" :alternate "h" :help "provides help for the command")
	   (arg-usage (current-error-port))
	   (exit 0))
	(("options" :help "display the skribe options and exit")
	   (arg-usage (current-output-port) #t)
	   (exit 0))
	(("version" :alternate "V" :help "displays the version of Skribe")
	   (version)
	   (exit 0))
	(("query" :alternate "q"
		  :help "displays informations about Skribe conf.")
	   (query)
	   (exit 0))
	(("verbose" :alternate "v" :arg level
	  :help "sets the verbosity to <level>. Use -v0 for crystal silence")
	   (let ((val (string->number level)))
	     (if (integer? val)
	       (set! *skribe-verbose* val))))
	(("warning" :alternate "w" :arg level
	  :help "sets the verbosity to <level>. Use -w0 for crystal silence")
	   (let ((val (string->number level)))
	     (if (integer? val)
	       (set! *skribe-warning* val))))
	(("debug" :alternate "g" :arg level :help "sets the debug <level>")
	   (let ((val (string->number level)))
	     (if (integer? val)
		 (set-skribe-debug! val)
		 (begin
		   ;; Use the symbol for debug
		   (set-skribe-debug!	    1)
		   (add-skribe-debug-symbol (string->symbol level))))))
	(("no-color" :help "disable coloring for output")
	 (no-debug-color))
	(("custom" :alternate "c" :arg key=val :help "Preset custom value")
	   (let ((args (string-split key=val "=")))
	     (if (and (list args) (= (length args) 2))
		 (let ((key (car args))
		       (val (cadr args)))
		   (set! *skribe-precustom* (cons (cons (string->symbol key) val)
						  *skribe-precustom*)))
		 (error 'parse-arguments "Bad custom ~S" key=val))))
	(("eval" :alternate "e" :arg expr :help "evaluate expression <expr>")
	   (with-input-from-string expr
	     (lambda () (eval (read)))))
	(else
	 (set! *skribe-src* other-arguments)))

    ;; we have to configure Skribe path according to the environment variable
    (skribe-path-set! (append (let ((path (getenv "SKRIBEPATH")))
				(if path
				    (string-split path ":")
				    '()))
			      (reverse! paths)
			      (skribe-default-path)))
    ;; Final initializations
    (if engine
      (set! *skribe-engine* engine))))

;;;; ======================================================================
;;;;
;;;;				   L O A D - R C
;;;;
;;;; ======================================================================
(define *load-rc* #f)  ;; FIXME:  This should go somewhere else.

(define (load-rc)
  (if *load-rc*
    (let ((file (make-path (*rc-directory*) (*rc-file*))))
      (if (and file (file-exists? file))
	(load file)))))


;;;; ======================================================================
;;;;
;;;;				      S K R I B E
;;;;
;;;; ======================================================================
; (define (doskribe)
;    (let ((e (find-engine *skribe-engine*)))
;      (if (and (engine? e) (pair? *skribe-precustom*))
; 	 (for-each (lambda (cv)
; 		     (engine-custom-set! e (car cv) (cdr cv)))
; 		   *skribe-precustom*))
;      (if (pair? *skribe-src*)
; 	 (for-each (lambda (f) (skribe-load f :engine *skribe-engine*))
; 		   *skribe-src*)
; 	 (skribe-eval-port (current-input-port) *skribe-engine*))))

(define *skribilo-output-port* (make-parameter (current-output-port)))

(define (doskribe)
  (let ((output-port (current-output-port))
	(user-module (current-module)))
    (dynamic-wind
	(lambda ()
	  ;; FIXME: Using this technique, anything written to `stderr' will
	  ;; also end up in the output file (e.g. Guile warnings).
	  (set-current-output-port (*skribilo-output-port*))
	  (set-current-module (make-run-time-module)))
	(lambda ()
	  ;;(format #t "engine is ~a~%" (*current-engine*))
	  (skribe-eval-port (current-input-port) (*current-engine*)))
	(lambda ()
	  (set-current-output-port output-port)
	  (set-current-module user-module)))))



;;;; ======================================================================
;;;;
;;;;				      M A I N
;;;;
;;;; ======================================================================
(define-public (skribilo . args)
  (let* ((options           (getopt-long (cons "skribilo" args)
					 skribilo-options))
	 (engine            (string->symbol
			     (option-ref options 'target "html")))
	 (output-file       (option-ref options 'output #f))
	 (debugging-level   (option-ref options 'debug "0"))
	 (warning-level     (option-ref options 'warning "2"))
	 (load-path         (option-ref options 'load-path "."))
	 (bib-path          (option-ref options 'bib-path "."))
	 (preload           '())
	 (variants          '())

	 (help-wanted       (option-ref options 'help #f))
	 (version-wanted    (option-ref options 'version #f)))

    ;; Set up the debugging infrastructure.
    (debug-enable 'debug)
    (debug-enable 'backtrace)
    (debug-enable 'procnames)

    (cond (help-wanted    (begin (skribilo-show-help) (exit 1)))
	  (version-wanted (begin (skribilo-show-version) (exit 1))))

    ;; Parse the most important options.

    (set-skribe-debug! (string->number debugging-level))

    (if (> (skribe-debug) 4)
	(set! %load-hook
	      (lambda (file)
		(format #t "~~ loading `~a'...~%" file))))

    (parameterize ((*current-engine* engine)
		   (*document-path*  (cons load-path (*document-path*)))
		   (*bib-path*       (cons bib-path (*bib-path*)))
		   (*warning*        (string->number warning-level))
		   (*verbose*        (let ((v (option-ref options
							  'verbose 0)))
				       (if (number? v) v
					   (if v 1 0)))))

      ;; Load the user rc file
      ;;(load-rc)

      (for-each (lambda (f)
		  (skribe-load f :engine (*current-engine*)))
		preload)

      ;; Load the specified variants.
      (for-each (lambda (x)
		  (skribe-load (format #f "~a.skr" x)
			       :engine (*current-engine*)))
		(reverse! variants))

      (let ((files (option-ref options '() '())))

	(if (> (length files) 2)
	    (error "you can specify at most one input file and one output file"
		   files))

	(let* ((source-file (if (null? files) #f (car files))))

	  (if (and output-file (file-exists? output-file))
	      (delete-file output-file))

	  (parameterize ((*destination-file* output-file)
			 (*source-file*      source-file)
			 (*skribilo-output-port*
			  (if (string? output-file)
			      (open-output-file output-file)
			      (current-output-port))))

	    ;;	(start-stack 7
	    (if source-file
		(with-input-from-file source-file doskribe)
		(doskribe))))))))


(define main skribilo)

;;; skribilo ends here.
