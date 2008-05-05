;;; init-lisp.el --- Code to initialize the Ready Lisp environment

;; Copyright (C) 2007,2008  John Wiegley.  All rights reserved.

;; Author: John Wiegley <johnw@newartisans.com>
;; Keywords: lisp
;; location: http://www.newartisans.com/software/readylisp.html

;; This file is not part of GNU Emacs.

;; This module is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 2, or (at your
;; option) any later version.

;; This module is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;;_ * mule

(prefer-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

;;;_ * cldoc

(autoload 'turn-on-cldoc-mode "cldoc" nil t)

(dolist (hook '(lisp-mode-hook
		slime-repl-mode-hook))
  (add-hook hook 'turn-on-cldoc-mode))

;;;_ * ansicl

(require 'info-look)

(dolist (mode '(lisp-mode slime-mode slime-repl-mode
			  inferior-slime-mode))
  (info-lookup-add-help :mode mode
			:regexp "[^][()'\" \t\n]+"
			:ignore-case t
			:doc-spec '(("(ansicl)Symbol Index" nil nil nil))))

(eval-after-load "lisp-mode"
  '(progn
     (define-key lisp-mode-map [(control ?h) ?f] 'info-lookup-symbol)))

(defadvice Info-exit (after remove-info-window activate)
  "When info mode is quit, remove the window."
  (if (> (length (window-list)) 1)
      (delete-window)))

;;;_ * emacs-lisp

(defun elisp-indent-or-complete (&optional arg)
  (interactive "p")
  (call-interactively 'lisp-indent-line)
  (unless (or (looking-back "^\\s-*")
	      (bolp)
	      (not (looking-back "[-A-Za-z0-9_*+/=<>!?]+")))
    (call-interactively 'lisp-complete-symbol)))

(eval-after-load "lisp-mode"
  '(progn
    (define-key emacs-lisp-mode-map [tab] 'elisp-indent-or-complete)))

;;;_ * lisp

(add-hook 'lisp-mode-hook 'turn-on-auto-fill)

(put 'iterate 'lisp-indent-function 1)
(put 'mapping 'lisp-indent-function 1)
(put 'producing 'lisp-indent-function 1)

(eval-after-load "speedbar"
 '(progn
   (add-to-list 'speedbar-obj-alist '("\\.lisp$" . ".fasl"))
   (speedbar-add-supported-extension ".lisp")))

;;;_ * paredit

(autoload 'paredit-mode "paredit"
  "Minor mode for pseudo-structurally editing Lisp code." t)

(dolist (hook '(emacs-lisp-mode-hook
		lisp-mode-hook
		slime-repl-mode-hook))
  (add-hook hook #'(lambda () (paredit-mode +1))))

;;;_ * redhank

(autoload 'redshank-mode "redshank"
  "Minor mode for restructuring Lisp code (i.e., refactoring)." t)

(dolist (hook '(emacs-lisp-mode-hook
		lisp-mode-hook
		slime-repl-mode-hook))
  (add-hook hook #'(lambda () (redshank-mode +1))))

;;;_ * slime

(require 'slime)

(slime-setup
 '(inferior-slime
   slime-asdf
   slime-autodoc
   slime-banner
   slime-c-p-c
   slime-editing-commands
   slime-fancy-inspector
   slime-fancy
   slime-fuzzy
   slime-highlight-edits
   slime-parse
   slime-presentation-streams
   slime-presentations
   slime-references
   slime-scratch
   slime-tramp
   ;; slime-typeout-frame
   slime-xref-browser))

;;(setq slime-net-coding-system 'utf-8-unix)

(defvar *slime-use-intel-x86-64* nil)

(defvar *sbcl-arch*
  (if (string= "i386" (shell-command-to-string "arch"))
      (if (and *slime-use-intel-x86-64*
	       (string-match "x86_64: 1"
			     (shell-command-to-string
			      "sysctl hw.optional.x86_64")))
	  "x86_64"
	"i386")
    "ppc"))

(defvar *ready-lisp-resources-path*
  (expand-file-name ".." (file-name-directory load-file-name)))

(defvar *sbcl-home-path*
  (expand-file-name "sbcl/" *ready-lisp-resources-path*))

(defvar *sbcl-lib-path*
  (expand-file-name (concat "sbcl/" (if (string= *sbcl-arch* "ppc")
					"powerpc"
				      *sbcl-arch*)
			    "/lib/sbcl/")
		    *ready-lisp-resources-path*))

(defvar *sbcl-source-path*
  (expand-file-name "sbcl/source/" *ready-lisp-resources-path*))

(defvar *sbcl-site-path*
  (expand-file-name "sbcl/site/" *ready-lisp-resources-path*))

(setenv "SBCL_HOME" *sbcl-lib-path*)

;; jww (2008-04-25): Ok, the following really needs some explanation; even if
;; you understand it perfectly (you nimble CL hacker you), I'm going to need
;; to remember what this does a few months or years from now...
;;
;; The problem being addressed here is that Ready Lisp pre-binds libraries
;; like SLIME into the SBCL core file, in the interests of first-time load
;; speed.  Mainly because first impressions are important enough to be worth
;; this extra effort.
;;
;; But while this work greats, SBCL and SLIME can't handle it if you relocate
;; the new core to a machine that doesn't have the same environment
;; (pathnames, etc).  I built Ready Lisp in a particular place; you as the
;; user probably aren't going to run it from that same place; this will cause
;; disjunction between the baked pathnames in the core file and your system.
;; The end result of all this is that asdf-install will fail to work, pretty
;; cryptically too.
;;
;; The answer is to dynamically rewrite the pathnames that are loaded from the
;; core file!  Yes, this is a total hack, but the alternative is to load and
;; compile all the Lisp sources that Ready Lisp depends on at load time.  Not
;; only would this be slow, but the output generated would be confusing as
;; hell to someone who's not familiar with Common Lisp already.
;;
;; So I define this function, `slime-reconfig-load-path', which gets attached
;; to `slime-connected-hook' to run once SLIME is able to talk to the SBCL
;; inferior process.  This defun is wrapped in an `eval' form because we need
;; to insert the pathnames that were determined just above, such as
;; `*sbcl-source-path*', etc.
;;
;; This function simply calls `slime-eval-async' at the first opportunity, in
;; order to pass a Common Lisp form down to SBCL.  That form changes the
;; follow special variables:
;;
;;   swank-loader:*source-directory*
;;   swank::*load-path*
;;   <path translations for logical host SYS>
;;   <paths found in asdf::*defined-systems*>
;;
;; All of these variables and definitions are being changed to relocate to the
;; Ready Lisp application's Resources directory (and sub-directories beneath
;; it), no matter where the user happens to install Ready Lisp.  You can even
;; run it straight from the disk image!

(eval
 `(defun slime-reconfig-load-path ()
    (slime-eval-async
     '(cl:prog1
       cl:nil
       (cl:setf swank-loader:*source-directory*
		,(expand-file-name "site-lisp/edit-modes/slime/"
				   *ready-lisp-resources-path*)
		swank::*load-path*
		'(,(expand-file-name "site-lisp/edit-modes/slime/contrib/"
				     *ready-lisp-resources-path*))

		(sb-impl::logical-host-translations
		 (sb-impl::find-logical-host "SYS"))
		(cl:list
		 (cl:list
		  "SYS:SRC;**;*.*.*"
		  (cl:pathname ,(concat *sbcl-source-path* "/src/**/*.*")))
		 (cl:list
		  "SYS:CONTRIB;**;*.*.*"
		  (cl:pathname ,(concat *sbcl-source-path* "/contrib/**/*.*"))))

		(sb-impl::logical-host-canon-transls
		 (sb-impl::find-logical-host "SYS"))
		(cl:list
		 (cl:list
		  (cl:pathname "SYS:SRC;**;*.*.*")
		  (cl:pathname ,(concat *sbcl-source-path* "/src/**/*.*")))
		 (cl:list
		  (cl:pathname "SYS:CONTRIB;**;*.*.*")
		  (cl:pathname ,(concat *sbcl-source-path* "/contrib/**/*.*")))))

       (cl:maphash
	(cl:lambda
	 (key value)
	 (cl:declare (cl:ignore key))
	 (cl:let ((component
		   (cl:car
		    (cl:last (cl:pathname-directory
			      (asdf::component-relative-pathname (cl:cdr value))))))
		  (site-modules (quote ,(nthcdr 2 (directory-files *sbcl-site-path*)))))
		 (cl:setf (cl:slot-value (cl:cdr value) 'asdf::relative-pathname)
			  (cl:pathname
			   (cl:concatenate
			    'cl:string
			    (cl:if (cl:member component site-modules
					      :test (cl:symbol-function 'cl:string=))
				   ,*sbcl-site-path*
				   ,*sbcl-lib-path*)
			    component "/")))))
	asdf::*defined-systems*)))))

(add-hook 'slime-connected-hook 'slime-reconfig-load-path)

(setq slime-lisp-implementations
      `((sbcl
	 (,@(list "/usr/bin/arch" "-arch" *sbcl-arch*
		  (expand-file-name "sbcl" *sbcl-home-path*)
		  "--core"
		  (expand-file-name "sbcl.core-with-slime" *sbcl-lib-path*)))
	 :init (lambda (port-file _)
		 (format "(swank:start-server %S :coding-system \"utf-8-unix\")\n"
			 port-file))
	 :coding-system utf-8-unix)
	(cmucl ("lisp"))
	(ecl ("ecl"))
	(clisp ("clisp") :coding-system utf-8-unix)))

(setq slime-default-lisp 'sbcl)
(setq slime-complete-symbol*-fancy t)
(setq slime-complete-symbol-function 'slime-fuzzy-complete-symbol)

(add-hook 'slime-load-hook #'(lambda () (require 'slime-fancy)))
(add-hook 'inferior-lisp-mode-hook #'(lambda () (inferior-slime-mode t)))
(remove-hook 'lisp-mode-hook 'load-and-setup-slime)

(defun indent-or-complete (&optional arg)
  (interactive "p")
  (if (or (looking-back "^\\s-*") (bolp))
      (call-interactively 'lisp-indent-line)
    (call-interactively 'slime-indent-and-complete-symbol)))

(eval-after-load "lisp-mode"
  '(progn
     (define-key lisp-mode-map [tab] 'indent-or-complete)
     (define-key lisp-mode-map [(meta ?q)] 'slime-reindent-defun)))

(eval-after-load "slime"
  '(progn
     (define-key slime-mode-map [return] 'paredit-newline)
     (define-key slime-repl-mode-map [tab] 'indent-or-complete)
     (define-key inferior-slime-mode-map [(control ?c) (control ?p)]
       'slime-repl-previous-prompt)

     (define-key slime-mode-map [(control ?h) ?f] 'info-lookup-symbol)
     (define-key slime-repl-mode-map [(control ?h) ?f] 'info-lookup-symbol)
     (define-key inferior-slime-mode-map [(control ?h) ?f] 'info-lookup-symbol)))

(slime)

(provide 'init-lisp)

;; init-lisp.el ends here
