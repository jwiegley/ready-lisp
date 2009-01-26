# These are the versions that Ready Lisp is known to work with.  Update
# at your own risk!  All you have to do is the change the version number
# here, and the corresponding file will automatically be uploaded from
# the author's server.  Note that paredit.el and redshank.el must be
# updated manually.

VERSION	    = $(shell date +%Y%m%d)
ARCH	    = $(shell uname -p)
PWD	    = $(shell pwd)
LATEX       = $(shell which latex || echo none)
LOCAL_CACHE = $(HOME)/Projects/ready-lisp/deps

######################################################################

# Go to sbcl.org and check the Downloads page to find out what versions
# these should be now.

SBCL_BOOTSTRAP_VER     = 1.0.23
SBCL_PPC_BOOTSTRAP_VER = 1.0.22

# This version is from aquamacs.org.

AQUA_VER	       = 1.6
SBCL_VER	       = 1.0.24

SBCL_RELEASE_BRANCH    = sbcl_1_0_24

# Change this to 'yes' if you want experimental threading support
THREADING              = no

# These versions should much more rarely.  Here are the URLs where you
# can check for the latest:
#
#  CL-FAD      http://www.weitz.de/cl-fad/
#  CL-PPCRE    http://www.weitz.de/cl-ppcre/
#  LOCAL-TIME  http://common-lisp.net/project/local-time/
#  SERIES      http://series.sourceforge.net/

CL_FAD_VER	       = 0.6.2
CL_PPCRE_VER	       = 2.0.1
LOCAL_TIME_VER	       = 0.9.3
SERIES_VER	       = 2.2.10

HYPERSPEC_VER	       = 7-0

#PAREDIT  = http://mumble.net/~campbell/emacs/
#REDSHANK = http://www.foldr.org/~michaelw/emacs/redshank/
#CLDOC    = http://homepage1.nifty.com/bmonkey/lisp/index-en.html

######################################################################

SBCL_I386	 = $(PWD)/build/sbcl/i386
SBCL_X86_64	 = $(PWD)/build/sbcl/x86_64
SBCL_PPC	 = $(PWD)/build/sbcl/powerpc
SBCL_ARCH	 = $(PWD)/build/sbcl/$(ARCH)

SBCL_I386_LIB	 = $(SBCL_I386)/lib/sbcl
SBCL_X86_64_LIB	 = $(SBCL_X86_64)/lib/sbcl
SBCL_PPC_LIB	 = $(SBCL_PPC)/lib/sbcl
SBCL_ARCH_LIB	 = $(SBCL_ARCH)/lib/sbcl

SBCL_I386_CORE	 = $(SBCL_I386_LIB)/sbcl.core-with-slime
SBCL_X86_64_CORE = $(SBCL_X86_64_LIB)/sbcl.core-with-slime
SBCL_PPC_CORE	 = $(SBCL_PPC_LIB)/sbcl.core-with-slime
SBCL_ARCH_CORE	 = $(SBCL_ARCH_LIB)/sbcl.core-with-slime

######################################################################

build/ReadyLisp-$(VERSION).dmg: image
	hdiutil create -ov -format UDBZ \
	    -volname "Ready Lisp" -srcfolder image $@

######################################################################

RESOURCES = image/Ready Lisp.app/Contents/Resources
AQUA_DMG  = Aquamacs-Emacs-$(AQUA_VER).dmg
AQUA_URL  = http://d10xg45o6p6dbl.cloudfront.net/projects/a/aquamacs/$(AQUA_DMG)

READY_LISP_DEPS =						\
	image/README						\
	image/.background					\
	ReadyLisp						\
	ReadyLisp/Contents/Info.plist				\
	$(SBCL_ARCH_CORE)					\
	ReadyLisp/Contents/Resources/sbcl			\
	ReadyLisp/Contents/Resources/site-lisp/edit-modes/slime	\
	ReadyLisp/Contents/Resources/sbcl/site			\
	ReadyLisp/Contents/Resources/sbcl/systems		\
	ReadyLisp/Contents/Resources/site-lisp/site-start.el	\
	ReadyLisp/Contents/Resources/site-lisp/paredit.elc	\
	ReadyLisp/Contents/Resources/sbcl/source

