(mapc 'require
      '(sb-bsd-sockets
	sb-posix
	sb-introspect
	sb-cltl2
	asdf))

(pushnew "systems/" asdf:*central-registry*)

(asdf:operate 'asdf:load-op :cl-fad)
(asdf:operate 'asdf:load-op :cl-ppcre)
(asdf:operate 'asdf:load-op :series)
(asdf:operate 'asdf:load-op :local-time)

(pushnew "slime/" asdf:*central-registry*)

(asdf:operate 'asdf:load-op :swank)

(load "slime/swank-loader")

(dolist (module '("swank-c-p-c"
		  "swank-arglists"
		  "swank-asdf"
		  "swank-package-fu"
		  "swank-sbcl-exts"
		  "swank-fancy-inspector"
		  "swank-fuzzy"
		  "swank-presentations"
		  "swank-presentation-streams"))
  (load (merge-pathnames "slime/contrib/" module)))

(print *modules*)

(sb-ext:save-lisp-and-die "sbcl.core-with-slime")
