;;; -*- coding: utf-8; tab-width: 4; c-basic-offset: 2; indent-tabs-mode: nil; -*-
;;; Replacement of the built-in coloring and framing in the latex engine with
;;; the ones provided by the minted package. Just include module.
;;:
;;; This file is part of Skribilo.
;;;
;;; Skribilo is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; Skribilo is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Skribilo.  If not, see <http://www.gnu.org/licenses/>.

(define-module (skribilo package minted)
  #:export (skribe scheme stklos bigloo lisp c c-language java minted-lang)
  #:use-module (skribilo engine)
  #:use-module (skribilo ast)
  #:use-module ((skribilo condition)        :select (invalid-argument-error))
  #:use-module ((skribilo utils strings)    :select (opt-format))
  #:use-module ((skribilo lib)              :select (new))
  #:use-module ((skribilo output)           :select (output))
  #:use-module ((skribilo writer)           :select (markup-writer-get writer-before writer-after writer-action))
  #:use-module ((skribilo source)           :select (<language> language-extractor language-fontifier))
  #:use-module ((oop goops)                 :select (make slot-set!))
  #:use-module ((skribilo parameters)       :select (*destination-file*))
  #:use-module ((skribilo source lisp)      :renamer (symbol-prefix-proc 'old:))
  #:use-module ((skribilo source c)         :renamer (symbol-prefix-proc 'old:))
  #:use-module ((skribilo utils syntax)     :select (skribilo-module-syntax)))

(skribilo-module-syntax)

(define is-latex?
  (eq? 'latex (engine-ident (*current-engine*))))

(define (minted-fontifier name)
  (lambda (s)
    (new markup
         (markup 'source)
         (body (if (string-suffix? "\n" s)
                   s
                   (string-append s "\n")))
         (options `((:language ,name))))))

(define (minted-lang name)
  (make <language>
    :name name
    :fontifier (minted-fontifier name)
    :extractor #f))

(let* ((le (find-engine 'latex))
       (old-prog-writer (markup-writer-get 'prog le))
       (old-frame-writer (markup-writer-get 'frame le)))
  (define (opt-append key val)
    (if (string? (engine-custom le key))
        (engine-custom-set! le key (string-append "\n" (engine-custom le key) val "\n"))
        (engine-custom-set! le key val)))

  ;; -------------- configure packages and output dir ---------------
  (opt-append 'usepackage (opt-format '(outputdir) (list (engine-custom le 'minted-output-dir))
                                      "\\usepackage[~a]{minted}" #f))

  ;; -------------- edit default writers ---------------
  (slot-set! old-prog-writer 'action
             (lambda (n e)
               (let ((ne (make-engine
                          (gensym "latex")
                          :filter #f))
                     (sources (search-down
                               (lambda (x)
                                 (and (markup? x)
                                      (eq? (markup-markup x) 'source))) n)))
                 (when (null? sources)
                   (invalid-argument-error 'prog #f 'body:source:language))


                 (let ((line (markup-option n :line))
                       (extra (markup-option n :minted-opts))
                       (inline (markup-option n :inline)))

                   (if inline
                       (display "\\mintinline")
                       (display "\\begin{minted}"))
                   (cond
                    ((and (number? line) extra)
                     (format #t "[linenos, firstnumber=~a, ~a]" line extra))
                    ((and line extra)
                     (format #t "[linenos, ~a]" extra))
                    (extra
                     (format #t "[~a]" extra))
                    ((number? line)
                     (format #t "[linenos, firstnumber=~a]" line))
                    (line
                     (display "[linenos]"))
                    (else
                     (display "[]")))
                   (if inline
                       (begin
                         (format #t "{~a}{" (markup-option (car sources) :language))
                         (output (markup-body n) ne)
                         (display "}"))
                       (begin
                         (format #t "{~a}\n" (markup-option (car sources) :language))
                         (output (markup-body n) ne)
                         (format #t "\\end{minted}\n")))
                   ))))
  (slot-set! old-prog-writer 'after #f)
  (slot-set! old-prog-writer 'before #f)

  (let* ((old-frame-before* (writer-before old-frame-writer))
         (old-frame-action* (writer-action old-frame-writer))
         (old-frame-after*  (writer-after old-frame-writer))
         (old-frame-before (if (procedure? old-frame-before*)
                               old-frame-before*
                               (lambda (n e) old-frame-before*)))
         (old-frame-action (if (procedure? old-frame-action*)
                               old-frame-action*
                               (lambda (n e) old-frame-action*)))
         (old-frame-after (if (procedure? old-frame-after*)
                              old-frame-after*
                              (lambda (n e) old-frame-after*)))
         (child-is-only-prog? (lambda (n)
                                (and (container? n) (container-body n) (not (null? (container-body n)))
                                     (container? (car (container-body n)))
                                     (eq? 'prog (markup-markup (car (container-body n)))))))
         (new-frame-before
          (lambda (n e)
            (if (child-is-only-prog? n)
                (let* ((inner-prog (car (container-body n)))
                       (type* (markup-option n :minted-frame-type))
                       (type (if (or (string? type*) (symbol? type*))
                                 type*
                                 'single)))
                  (markup-option-add! inner-prog :minted-opts (format #f "frame=~a" type))
                  (output inner-prog e))
                (old-frame-before n e))))
         (new-frame-action
          (lambda (n e)
            (unless (child-is-only-prog? n)
              (old-frame-action n e))))
         (new-frame-after
          (lambda (n e)
            (unless (child-is-only-prog? n)
              (old-frame-after n e)))))

    (slot-set! old-frame-writer 'before new-frame-before)
    (slot-set! old-frame-writer 'action new-frame-action)
    (slot-set! old-frame-writer 'after new-frame-after)))

(define (derived-language name old)
  (make <language>
    :name name
    :fontifier (if is-latex?
                   (minted-fontifier name)
                   (language-fontifier old))
    :extractor (language-extractor old)))

(define scheme (derived-language 'scheme old:scheme))
(define skribe (derived-language 'skribe old:skribe))
(define stklos (derived-language 'stklos old:stklos))
(define bigloo (derived-language 'bigloo old:bigloo))
(define lisp   (derived-language 'lisp   old:lisp))
(define c      (derived-language 'c      old:c))
(define c-language c)
(define java   (derived-language 'java   old:java))