READY_LISP_DOC_DEPS =						\
	ReadyLisp/Contents/Resources/html			\
	ReadyLisp/Contents/Resources/html/HyperSpec		\
	ReadyLisp/Contents/Resources/pdf			\
	ReadyLisp/Contents/Resources/pdf/sbcl.pdf		\
	ReadyLisp/Contents/Resources/pdf/slime.pdf

ifeq ($(LATEX),none)
image:	$(READY_LISP_DEPS)
else
image:	$(READY_LISP_DEPS) $(READY_LISP_DOC_DEPS)
endif
	chmod -R go+rX image
	ln -sf /Applications image

######################################################################

image/README: README NEWS
	-mkdir image
	cp -p README NEWS image
	chflags hidden image/README image/NEWS

image/.background: dist/image.png dist/DS_Store
	-mkdir image/.background
	cp -p dist/image.png image/.background
	cp -p dist/DS_Store image/.DS_Store

######################################################################

ReadyLisp:
	ln -sf image/Ready\ Lisp.app $@

######################################################################

ReadyLisp/Contents/Info.plist: $(AQUA_DMG)
	hdiutil attach $(AQUA_DMG)
	rsync -aE --delete \
	    "/Volumes/Aquamacs Emacs/Aquamacs Emacs.app/" image/Ready\ Lisp.app/
	hdiutil detach /Volumes/Aquamacs\ Emacs
	touch $@

$(AQUA_DMG):
	if [ -f $(LOCAL_CACHE)/$(AQUA_DMG) ]; then	\
	    ln $(LOCAL_CACHE)/$(AQUA_DMG) $@;	\
	else						\
	    curl -Lo "$@" "$(AQUA_URL)";		\
	fi

######################################################################

BOOTSTRAP_DEPS =				\
	bootstrap.lisp				\
	site					\
	slime/swank.lisp			\
	site/cl-fad-$(CL_FAD_VER)		\
	site/cl-ppcre-$(CL_PPCRE_VER)		\
	site/local-time-$(LOCAL_TIME_VER)	\
	site/series-$(SERIES_VER)		\
	systems

$(SBCL_I386_CORE): $(SBCL_I386)/bin/sbcl $(BOOTSTRAP_DEPS)
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_I386_LIB) $(SBCL_I386)/bin/sbcl	\
		--core $(SBCL_I386_LIB)/sbcl.core		\
		--load bootstrap.lisp > sbcl-i386-core-log.txt 2>&1
	mv sbcl.core-with-slime $@

$(SBCL_X86_64_CORE): $(SBCL_X86_64)/bin/sbcl $(BOOTSTRAP_DEPS)
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_X86_64_LIB) $(SBCL_X86_64)/bin/sbcl	\
		--core $(SBCL_X86_64_LIB)/sbcl.core		\
		--load bootstrap.lisp > sbcl-x86_64-core-log.txt 2>&1
	mv sbcl.core-with-slime $@

$(SBCL_PPC_CORE): $(SBCL_PPC)/bin/sbcl $(BOOTSTRAP_DEPS)
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_PPC_LIB) $(SBCL_PPC)/bin/sbcl	\
		--core $(SBCL_PPC_LIB)/sbcl.core	\
		--load bootstrap.lisp > sbcl-ppc-core-log.txt 2>&1
	mv sbcl.core-with-slime $@

######################################################################

# These are by far the most time consuming rules in this Makefile.

SBCL_DL_URL		   = http://prdownloads.sourceforge.net/sbcl

