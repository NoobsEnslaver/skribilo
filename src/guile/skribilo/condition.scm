;;; condition.scm  --  Skribilo SRFI-35 error condition hierarchy.
;;;
;;; Copyright 2006, 2007, 2008  Ludovic Court�s  <ludo@gnu.org>
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

(define-module (skribilo condition)
  :autoload   (srfi srfi-1)  (find)
  :autoload   (srfi srfi-34) (with-exception-handler)
  :use-module (srfi srfi-35)
  :use-module (srfi srfi-39)
  :autoload   (skribilo utils syntax) (_ N_)
  :export     (&skribilo-error skribilo-error?
	       &invalid-argument-error invalid-argument-error?
	       &too-few-arguments-error too-few-arguments-error?

	       &file-error file-error?
	       &file-search-error file-search-error?
	       &file-open-error file-open-error?
	       &file-write-error file-write-error?

	       register-error-condition-handler!
	       lookup-error-condition-handler

	       %call-with-skribilo-error-catch
	       call-with-skribilo-error-catch
               call-with-skribilo-error-catch/exit))

;;; Author:  Ludovic Court�s
;;;
;;; Commentary:
;;;
;;; Top-level of Skribilo's SRFI-35 error conditions.
;;;
;;; Code:


;;;
;;; Standard error conditions.
;;;

(define-condition-type &skribilo-error &error
  skribilo-error?)


;;;
;;; Generic errors.
;;;

(define-condition-type &invalid-argument-error &skribilo-error
  invalid-argument-error?
  (proc-name invalid-argument-error:proc-name)
  (argument  invalid-argument-error:argument))

(define-condition-type &too-few-arguments-error &skribilo-error
  too-few-arguments-error?
  (proc-name too-few-arguments-error:proc-name)
  (arguments too-few-arguments-error:arguments))


;;;
;;; File errors.
;;;

(define-condition-type &file-error &skribilo-error
  file-error?
  (file-name file-error:file-name))

(define-condition-type &file-search-error &file-error
  file-search-error?
  (path file-search-error:path))

(define-condition-type &file-open-error &file-error
  file-open-error?)

(define-condition-type &file-write-error &file-error
  file-write-error?)



;;;
;;; Adding new error conditions from other modules.
;;;

(define %external-error-condition-alist '())

(define (register-error-condition-handler! pred handler)
  (set! %external-error-condition-alist
	(cons (cons pred handler)
	      %external-error-condition-alist)))

(define (lookup-error-condition-handler c)
  (let ((pair (find (lambda (pair)
		      (let ((pred (car pair)))
			(pred c)))
		    %external-error-condition-alist)))
    (if (pair? pair)
	(cdr pair)
	#f)))



;;;
;;; Convenience functions.
;;;

(define (show-stack-trace)
  ;; Display a backtrace to stderr if possible.
  (let ((stack (make-stack #t)))
    (if stack
        (begin
          (format (current-error-port) "~%Call stack:~%")
          (display-backtrace stack (current-error-port)))
        (begin
          (format (current-error-port) (_ "Call stack trace not available.~%"))
          (format (current-error-port) (_ "Use `GUILE=\"guile --debug\" skribilo ...' for a detailed stack trace."))))))

(define (%call-with-skribilo-error-catch thunk exit exit-val)
  (with-exception-handler
   (lambda (c)
     (cond  ((invalid-argument-error? c)
	     (format (current-error-port)
                     (_ "in `~a': invalid argument: ~S~%")
		     (invalid-argument-error:proc-name c)
		     (invalid-argument-error:argument c))
             (show-stack-trace)
	     (exit exit-val))

	    ((too-few-arguments-error? c)
	     (format (current-error-port)
                     (_ "in `~a': too few arguments: ~S~%")
		     (too-few-arguments-error:proc-name c)
		     (too-few-arguments-error:arguments c))
             (show-stack-trace)
             (exit exit-val))

	    ((file-search-error? c)
	     (format (current-error-port)
                     (_ "~a: not found in path `~S'~%")
		     (file-error:file-name c)
		     (file-search-error:path c))
             (show-stack-trace)
	     (exit exit-val))

	    ((file-open-error? c)
	     (format (current-error-port)
                     (_ "~a: cannot open file~%")
		     (file-error:file-name c))
             (show-stack-trace)
	     (exit exit-val))

	    ((file-write-error? c)
	     (format (current-error-port)
                     (_ "~a: cannot write to file~%")
		     (file-error:file-name c))
             (show-stack-trace)
	     (exit exit-val))

	    ((file-error? c)
	     (format (current-error-port)
                     (_ "file error: ~a~%")
		     (file-error:file-name c))
             (show-stack-trace)
	     (exit exit-val))

	    ((skribilo-error? c)
	     (let ((handler (lookup-error-condition-handler c)))
	       (if (procedure? handler)
		   (handler c)
		   (format (current-error-port)
			   (_ "undefined skribilo error: ~S~%")
			   c)))
             (show-stack-trace)
	     (exit exit-val))

            ((message-condition? c)
             (format (current-error-port) (condition-message c))
             (show-stack-trace)
             (exit exit-val))))

   thunk))

(define-macro (call-with-skribilo-error-catch thunk)
  `(call/cc (lambda (cont)
	      (%call-with-skribilo-error-catch ,thunk cont #f))))

(define (call-with-skribilo-error-catch/exit thunk)
  (%call-with-skribilo-error-catch thunk primitive-exit 1))


;;; conditions.scm ends here
