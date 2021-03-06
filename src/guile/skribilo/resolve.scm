;;; resolve.scm  --  Skribilo reference resolution.
;;;
;;; Copyright 2005, 2006, 2008, 2009, 2018  Ludovic Court?s <ludo@gnu.org>
;;; Copyright 2003, 2004  Erick Gallesio - I3S-CNRS/ESSI <eg@unice.fr>
;;;
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

(define-module (skribilo resolve)
  #:use-module (skribilo debug)
  #:use-module (skribilo ast)
  #:use-module (skribilo utils syntax)

  #:use-module (oop goops)
  #:use-module (srfi srfi-39)

  #:use-module (skribilo condition)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-35)
  #:use-module (ice-9 match)

  #:export (resolve! resolve-search-parent
	   resolve-counter resolve-parent resolve-ident
	   *document-being-resolved*))

(skribilo-module-syntax)




;;;
;;; Resolving nodes.
;;;

;; The document being resolved.  Note: This is only meant to be used by the
;; compatibility layer in order to implement things like `find-markups'!
(define *document-being-resolved* (make-parameter #f))

(define *unresolved* (make-parameter #f))
(define-generic do-resolve!)


;;;; ======================================================================
;;;;
;;;; RESOLVE!
;;;;
;;;; This function iterates over an ast until all unresolved  references
;;;; are resolved.
;;;;
;;;; ======================================================================
(define (resolve! ast engine env)
  (with-debug 3 'resolve
     (debug-item "ast=" ast)

     (if (document? ast)
	 ;; Bind nodes prior to resolution so that unresolved nodes can
	 ;; lookup nodes by identifier using `document-lookup-node' or
	 ;; `resolve-ident'.
	 (document-bind-nodes! ast))

     (parameterize ((*unresolved* #f))
       (let Loop ((ast ast))
	 (*unresolved* #f)
	 (let ((ast (do-resolve! ast engine env)))
	   (if (*unresolved*)
	       (begin
		 (debug-item "iterating over ast " ast)
		 (Loop ast))
	       ast))))))

;;;; ======================================================================
;;;;
;;;;				D O - R E S O L V E !
;;;;
;;;; ======================================================================

(define-method (do-resolve! ast engine env)
  ast)


(define-method (do-resolve! (ast <pair>) engine env)
  (match ast
    ((? list?)                                    ;proper list
     (map (lambda (elt)
            (do-resolve! elt engine env))
          ast))
    ((head . tail)                                ;pair or improper list
     (cons (do-resolve! head engine env)
           (do-resolve! tail engine env)))))


(define-method (do-resolve! (node <node>) engine env)
  (if (ast-resolved? node)
      node
      (let ((body    (slot-ref node 'body))
	    (options (slot-ref node 'options))
	    (parent  (slot-ref node 'parent))
	    (unresolved? (*unresolved*)))
	(with-debug 5 'do-resolve<body>
	   (debug-item "body=" body)
	   (parameterize ((*unresolved* #f))
	     (when (eq? parent 'unspecified)
	       (let ((p (assq 'parent env)))
		 (slot-set! node 'parent
			    (and (pair? p) (pair? (cdr p)) (cadr p)))))

             (when (pair? options)
               (debug-item "unresolved options=" options)
               (let ((resolved (map (match-lambda
                                      ((option value)
                                       (list option
                                             (do-resolve! value engine env))))
                                    options)))
                 (slot-set! node 'options resolved)
                 (debug-item "resolved options=" options)))

	     (slot-set! node 'body (do-resolve! body engine env))
	     (slot-set! node 'resolved? (not (*unresolved*))))

	   (*unresolved* (or unresolved? (not (ast-resolved? node))))
	   node))))


(define-method (do-resolve! (node <container>) engine env0)
  ;; Similar to the NODE method, except that (i) children will get NODE as
  ;; their parent, and (ii) NODE may extend its environment, through its
  ;; `env' slot.
  (if (ast-resolved? node)
      node
      (let ((body     (slot-ref node 'body))
            (options  (slot-ref node 'options))
            (env      (slot-ref node 'env))
            (parent   (slot-ref node 'parent))
            (unresolved? (*unresolved*)))
        (with-debug 5 'do-resolve<container>
           (debug-item "markup=" (markup-markup node))
           (debug-item "body=" body)
           (debug-item "env0=" env0)
           (debug-item "env=" env)
           (parameterize ((*unresolved* #f))
             (when (eq? parent 'unspecified)
               (let ((p (assq 'parent env0)))
                 (slot-set! node 'parent
                            (and (pair? p) (pair? (cdr p)) (cadr p)))))

             (when (pair? options)
               (let ((e (append `((parent ,node)) env0)))
                 (debug-item "unresolved options=" options)
                 (for-each (lambda (o)
                             (set-car! (cdr o)
                                       (do-resolve! (cadr o)
                                                    engine e)))
                           options)
                 (debug-item "resolved options=" options)))

             (let ((e `((parent ,node) ,@env ,@env0)))
               (slot-set! node 'body (do-resolve! body engine e)))
             (slot-set! node 'resolved? (not (*unresolved*))))

           (*unresolved* (or unresolved? (not (ast-resolved? node))))
           node))))


(define-method (do-resolve! (node <document>) engine env0)
  (parameterize ((*document-being-resolved* node))
    (next-method)
    ;; resolve the engine custom
    (let* ((env (append `((parent ,node)) env0))
           (resolved (map (match-lambda
                            ((i a)
                             (debug-item "custom=" i " " a)
                             (list i (do-resolve! a engine env))))
                          (slot-ref engine 'customs))))
      (slot-set! engine 'customs resolved))
    node))


(define-method (do-resolve! (node <unresolved>) engine env)
  (with-debug 5 'do-resolve<unresolved>
     (debug-item "node=" node)
     (let* ((p      (assq 'parent env))
            (parent (and (pair? p) (pair? (cdr p)) (cadr p))))

       (slot-set! node 'parent parent)

       (let* ((proc (slot-ref node 'proc))
              (res  (proc node engine env))
              (loc  (ast-loc node)))

         ;; Bind non-unresolved children of RES now so that unresolved
         ;; children of RES (if any) can look them up in the next `resolve!'
         ;; run.  (XXX: This largely duplicates `document-bind-nodes!'.)
         (let loop ((node res)
                    (doc  (ast-document node)))
           (if (ast? node)
               (ast-loc-set! node loc))

           (cond ((document? node)
                  ;; Bind NODE in its parent's document.  This is so
                  ;; that (i) a sub-document is bound in its parent
                  ;; document, and (ii) a node within a sub-document
                  ;; is bound in this sub-document.
                  (document-bind-node! doc node)
                  (loop (markup-body node) node))

                 ((markup? node)
                  (document-bind-node! doc node)
                  (loop (markup-body node) doc))

                 ((node? node)
                  (loop (node-body node) doc))

                 ((pair? node)
                  (for-each (lambda (n) (loop n doc)) node))

                 ((command? node)
                  (loop (command-body node) doc))))

         (debug-item "res=" res)
         (*unresolved* #t)
         res))))


(define-method (do-resolve! (node <handle>) engine env)
  node)


(define-method (do-resolve! (node <command>) engine env)
  (with-debug 5 'do-resolve<command>
     (debug-item "node=" node)
     (let ((p (assq 'parent env)))
       (slot-set! node 'parent (and (pair? p) (pair? (cdr p)) (cadr p))))
     (slot-set! node 'body
                (do-resolve! (command-body node) engine env))
     node))



;;;; ======================================================================
;;;;
;;;; RESOLVE-PARENT
;;;;
;;;; ======================================================================
(define (resolve-parent n e)
  (with-debug 5 'resolve-parent
     (debug-item "n=" n)
     (cond
       ((not (is-a? n <ast>))
	(let ((c (assq 'parent e)))
	  (if (pair? c)
	      (cadr c)
	      n)))
       ((eq? (slot-ref n 'parent) 'unspecified)
        (raise (condition (&ast-orphan-error (ast n)))))
       (else
	(slot-ref n 'parent)))))


;;;; ======================================================================
;;;;
;;;; RESOLVE-SEARCH-PARENT
;;;;
;;;; ======================================================================
(define (resolve-search-parent n e pred)
  (with-debug 5 'resolve-search-parent
     (debug-item "node=" n)
     (debug-item "searching=" pred)
     (let ((p (resolve-parent n e)))
       (debug-item "parent=" p " "
		   (if (is-a? p <markup>) (slot-ref p 'markup) "???"))
       (cond
	 ((pred p)		 p)
	 ((is-a? p <unresolved>) p)
	 ((not p)		 #f)
	 (else			 (resolve-search-parent p e pred))))))

;;;; ======================================================================
;;;;
;;;; RESOLVE-COUNTER
;;;;
;;;; ======================================================================
;;FIXME: factoriser
(define (resolve-counter n e cnt val . opt)
  (let ((c (assq (symbol-append cnt '-counter) e)))
    (if (not (pair? c))
	(if (or (null? opt) (not (car opt)) (null? e))
            (raise (condition (&ast-orphan-error (ast n))))
	    (begin
	      (set-cdr! (last-pair e)
			(list (list (symbol-append cnt '-counter) 0)
			      (list (symbol-append cnt '-env) '())))
	      (resolve-counter n e cnt val)))
	(let* ((num (cadr c)))
	  (let ((c2 (assq (symbol-append cnt '-env) e)))
	    (set-car! (cdr c2) (cons (resolve-parent n e) (cadr c2))))
	  (cond
	    ((integer? val)
	     (set-car! (cdr c) val)
	     (car val))
	    ((not val)
	     val)
	    (else
	     (set-car! (cdr c) (+ 1 num))
	     (+ 1 num)))))))


;;;
;;; `resolve-ident'.
;;;
;;; This function kind of sucks because the document where IDENT is to be
;;; searched is not explictly passed.  Thus, using `document-lookup-node' is
;;; recommended instead of using this function.
;;;

(define (resolve-ident ident markup n e)
  ;; Search for a node with identifier IDENT and markup type MARKUP.  N is
  ;; typically an `<unresolved>' node and the node lookup should be performed
  ;; in its parent document.  E is the "environment" (an alist).
  (with-debug 4 'resolve-ident
     (debug-item "ident=" ident)
     (debug-item "markup=" markup)
     (debug-item "n=" (if (markup? n) (markup-markup n) n))
     (if (not (string? ident))
         (raise (condition (&invalid-argument-error ;; type error
                            (proc-name "resolve-ident")
                            (argument  ident))))
	 (let* ((doc (ast-document n))
		(result (and doc (document-lookup-node doc ident))))
	   (if (or (not markup)
		   (and (markup? result) (eq? (markup-markup result) markup)))
	       result
	       #f)))))


;;; Local Variables:
;;; coding: latin-1
;;; End:
