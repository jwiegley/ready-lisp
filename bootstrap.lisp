(mapc 'require
      '(sb-bsd-sockets
	sb-posix
	sb-introspect
	sb-cltl2
	asdf))

(pushnew "systems/" asdf:*central-registry*)

(asdf:operate 'asdf:load-op :cl-ppcre)
(asdf:operate 'asdf:load-op :series)
(asdf:operate 'asdf:load-op :local-time)
(asdf:operate 'asdf:load-op :memoize)

(load "slime/swank-loader")

(dolist (module '("swank-arglists"
		  "swank-asdf"
		  "swank-c-p-c"
		  "swank-fancy-inspector"
		  "swank-fuzzy"
		  "swank-presentation-streams"
		  "swank-presentations"))
  (load (merge-pathnames "slime/contrib/" module)))

(print *modules*)

(sb-ext:save-lisp-and-die "sbcl.core-with-slime")
