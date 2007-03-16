;;; diff.scm  --  A document difference highlighting package.
;;;
;;; Copyright 2007  Ludovic Court�s <ludovic.courtes@laas.fr>
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

(define-module (skribilo package diff)
  :use-module (differ)
  :use-module (srfi srfi-1)
  :use-module (srfi srfi-39)
  :use-module (ice-9 optargs)

  :use-module (skribilo ast)
  :use-module (skribilo lib)
  :autoload   (skribilo reader)        (*document-reader*)
  :autoload   (skribilo engine)        (*current-engine*)
  :autoload   (skribilo module)        (make-run-time-module)
  :autoload   (skribilo resolve)       (resolve!)
  :autoload   (skribilo evaluator)     (evaluate-ast-from-port)
  :autoload   (skribilo biblio)        (*bib-table* make-bib-table)
  :use-module (skribilo package base)
  :use-module (skribilo utils syntax)

  :export (make-diff-document
           make-diff-document-from-files))

(fluid-set! current-reader %skribilo-module-reader)

;;; Author: Ludovic Court�s
;;;
;;; Commentary:
;;;
;;; This package provides facilities to automatically produce documents where
;;; changes from a previous version of the document are highlighted.
;;;
;;; Warning: This is very experimental at this stage!
;;;
;;; Code:



;;;
;;; Markup.
;;;

(define-markup (deletion :rest args)
  (color :fg "red" (symbol "middot")))

(define-markup (insertion :rest args)
  (color :fg "green" args))

(define-markup (replacement :rest args)
  (color :fg "orange" args))

(define-markup (unchanged :rest args)
  args)


;;;
;;; Helpers for string diffs.
;;;

