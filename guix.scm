;;; guix.scm  --  Build recipe for GNU Guix.
;;;
;;; Copyright © 2020 Ludovic Courtès <ludo@gnu.org>
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

(use-modules (gnu) (guix)
             (guix profiles)
             (guix build-system gnu)
             ((guix git-download) #:select (git-predicate))
             (guix licenses)
             (srfi srfi-1))

(define S specification->package)

(define skribilo
  (package
    (name "skribilo")
    (version "0.0-git")
    (source (local-file "." "skribilo-checkout"
                        #:recursive? #t
                        #:select?
                        (git-predicate (current-source-directory))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (modify-phases %standard-phases
                  (add-after 'unpack 'make-po-files-writable
                    (lambda _
                      (for-each make-file-writable (find-files "po"))
                      #t)))))
    (native-inputs
     `(("pkg-config" ,(S "pkg-config"))
       ("autoconf" ,(S "autoconf"))
       ("automake" ,(S "automake"))
       ("gettext" ,(S "gettext"))
       ("git" ,(S "git-minimal"))))               ;for version numbers
    (inputs
     `(("guile" ,(S "guile"))
       ("imagemagick" ,(S "imagemagick"))         ;'convert'
       ("ghostscript" ,(S "ghostscript"))         ;'ps2pdf'
       ("ploticus" ,(S "ploticus"))
       ("lout" ,(S "lout"))))

    ;; The 'skribilo' command needs them, and for people using Skribilo as a
    ;; library, these inputs are needed as well.
    (propagated-inputs
     `(("guile-reader" ,(S "guile-reader"))
       ("guile-lib" ,(S "guile-lib"))))

    (home-page "https://www.nongnu.org/skribilo/")
    (synopsis "Document production tool written in Guile Scheme")
    (description
     "Skribilo is a free document production tool that takes a structured
document representation as its input and renders that document in a variety of
output formats: HTML and Info for on-line browsing, and Lout and LaTeX for
high-quality hard copies.

The input document can use Skribilo's markup language to provide information
about the document's structure, which is similar to HTML or LaTeX and does not
require expertise.  Alternatively, it can use a simpler, “markup-less” format
that borrows from Emacs' outline mode and from other conventions used in
emails, Usenet and text.

Lastly, Skribilo provides Guile Scheme APIs.")
    (license gpl3+)))

(define with-guile-2.0
  (package-input-rewriting/spec `(("guile" . ,(const (S "guile@2.0"))))
                                #:deep? #f))

(define with-guile-2.2
  (package-input-rewriting/spec `(("guile" . ,(const (S "guile@2.2"))))
                                #:deep? #f))

(define skribilo/guile-2.2
  (package
    (inherit (with-guile-2.2 skribilo))
    (name "guile2.2-skribilo")
    ;; Arrange to not trigger a rebuild of Automake & co.
    (inputs `(("guile" ,(S "guile@2.2"))
              ,@(alist-delete "guile" (package-inputs skribilo))))
    (native-inputs (package-native-inputs skribilo))))

(define skribilo/guile-2.0
  (package
    (inherit (with-guile-2.0 skribilo))
    (name "guile2.0-skribilo")
    (inputs `(("guile" ,(S "guile@2.0"))
              ,@(alist-delete "guile" (package-inputs skribilo))))
    (native-inputs (package-native-inputs skribilo))))

(packages->manifest (list skribilo/guile-2.0
                          skribilo/guile-2.2
                          skribilo))

;; Comment the following line to build all the variants.
skribilo