SBCL_BOOTSTRAP		   = sbcl-$(SBCL_BOOTSTRAP_VER)-x86-darwin
SBCL_BOOTSTRAP_TBZ	   = $(SBCL_BOOTSTRAP)-binary.tar.bz2
SBCL_BOOTSTRAP_TBZ_URL	   = $(SBCL_DL_URL)/$(SBCL_BOOTSTRAP_TBZ)

SBCL_PPC_BOOTSTRAP	   = sbcl-$(SBCL_PPC_BOOTSTRAP_VER)-powerpc-darwin
SBCL_PPC_BOOTSTRAP_TBZ	   = $(SBCL_PPC_BOOTSTRAP)-binary.tar.bz2
SBCL_PPC_BOOTSTRAP_TBZ_URL = $(SBCL_DL_URL)/$(SBCL_PPC_BOOTSTRAP_TBZ)

$(SBCL_I386)/bin/sbcl: \
	sbcl/version.lisp-expr $(SBCL_BOOTSTRAP)/src/runtime/sbcl
	@echo Building SBCL $(SBCL_VER) for i386, please wait ...
	(cd sbcl && sh clean.sh &&					\
	 SBCL_HOME=$(PWD)/$(SBCL_BOOTSTRAP)/contrib			\
	 PATH=$(PWD)/$(SBCL_BOOTSTRAP)/src/runtime:$(PATH)		\
	 sh make.sh > sbcl-i386-log.txt 2>&1 &&				\
	 (test ! -x "$(shell which latex)" ||				\
	    (cd doc && sh make-doc.sh > sbcl-doc-log.txt 2>&1 &&	\
	     cd manual && make > sbcl-manual-log.txt 2>&1 ));		\
	 rm -fr $(SBCL_I386) && mkdir -p $(SBCL_I386) &&		\
	 INSTALL_ROOT=$(SBCL_I386)					\
	 sh install.sh > sbcl-i386-install-log.txt 2>&1 )

$(SBCL_X86_64)/bin/sbcl: \
	sbcl/version.lisp-expr $(SBCL_BOOTSTRAP)/src/runtime/sbcl
	@echo Building SBCL $(SBCL_VER) for x86-64, please wait ...
	(cd sbcl && sh clean.sh &&					\
	 SBCL_ARCH=x86-64 SBCL_HOME=$(PWD)/$(SBCL_BOOTSTRAP)/contrib	\
	 PATH=$(PWD)/$(SBCL_BOOTSTRAP)/src/runtime:$(PATH)		\
	 sh make.sh > sbcl-x86_64-log.txt 2>&1 &&			\
	 rm -fr $(SBCL_X86_64) && mkdir -p $(SBCL_X86_64) &&		\
	 INSTALL_ROOT=$(SBCL_X86_64) \
	 sh install.sh > sbcl-x86_64-install-log.txt 2>&1 )

$(SBCL_PPC)/bin/sbcl: \
	sbcl/version.lisp-expr $(SBCL_PPC_BOOTSTRAP)/src/runtime/sbcl
	@echo Building SBCL $(SBCL_VER) for powerpc, please wait ...
	(cd sbcl && sh clean.sh &&				\
	 SBCL_HOME=$(PWD)/$(SBCL_PPC_BOOTSTRAP)/contrib		\
	 PATH=$(PWD)/$(SBCL_PPC_BOOTSTRAP)/src/runtime:$(PATH)	\
	 sh make.sh > sbcl-ppc-log.txt 2>&1 &&			\
	 rm -fr $(SBCL_PPC) && mkdir -p $(SBCL_PPC) &&		\
	 INSTALL_ROOT=$(SBCL_PPC) \
	 sh install.sh > sbcl-ppc-install-log.txt 2>&1 )

######################################################################

SBCL_GIT = git://sbcl.boinkor.net/sbcl.git

ifeq ($(THREADING),yes)
sbcl/version.lisp-expr: sbcl/customize-target-features.lisp
else
sbcl/version.lisp-expr:
endif
	@test -f sbcl/version.lisp-expr ||			\
	    (rm -fr sbcl; git clone $(SBCL_GIT) &&		\
	     cd sbcl && git checkout $(SBCL_RELEASE_BRANCH))