(define (coalesce-edits edits)
  ;; Coalesce EDITS (an array of edits as returned by `diff:edits') into a
  ;; list of contiguous changes, each change being denoted by `(CHANGE-KIND
  ;; START END)' where CHANGE-KIND is one of `deletion', `insertion' or
  ;; `replacement'.
  (define (do-coalesce edit-kind edit result)
    (cond ((null? result)
           `((,edit-kind ,edit ,edit)))
          ((eq? (caar result) edit-kind)
           (let ((start (cadr  (car result)))
                 (end   (caddr (car result))))
             (if (= edit (+ end 1))
                 (cons `(,edit-kind ,start ,edit)
                       (cdr result))
                 (cons `(,edit-kind ,edit ,edit)
                       result))))
          (else
           (let ((start (cadr  (car result)))
                 (end   (caddr (car result))))
             (if (and (= start end edit)
                      (not (eq? (caar result) 'replacement)))
                 (do-coalesce 'replacement edit (cdr result))
                 (cons `(,edit-kind ,edit ,edit)
                       result))))))

  (reverse! (fold (lambda (edit result)
                    (if (negative? edit)
                        (let ((edit (- -1 edit)))
                          (do-coalesce 'deletion edit result))
                        (let ((edit (- edit 1)))
                          (do-coalesce 'insertion edit result))))
                  '()
                  (array->list edits))))

(define (add-unchanged edits str-len)
  ;; Add information about unchanged regions to EDITS, a list returned by
  ;; `coalesce-edits'.  STR-LEN should be the length of the _target_ string,
  ;; i.e., the second argument of `diff:edits'.
  (define (coalesce-unchanged start end result)
    (if (null? result)
        `((unchanged ,start ,end))
        (let ((prev-unchanged? (eq? (caar result) 'unchanged))
              (prev-start      (cadr (car result)))
              (prev-end        (caddr (car result))))
          (if prev-unchanged?
              (cons `(unchanged ,prev-start ,end)
                    (cdr result))
              (cons `(unchanged ,start ,end)
                    result)))))

  (let loop ((edits   edits)
             (result  '())
             (str-pos 0))
    (if (null? edits)
        (reverse! (if (< str-pos (- str-len 1))
                      (cons (list 'unchanged str-pos (- str-len 1))
                            result)
                      result))
        (let* ((change (car edits))
               (kind  (car change))
               (start (cadr change))
               (end   (caddr change)))

          (loop (cdr edits)
                (if (memq kind '(insertion replacement))
                    (if (> start str-pos)
                        (cons change
                              (coalesce-unchanged str-pos (- start 1)
                                                  result))
                        (cons change result))
                    (cons change result))
                (if (eq? kind 'deletion)
                    str-pos ;; deletion doesn't change string position
                    (+ end 1)))))))

(define (string-diff-sequences str1 str2)
  ;; Return a "diff sequence" between STR1 and STR2.  The diff sequence is
  ;; alist of 3-element list whose car represent a diff type (a symbol,
  ;; either `unchanged', `replacement', `insertion', or `deletion') and two
  ;; integers denoting where the change took place.  These two integers are
  ;; an indices in STR1 in the case of `deletion', indices in STR2 otherwise.
  (add-unchanged (coalesce-edits (diff:edits str1 str2))
                 (string-length str2)))



;;;
;;; AST diffing.
;;;

(define %undiffable-markups
  ;; List of markups to not diff.
  '(ref url-ref bib-ref bib-ref+ line-ref unref numref
    eq     ;; XXX: not supported because of the `eq-evaluate' thing
    figref ;; non-standard
    mark
    image symbol lout-illustration
    &the-bibliography
    toc
    index &index-entry &the-index &the-index-header))

(define (annotated-string-diff str1 str2)
  ;; Return a list (actually an AST) denoting the differences between STR1
  ;; and STR2.  The returned text is actually that of STR2 augmented with
  ;; `insertion', `deletion', `replacement', and `unchanged' markup.
  (reverse!
   (fold (lambda (edit result)
           (let ((start (cadr edit))
                 (end   (+ 1 (caddr edit))))
             (cons (case (car edit)
                     ((insertion)
                      (insertion (substring str2 start end)))
                     ((deletion)
                      (deletion  (substring str1 start end)))
                     ((replacement)
                      (replacement (substring str2 start end)))
                     ((unchanged)
                      (unchanged (substring str2 start end))))
                   result)))
         '()
         (string-diff-sequences str1 str2))))

(define (make-diff-document ast1 ast2)
  ;; Return a document based on AST2 that highlights differences between AST1
  ;; and AST2, enclosing unchanged parts in `unchanged' markups, etc.  AST2
  ;; is used as the "reference" tree, thus changes from AST1 to AST2 are
  ;; shown in the resulting document.
  (define (undiffable? kind)
    (memq kind %undiffable-markups))

  (let loop ((ast1 ast1)
             (ast2 ast2))
    ;;(format (current-error-port) "diff: ~a ~a~%" ast1 ast2)
    (cond ((string? ast2)
           (if (string? ast1)
               (annotated-string-diff ast1 ast2)
               (insertion ast2)))

          ((document? ast2)
           (let ((ident (or (markup-ident ast2)
                            (ast->string (markup-option ast2 :title))
                            (symbol->string (gensym "document"))))
                 (opts  (markup-options ast2))
                 (class (markup-class ast2))
                 (body  (markup-body ast2)))
             (new document
                  (markup 'document)
                  (ident ident)
                  (class class)
                  (options opts)
                  (body (loop (if (markup? ast1)
                                  (markup-body ast1)
                                  ast1)
                              body))
                  (env (list (list 'chapter-counter 0) (list 'chapter-env '())
                             (list 'section-counter 0) (list 'section-env '())
                             (list 'footnote-counter 0)
                             (list 'footnote-env '())
                             (list 'figure-counter 0)
                             (list 'figure-env '()))))))

          ((container? ast2)
           (let ((kind  (markup-markup ast2))
                 (ident (markup-ident ast2))
                 (opts  (markup-options ast2))
                 (class (markup-class ast2))
                 (body  (markup-body ast2)))
             (new container
                  (markup  kind)
                  (ident   ident)
                  (class   class)
                  (options opts)
                  (body (if (undiffable? kind)
                            body
                            (loop (if (and (container? ast1)
                                           (is-markup? ast1 kind))
                                      (markup-body ast1)
                                      ast1)
                                  body))))))

          ((markup? ast2)
           (let ((kind  (markup-markup ast2))
                 (ident (markup-ident ast2))
                 (opts  (markup-options ast2))
                 (class (markup-class ast2))
                 (body  (markup-body ast2)))
             (new markup
                  (markup  kind)
                  (ident   ident)
                  (class   class)
                  (options opts)
                  (body (if (undiffable? kind)
                            body
                            (loop (if (is-markup? ast1 kind)
                                      (markup-body ast1)
                                      ast1)
                                  body))))))

          ((list? ast2)
           (if (list? ast1)
               (let liip ((ast1 ast1)
                          (ast2 ast2)
                          (result '()))
                 (if (null? ast2)
                     (reverse! result)
                     (liip (if (null? ast1) ast1 (cdr ast1))
                           (cdr ast2)
                           (cons (loop (if (null? ast1) #f (car ast1))
                                       (car ast2))
                                 result))))
               (map (lambda (x)
                      (loop ast1 x))
                    ast2)))

          ((equal? ast1 ast2)
           (unchanged ast1))

          (else
           (insertion ast2)))))



;;;
;;; Public API.
;;;

(define* (make-diff-document-from-files old-file new-file
                                        :key (reader (*document-reader*))
                                             (env '())
                                             (engine (*current-engine*)))
  ;; Return a document similar to NEW-FILE, where differences from OLD-FILE
  ;; are highlighted.
  (let ((ast1
         (parameterize ((*bib-table* (make-bib-table 'doc-1)))
           (evaluate-ast-from-port (open-input-file old-file)
                                   :reader reader
                                   :module (make-run-time-module))))
        (~~ (skribe-message "diff: first document loaded~%"))
        (ast2
         (parameterize ((*bib-table* (make-bib-table 'doc-2)))
           (evaluate-ast-from-port (open-input-file new-file)
                                   :reader reader
                                   :module (make-run-time-module))))
        (%% (skribe-message "diff: second document loaded~%")))

    (resolve! ast1 engine env)
    (resolve! ast2 engine env)
    (make-diff-document ast1 ast2)))

;;; diff.scm ends here

;;; arch-tag: 69ad10fa-5688-4835-8956-439e44e26847
