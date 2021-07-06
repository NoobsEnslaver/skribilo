;;; skribilo.scm  --  The Skribilo document processor.
;;;
;;; Copyright © 2021 Arun Isaac <arunisaac@systemreboot.net>
;;;
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

(require 'scheme)

(defconst skribilo-font-lock-keywords
  (list (cons (rx "(" (group (or "document" "chapter" "code"
                                 "section" "subsection" "subsubsection"
                                 "prog" "p" "ref")))
              1)))

(defun skribilo-innermost-parens-start (state)
  "Return the position of the innermost open parenthesis. STATE
is a parser state object as returned by `parse-partial-sexp'."
  (elt state 1))

(defun skribilo-open-parens-positions (state)
  "Return the positions of the currently open parentheses,
starting with the outermost. STATE is a parser state object as
returned by `parse-partial-sexp'. See \"(elisp) Parser state\"."
  (elt state 9))

(defun skribilo-sexp-head (state)
  "Return the first symbol of the innermost sexp. STATE is a
parser state object as returned by `parse-partial-sexp'."
  (save-excursion
    (goto-char (skribilo-innermost-parens-start state))
    (forward-char)
    (intern-soft
     (buffer-substring-no-properties
      (point)
      (progn (forward-sexp) (point))))))

(defun skribilo-indent-function (indent-point state)
  (let ((property (get (skribilo-sexp-head state)
                       'skribilo-indent-function)))
    (cond
     ;; If within square brackets, don't indent.
     ((seq-some (lambda (position)
                  (eq (char-after position)
                      ?\[))
                (skribilo-open-parens-positions state))
      0)
     ;; Like `scheme-indent-function', but use the
     ;; 'skribilo-indent-function property instead of the
     ;; 'scheme-indent-function property.
     ((eq property 'defun)
      (lisp-indent-defform state indent-point))
     ((integerp property)
      (lisp-indent-specform method state indent-point (current-column)))
     ((functionp property)
      (funcall property state indent-point (current-column)))
     ;; Else, pass on control to `scheme-indent-function'.
     (t
      (scheme-indent-function indent-point state)))))

(defun skribilo-keywords-in-sexp ()
  "Return the number of keywords in the sexp currently at
point. The point must be on the opening parenthesis at the
beginning of the sexp."
  ;; The [] construct in skribilo isn't a proper sexp in the sense
  ;; understood by `read'. So, we can't simply use `sexp-at-point' to
  ;; read the whole sexp and then count the keywords.
  (save-excursion
    ;; TODO: What if there is whitespace after the opening
    ;; parenthesis?
    ;; Move into the sexp.
    (forward-char)
    ;; Go to the end of the first sub-sexp.
    (forward-sexp)
    ;; Move past one sub-sexp and increment result if that sub-sexp is
    ;; a keyword.
    (let ((result 0))
      (while (ignore-error 'scan-error
               (or (forward-sexp) t))
        (when (keywordp (sexp-at-point))
          (setq result (1+ result))))
      result)))

(defun skribilo-indent-form (state indent-point normal-indent)
  (lisp-indent-specform
   (* 2
      (save-excursion
        (goto-char (skribilo-innermost-parens-start state))
        (skribilo-keywords-in-sexp)))
   state indent-point normal-indent))

(define-minor-mode skribilo-mode
  "Minor mode for editing Skribilo sources."
  nil nil nil
  (setq-local lisp-indent-function 'skribilo-indent-function)
  (mapc (lambda (symbol)
          (put symbol 'skribilo-indent-function 'skribilo-indent-form))
        '(document chapter section subsection subsubsection))
  (font-lock-add-keywords nil skribilo-font-lock-keywords)
  (font-lock-flush))

(provide 'skribilo)