sbcl/customize-target-features.lisp: customize-target-features.lisp
	cp -p $< $@

######################################################################

$(SBCL_BOOTSTRAP)/src/runtime/sbcl: $(SBCL_BOOTSTRAP_TBZ)
	tar xjf $(SBCL_BOOTSTRAP_TBZ)
	ln -f $(SBCL_BOOTSTRAP)/output/sbcl.core $(SBCL_BOOTSTRAP)/contrib
	touch $(SBCL_BOOTSTRAP)/src/runtime/sbcl

$(SBCL_BOOTSTRAP_TBZ):
	if [ -f $(LOCAL_CACHE)/$(SBCL_BOOTSTRAP_TBZ) ]; then	\
	    ln $(LOCAL_CACHE)/$(SBCL_BOOTSTRAP_TBZ) $@;		\
	else								\
	    curl -Lo $@ $(SBCL_BOOTSTRAP_TBZ_URL);			\
	fi

$(SBCL_PPC_BOOTSTRAP)/src/runtime/sbcl: $(SBCL_PPC_BOOTSTRAP_TBZ)
	tar xjf $(SBCL_PPC_BOOTSTRAP_TBZ)
	ln -f $(SBCL_PPC_BOOTSTRAP)/output/sbcl.core $(SBCL_PPC_BOOTSTRAP)/contrib
	touch $(SBCL_PPC_BOOTSTRAP)/src/runtime/sbcl

$(SBCL_PPC_BOOTSTRAP_TBZ):
	if [ -f $(LOCAL_CACHE)/$(SBCL_PPC_BOOTSTRAP_TBZ) ]; then	\
	    ln $(LOCAL_CACHE)/$(SBCL_PPC_BOOTSTRAP_TBZ) $@;	\
	else								\
	    curl -Lo $@ $(SBCL_PPC_BOOTSTRAP_TBZ_URL);			\
	fi

######################################################################

site:
	mkdir $@

######################################################################

SLIME_GIT = git://github.com/nablaone/slime.git

slime/swank.lisp:
	rm -fr slime; git clone $(SLIME_GIT)

######################################################################

CL_FAD_URL     = http://www.weitz.de/cl-fad/
CL_FAD_TGZ     = cl-fad.tar.gz
CL_FAD_TGZ_URL = http://weitz.de/files/$(CL_FAD_TGZ)

site/cl-fad-$(CL_FAD_VER): site/$(CL_FAD_TGZ)
	(cd site; tar xzf $(CL_FAD_TGZ))

site/$(CL_FAD_TGZ):
	if [ -f $(LOCAL_CACHE)/$(CL_FAD_TGZ) ]; then	\
	    ln $(LOCAL_CACHE)/$(CL_FAD_TGZ) $@;		\
	else							\
	    curl -Lo $@ $(CL_FAD_TGZ_URL);			\
	fi

######################################################################

CL_PPCRE_URL	 = http://www.weitz.de/cl-ppcre/
CL_PPCRE_TGZ	 = cl-ppcre.tar.gz
CL_PPCRE_TGZ_URL = http://weitz.de/files/$(CL_PPCRE_TGZ)

site/cl-ppcre-$(CL_PPCRE_VER): site/$(CL_PPCRE_TGZ)
	(cd site; tar xzf $(CL_PPCRE_TGZ))

site/$(CL_PPCRE_TGZ):
	if [ -f $(LOCAL_CACHE)/$(CL_PPCRE_TGZ) ]; then	\
	    ln $(LOCAL_CACHE)/$(CL_PPCRE_TGZ) $@;		\
	else							\
	    curl -Lo $@ $(CL_PPCRE_TGZ_URL);			\
	fi

######################################################################

LOCAL_TIME_URL	   = http://common-lisp.net/project/local-time/
LOCAL_TIME_TGZ	   = local-time-$(LOCAL_TIME_VER).tar.gz
LOCAL_TIME_TGZ_URL = $(LOCAL_TIME_URL)/$(LOCAL_TIME_TGZ)

site/local-time-$(LOCAL_TIME_VER): site/$(LOCAL_TIME_TGZ)
	(cd site; tar xzf $(LOCAL_TIME_TGZ))

site/$(LOCAL_TIME_TGZ):
	if [ -f $(LOCAL_CACHE)/$(LOCAL_TIME_TGZ) ]; then	\
	    ln $(LOCAL_CACHE)/$(LOCAL_TIME_TGZ) $@;	\
	else							\
	    curl -Lo $@ $(LOCAL_TIME_TGZ_URL);			\
	fi

######################################################################

SERIES_URL     = http://series.sourceforge.net/
SERIES_TBZ     = series-$(SERIES_VER).tar.bz2
SERIES_TBZ_URL = http://downloads.sourceforge.net/series/$(SERIES_TBZ)

site/series-$(SERIES_VER): site/$(SERIES_TBZ)
	(cd site; tar xjf $(SERIES_TBZ))

site/$(SERIES_TBZ):
	if [ -f $(LOCAL_CACHE)/$(SERIES_TBZ) ]; then	\
	    ln $(LOCAL_CACHE)/$(SERIES_TBZ) $@;		\
	else							\
	    curl -Lo $@ $(SERIES_TBZ_URL);			\
	fi

######################################################################

systems:
	mkdir $@
	(cd systems; ln -sf ../site/*/*.asd .)

######################################################################

PPC_HOST = none
PPC_USER = johnw

ReadyLisp/Contents/Resources/sbcl: build/sbcl/sbcl
	rsync -a --exclude=share/ --exclude=bin/sbcl	\
	    --exclude=lib/sbcl/sbcl.core		\
	    build/sbcl/ "$(RESOURCES)"/sbcl/

ifeq ($(PPC_HOST),none)
build/sbcl/sbcl:
else
build/sbcl/sbcl: $(SBCL_PPC)
endif
	if [ -x $(SBCL_PPC)/bin/sbcl ]; then			\
	    if [ -x $(SBCL_X86_64)/bin/sbcl ]; then		\
		lipo -create					\
		    -arch x86_64 $(SBCL_X86_64)/bin/sbcl	\
		    -arch i386   $(SBCL_I386)/bin/sbcl		\
		    -arch ppc    $(SBCL_PPC)/bin/sbcl		\
		    -output $@;					\
	    else						\
		lipo -create					\
		    -arch i386   $(SBCL_I386)/bin/sbcl		\
		    -arch ppc    $(SBCL_PPC)/bin/sbcl		\
		    -output $@;					\
	    fi;							\
	elif [ -x $(SBCL_X86_64)/bin/sbcl ]; then		\
	    lipo -create					\
		-arch x86_64 $(SBCL_X86_64)/bin/sbcl		\
		-arch i386   $(SBCL_I386)/bin/sbcl		\
		-output $@;					\
	else							\
	    cp -p $(SBCL_I386)/bin/sbcl $@;			\
	fi

######################################################################

$(SBCL_PPC): sbcl-$(SBCL_VER)-ppc.tar.bz2
	if [   -f sbcl-$(SBCL_VER)-ppc.tar.bz2 -a		\
	     ! -d $(SBCL_PPC) ]; then				\
	    tar xjf sbcl-$(SBCL_VER)-ppc.tar.bz2;		\
	fi

ifeq ($(PPC_HOST),none)

sbcl-$(SBCL_VER)-ppc.tar.bz2: $(SBCL_PPC_CORE)
	tar cjf $@ build/sbcl/powerpc

else

sbcl-$(SBCL_VER)-ppc.tar.bz2: $(SBCL_PPC_BOOTSTRAP_TBZ)
	rsync -e ssh -a --delete				\
	    --exclude='*.o'					\
	    --exclude='*.fasl'					\
	    --exclude='/sbcl*-x86-darwin.bz2'			\
	    --exclude=.git/					\
	    --exclude=/image/					\
	    --exclude=/build/					\
	    --exclude=/dist/					\
	    --exclude=/doc/					\
	    --exclude=/sbcl/obj/				\
	    --exclude=/sbcl/output/				\
	    --exclude=/site-lisp/				\
	    ./ $(PPC_USER)@$(PPC_HOST):/tmp/ready-lisp/
	ssh $(PPC_USER)@$(PPC_HOST) \
	    "(cd /tmp/ready-lisp && make sbcl-$(SBCL_VER)-ppc.tar.bz2)"
	scp $(PPC_USER)@$(PPC_HOST):/tmp/ready-lisp/$@ .

endif

######################################################################

ReadyLisp/Contents/Resources/site-lisp/edit-modes/slime: slime/slime.elc
	rsync -a --delete --exclude=.git/ --exclude=doc/ --exclude='*-log.txt' \
	    slime/ "$(RESOURCES)"/site-lisp/edit-modes/slime/

slime/slime.elc: slime/slime.el
	find slime -name '*.el' -type f |				\
	while read file; do						\
	    EMACSDATA="$(RESOURCES)/etc"				\
	    EMACSDOC="$(RESOURCES)/etc"					\
	    EMACSPATH="$(RESOURCES)/libexec"				\
	    "$(RESOURCES)"/../MacOS/"Aquamacs Emacs" -q --no-site-file	\
		-L "$(RESOURCES)"/lisp					\
		-L "$(RESOURCES)"/lisp/international			\
		-L "$(RESOURCES)"/lisp/emacs-lisp			\
		-L "$(RESOURCES)"/lisp/progmodes			\
		-L "$(RESOURCES)"/lisp/net				\
		-L slime						\
		-L slime/contrib					\
		-l slime/slime.el					\
		--eval '(setq byte-compile-warnings nil)'		\
		-batch -f batch-byte-compile $$file;			\
	done

######################################################################

ReadyLisp/Contents/Resources/sbcl/site: site
	rsync -a --exclude='*.tar.*' site/ "$(RESOURCES)"/sbcl/site/

ReadyLisp/Contents/Resources/sbcl/systems: systems
	rsync -a systems/ "$(RESOURCES)"/sbcl/systems/

######################################################################

ReadyLisp/Contents/Resources/site-lisp/site-start.el: site-lisp/site-start.patch
	patch -p0 -N -d "$(RESOURCES)" < site-lisp/site-start.patch
	rm -f ReadyLisp/Contents/Resources/site-lisp/site-start.elc

ReadyLisp/Contents/Resources/site-lisp/paredit.elc: site-lisp/paredit.elc
	rsync -a --exclude=site-start.patch site-lisp/ "$(RESOURCES)"/site-lisp/

site-lisp/paredit.elc: \
	site-lisp/cldoc.el site-lisp/paredit.el site-lisp/redshank.el
	echo $? | while read file; do					\
	    EMACSDATA="$(RESOURCES)/etc"				\
	    EMACSDOC="$(RESOURCES)/etc"					\
	    EMACSPATH="$(RESOURCES)/libexec"				\
	    "$(RESOURCES)"/../MacOS/"Aquamacs Emacs" -q --no-site-file	\
		-L "$(RESOURCES)"/lisp					\
		-L "$(RESOURCES)"/lisp/international			\
		-L "$(RESOURCES)"/lisp/emacs-lisp			\
		-L "$(RESOURCES)"/lisp/progmodes			\
		-L "$(RESOURCES)"/lisp/net				\
		-L site-lisp -l slime/slime.elc				\
		--eval '(setq byte-compile-warnings nil)'		\
		-batch -f batch-byte-compile $$file;			\
	done

######################################################################

ReadyLisp/Contents/Resources/pdf:
	mkdir $@

ReadyLisp/Contents/Resources/html:
	mkdir $@
	test ! -d $@/../Aquamacs\ Help	       || mv $@/../Aquamacs\ Help $@
	test ! -d $@/../Emacs\ Manual	       || mv $@/../Emacs\ Manual $@
	test ! -d $@/../Emacs\ Lisp\ Reference || mv $@/../Emacs\ Lisp\ Reference $@
	test ! -L $@/../elisp		       || mv $@/../elisp $@

######################################################################

ReadyLisp/Contents/Resources/pdf/sbcl.pdf:
	rsync -a $(SBCL_I386)/share/man/ "$(RESOURCES)"/man/
	cp -p $(SBCL_I386)/share/info/*.info* "$(RESOURCES)"/info/
	cp -p $(SBCL_I386)/share/doc/sbcl/*.pdf "$(RESOURCES)"/pdf/
	rsync -a $(SBCL_I386)/share/doc/sbcl/html/asdf "$(RESOURCES)"/html
	rsync -a $(SBCL_I386)/share/doc/sbcl/html/sbcl "$(RESOURCES)"/html

######################################################################

ReadyLisp/Contents/Resources/sbcl/source: sbcl
	rsync -a --exclude=doc/ --exclude=obj/ --exclude=output/ \
	    --exclude=tests/ --exclude=tools-for-build/ \
	    --exclude=.git/ --exclude='*-log.txt' \
	    sbcl/ "$(RESOURCES)"/sbcl/source/

######################################################################

ReadyLisp/Contents/Resources/pdf/slime.pdf: slime/doc/slime.pdf
	cp -p slime/doc/slime.info* "$(RESOURCES)"/info/
	cp -p slime/doc/*.pdf "$(RESOURCES)"/pdf/
	rsync -a slime/doc/html/ "$(RESOURCES)"/html/slime/

slime/doc/slime.pdf: slime/doc/slime.texi
	test ! -x "$(shell which latex)" || \
	    (cd slime/doc; make > slime-doc-log.txt 2>&1)

######################################################################

HYPERSPEC_URL	  = ftp://ftp.lispworks.com/pub/software_tools/reference
HYPERSPEC_TGZ	  = HyperSpec-$(HYPERSPEC_VER).tar.gz
HYPERSPEC_TGZ_URL = $(HYPERSPEC_URL)/$(HYPERSPEC_TGZ)

ReadyLisp/Contents/Resources/html/HyperSpec: doc/html doc/html/HyperSpec
	cp -p doc/info/ansi* "$(RESOURCES)"/info/
	grep -q SBCL "$(RESOURCES)"/info/dir || \
	    patch -p1 -d "$(RESOURCES)" < doc/info/dir.patch
	rsync -a doc/html/HyperSpec "$(RESOURCES)"/html

doc/html:
	mkdir doc/html

doc/html/HyperSpec: doc/html/$(HYPERSPEC_TGZ)
	(cd doc/html; tar xzf $(HYPERSPEC_TGZ))
	touch $@

doc/html/$(HYPERSPEC_TGZ):
	if [ -f $(LOCAL_CACHE)/$(HYPERSPEC_TGZ) ]; then	\
	    ln $(LOCAL_CACHE)/$(HYPERSPEC_TGZ) $@;		\
	else							\
	    curl -Lo $@ $(HYPERSPEC_TGZ_URL);			\
	fi

######################################################################

# These are utility targets for use by the developer.

update:
	git pull
	test -d sbcl && (cd sbcl && git pull)
	test -d slime && (cd slime && git pull)

clean:
	rm -f ReadyLisp *.dmg *.bz2 *-log.txt
	rm -fr build image sbcl-*-darwin
	test ! -d slime || find slime -name '*.fasl' -delete
	test ! -d slime || find slime -name '*.elc' -delete
	find site-lisp -name '*.elc' -delete
	test ! -d sbcl || (cd sbcl; sh clean.sh)
	test ! -d slime/doc || (cd slime/doc; make clean)

scour: clean
	rm -fr sbcl slime systems site

# Makefile ends here
