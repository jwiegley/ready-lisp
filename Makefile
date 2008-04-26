# These are the versions that Ready Lisp is known to work with.  Update at
# your own risk!  All you have to do is the change the version number here,
# and the corresponding file will automatically be uploaded from the author's
# server.  Note that paredit.el and redshank.el must be updated manually.

VERSION	  = $(shell date +%Y%m%d)
SBCL_VER  = $(shell ./sbcl-ver)
SLIME_VER = $(shell ./slime-ver)
ARCH	  = $(shell uname -p)

# Go to sbcl.org and check the Downloads page to find out what versions these
# should be now.

SBCL_BOOTSTRAP_VER     = 1.0.12
SBCL_PPC_BOOTSTRAP_VER = 1.0.2

# This version is from aquamacs.org.

AQUA_VER = 1.3b

# These versions should much more rarely.  Here are the URLs where you can
# check for the latest:
#
#  CL-FAD      http://www.weitz.de/cl-fad/
#  CL-PPCRE    http://www.weitz.de/cl-ppcre/
#  LOCAL-TIME  http://common-lisp.net/project/local-time/
#  SERIES      http://series.sourceforge.net/

CL_FAD_VER     = 0.6.2
CL_PPCRE_VER   = 1.3.2
LOCAL_TIME_VER = 0.9.3
SERIES_VER     = 2.2.9

######################################################################

PWD = $(shell pwd)

SBCL_I386   = $(PWD)/build/sbcl/i386
SBCL_X86_64 = $(PWD)/build/sbcl/x86_64
SBCL_PPC    = $(PWD)/build/sbcl/ppc

SBCL_I386_LIB   = $(SBCL_I386)/lib/sbcl
SBCL_X86_64_LIB = $(SBCL_X86_64)/lib/sbcl
SBCL_PPC_LIB    = $(SBCL_PPC)/lib/sbcl

SBCL_I386_CORE   = $(SBCL_I386_LIB)/sbcl.core-with-slime
SBCL_X86_64_CORE = $(SBCL_X86_64_LIB)/sbcl.core-with-slime
SBCL_PPC_CORE    = $(SBCL_PPC_LIB)/sbcl.core-with-slime

all: core slime-build site-lisp-elc disk-image

core: dependencies sbcl

update:
	git pull
	test -d sbcl && (cd sbcl && git pull)
	test -d slime && (cd slime && git pull)

######################################################################

dependencies: aquamacs sbcl-git slime-git hyperspec \
	cl-fad cl-ppcre local-time series systems

######################################################################

AQUA_DMG=Aquamacs-Emacs-$(AQUA_VER).dmg
AQUA_URL=http://www.tardis.ed.ac.uk/~dreitter/$(AQUA_DMG)
AQUA_APP=Aquamacs Emacs.app

RESOURCES = aquamacs/$(AQUA_APP)/Contents/Resources

aquamacs/$(AQUA_DMG):
	@test -d aquamacs || mkdir aquamacs
	curl -Lo "$@" "$(AQUA_URL)"

aquamacs-app: aquamacs/$(AQUA_DMG)
	@test -d "aquamacs/$(AQUA_APP)" ||				\
	    (hdiutil attach aquamacs/$(AQUA_DMG) &&			\
	    cp -R "/Volumes/Aquamacs Emacs/$(AQUA_APP)" aquamacs &&	\
	    hdiutil detach /Volumes/Aquamacs\ Emacs)

aquamacs: aquamacs-app

apply-patches: site-lisp/site-start.patch
	patch -N -p0 < site-lisp/site-start.patch

######################################################################

SBCL_GIT=git://sbcl.boinkor.net/sbcl.git

sbcl/version.lisp-expr:
	@test -f sbcl/version.lisp-expr ||		\
		(rm -fr sbcl; git clone $(SBCL_GIT))

sbcl-git: sbcl/version.lisp-expr

SBCL_BOOTSTRAP=sbcl-$(SBCL_BOOTSTRAP_VER)-x86-darwin
SBCL_BOOTSTRAP_TBZ=$(SBCL_BOOTSTRAP)-binary.tar.bz2
SBCL_BOOTSTRAP_TBZ_URL=http://prdownloads.sourceforge.net/sbcl/$(SBCL_BOOTSTRAP_TBZ)

SBCL_PPC_BOOTSTRAP=sbcl-$(SBCL_PPC_BOOTSTRAP_VER)-powerpc-darwin
SBCL_PPC_BOOTSTRAP_TBZ=$(SBCL_PPC_BOOTSTRAP)-binary.tar.bz2
SBCL_PPC_BOOTSTRAP_TBZ_URL=http://prdownloads.sourceforge.net/sbcl/$(SBCL_PPC_BOOTSTRAP_TBZ)

$(SBCL_BOOTSTRAP_TBZ):
	curl -Lo $@ $(SBCL_BOOTSTRAP_TBZ_URL)

$(SBCL_BOOTSTRAP)/src/runtime/sbcl: $(SBCL_BOOTSTRAP_TBZ)
	tar xvjf $(SBCL_BOOTSTRAP_TBZ)
	mv $(SBCL_BOOTSTRAP)/output/sbcl.core $(SBCL_BOOTSTRAP)/contrib
	touch $(SBCL_BOOTSTRAP)/src/runtime/sbcl

$(SBCL_PPC_BOOTSTRAP_TBZ):
	curl -Lo $@ $(SBCL_PPC_BOOTSTRAP_TBZ_URL)

$(SBCL_PPC_BOOTSTRAP)/src/runtime/sbcl: $(SBCL_PPC_BOOTSTRAP_TBZ)
	tar xvjf $(SBCL_PPC_BOOTSTRAP_TBZ)
	mv $(SBCL_PPC_BOOTSTRAP)/output/sbcl.core $(SBCL_PPC_BOOTSTRAP)/contrib
	touch $(SBCL_PPC_BOOTSTRAP)/src/runtime/sbcl

# (cd tests; sh run-tests.sh); \

$(SBCL_PPC)/bin/sbcl: \
	sbcl/version.lisp-expr $(SBCL_PPC_BOOTSTRAP)/src/runtime/sbcl
	@echo Building SBCL $(SBCL_VER) for powerpc, please wait ...
	(cd sbcl && sh clean.sh &&				\
	 SBCL_HOME=$(PWD)/$(SBCL_PPC_BOOTSTRAP)/contrib		\
	 PATH=$(PWD)/$(SBCL_PPC_BOOTSTRAP)/src/runtime:$(PATH)	\
	 sh make.sh > sbcl-ppc-log.txt 2>&1 &&			\
	 rm -fr $(SBCL_PPC) && mkdir -p $(SBCL_PPC) &&		\
	 INSTALL_ROOT=$(SBCL_PPC) sh install.sh)

$(SBCL_X86_64)/bin/sbcl: \
	sbcl/version.lisp-expr $(SBCL_BOOTSTRAP)/src/runtime/sbcl
	@echo Building SBCL $(SBCL_VER) for x86-64, please wait ...
	(cd sbcl && sh clean.sh &&					\
	 SBCL_ARCH=x86-64 SBCL_HOME=$(PWD)/$(SBCL_BOOTSTRAP)/contrib	\
	 PATH=$(PWD)/$(SBCL_BOOTSTRAP)/src/runtime:$(PATH)		\
	 sh make.sh > sbcl-x86_64-log.txt 2>&1 &&			\
	 (test ! -x $(shell which latex) ||				\
	     (cd doc && sh make-doc.sh && cd manual && make));		\
	 rm -fr $(SBCL_X86_64) && mkdir -p $(SBCL_X86_64) &&		\
	 INSTALL_ROOT=$(SBCL_X86_64) sh install.sh)

$(SBCL_I386)/bin/sbcl: \
	sbcl/version.lisp-expr $(SBCL_BOOTSTRAP)/src/runtime/sbcl
	@echo Building SBCL $(SBCL_VER) for i386, please wait ...
	(cd sbcl && sh clean.sh &&				\
	 SBCL_HOME=$(PWD)/$(SBCL_BOOTSTRAP)/contrib		\
	 PATH=$(PWD)/$(SBCL_BOOTSTRAP)/src/runtime:$(PATH)	\
	 sh make.sh > sbcl-i386-log.txt 2>&1 &&			\
	 (test ! -x $(shell which latex) ||			\
	     (cd doc && sh make-doc.sh && cd manual && make));	\
	 rm -fr $(SBCL_I386) && mkdir -p $(SBCL_I386) &&	\
	 INSTALL_ROOT=$(SBCL_I386) sh install.sh)

# This code allows me to build just the PowerPC dependent parts on another OS
# X box over SSH.

PPC_HOST=
PPC_USER=johnw

sbcl-$(SBCL_VER)-ppc.tar.bz2:
	if [ "$(PPC_HOST)" = "" ]; then				\
	    if [ "$(ARCH)" = "powerpc" ]; then			\
		make $(SBCL_PPC_CORE) &&			\
		tar cvjf $@ build/sbcl/ppc;			\
	    fi;							\
	else							\
	    rsync -e ssh -av --delete				\
		--exclude=.git/					\
		--exclude='/sbcl-*/'				\
		--exclude=/sbcl/obj/				\
		--exclude=/build/				\
		--exclude=/aquamacs/				\
		--exclude=/doc/					\
		--exclude=/sbcl/output/				\
		--exclude=/sbcl/tests/				\
		--exclude=/slime/				\
		--exclude=/site/				\
		--exclude=/systems/				\
		--exclude=/site-lisp/				\
		--exclude=/dist/				\
		--exclude='/sbcl*.bz2'				\
		./ $(PPC_USER)@$(PPC_HOST):/tmp/ready-lisp/ &&	\
	    ssh $(PPC_USER)@$(PPC_HOST)				\
		'(cd /tmp/ready-lisp; make ppc-tarball)' &&	\
	    scp $(PPC_USER)@$(PPC_HOST):/tmp/ready-lisp/$@ .;	\
	fi

ppc-tarball: sbcl-$(SBCL_VER)-ppc.tar.bz2

$(SBCL_PPC): sbcl-$(SBCL_VER)-ppc.tar.bz2
	if [   -f sbcl-$(SBCL_VER)-ppc.tar.bz2 -a		\
	     ! -d $(SBCL_PPC) ]; then				\
	    tar xvjf sbcl-$(SBCL_VER)-ppc.tar.bz2;		\
	fi

build/sbcl/sbcl:
	if [ ! "$(PPC_HOST)" = "" ]; then			\
	    make $(SBCL_PPC);					\
	fi
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

sbcl-bin: build/sbcl/sbcl

$(SBCL_PPC_CORE): $(SBCL_PPC)/bin/sbcl bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_PPC_LIB) $(SBCL_PPC)/bin/sbcl	\
		--core $(SBCL_PPC_LIB)/sbcl.core	\
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

sbcl-powerpc-core: $(SBCL_PPC_CORE)

$(SBCL_X86_64_CORE): $(SBCL_X86_64)/bin/sbcl bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_X86_64_LIB) $(SBCL_X86_64)/bin/sbcl	\
		--core $(SBCL_X86_64_LIB)/sbcl.core		\
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

sbcl-x86_64-core: $(SBCL_X86_64_CORE)

$(SBCL_I386_CORE): $(SBCL_I386)/bin/sbcl bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_I386_LIB) $(SBCL_I386)/bin/sbcl	\
		--core $(SBCL_I386_LIB)/sbcl.core		\
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

sbcl-i386-core: $(SBCL_I386_CORE)

sbcl: sbcl-$(ARCH)-core sbcl-bin

######################################################################

SLIME_GIT=git://github.com/nablaone/slime.git

slime-git:
	@test -f slime/slime.el || (rm -fr slime; git clone $(SLIME_GIT))

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

slime/doc/slime.pdf: slime/doc/slime.texi
	test ! -x $(shell which latex) || (cd slime/doc; make)

slime-doc: slime/doc/slime.pdf

slime-build: slime/slime.elc slime-doc

######################################################################

CL_FAD_URL=http://www.weitz.de/cl-fad/
CL_FAD_TGZ=cl-fad.tar.gz
CL_FAD_TGZ_URL=http://weitz.de/files/$(CL_FAD_TGZ)

site/$(CL_FAD_TGZ):
	@test -d site || mkdir site
	curl -Lo $@ $(CL_FAD_TGZ_URL)

site/cl-fad-$(CL_FAD_VER): site/$(CL_FAD_TGZ)
	(cd site; tar xvzf $(CL_FAD_TGZ))

cl-fad: site/cl-fad-$(CL_FAD_VER)

######################################################################

CL_PPCRE_URL=http://www.weitz.de/cl-ppcre/
CL_PPCRE_TGZ=cl-ppcre.tar.gz
CL_PPCRE_TGZ_URL=http://weitz.de/files/$(CL_PPCRE_TGZ)

site/$(CL_PPCRE_TGZ):
	@test -d site || mkdir site
	curl -Lo $@ $(CL_PPCRE_TGZ_URL)

site/cl-ppcre-$(CL_PPCRE_VER): site/$(CL_PPCRE_TGZ)
	(cd site; tar xvzf $(CL_PPCRE_TGZ))

cl-ppcre: site/cl-ppcre-$(CL_PPCRE_VER)

######################################################################

LOCAL_TIME_URL=http://common-lisp.net/project/local-time/
LOCAL_TIME_TGZ=local-time-$(LOCAL_TIME_VER).tar.gz
LOCAL_TIME_TGZ_URL=http://common-lisp.net/project/local-time/$(LOCAL_TIME_TGZ)

site/$(LOCAL_TIME_TGZ):
	@test -d site || mkdir site
	curl -Lo $@ $(LOCAL_TIME_TGZ_URL)

site/local-time-$(LOCAL_TIME_VER): site/$(LOCAL_TIME_TGZ)
	(cd site; tar xvzf $(LOCAL_TIME_TGZ))

local-time: site/local-time-$(LOCAL_TIME_VER)

######################################################################

SERIES_URL=http://series.sourceforge.net/
SERIES_TBZ=series-$(SERIES_VER).tar.bz2
SERIES_TBZ_URL=http://downloads.sourceforge.net/series/$(SERIES_TBZ)

site/$(SERIES_TBZ):
	@test -d site || mkdir site
	curl -Lo $@ $(SERIES_TBZ_URL)

site/series-$(SERIES_VER): site/$(SERIES_TBZ)
	(cd site; tar xvjf $(SERIES_TBZ))

series: site/series-$(SERIES_VER)

######################################################################

systems:
	@test -d systems || mkdir systems
	(cd systems; ln -sf ../site/*/*.asd .)

######################################################################

site-lisp/paredit.elc: site-lisp/cldoc.el site-lisp/paredit.el site-lisp/redshank.el
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

site-lisp-elc: site-lisp/paredit.elc

######################################################################

HYPERSPEC_TGZ=HyperSpec-7-0.tar.gz
HYPERSPEC_TGZ_URL=ftp://ftp.lispworks.com/pub/software_tools/reference/$(HYPERSPEC_TGZ)

doc/html/$(HYPERSPEC_TGZ):
	@test -d doc/html || mkdir doc/html
	curl -Lo $@ $(HYPERSPEC_TGZ_URL)

doc/html/HyperSpec: doc/html/$(HYPERSPEC_TGZ)
	(cd doc/html; tar xvzf $(HYPERSPEC_TGZ))
	touch $@

hyperspec: doc/html/HyperSpec

######################################################################

APP=/tmp/Ready Lisp/Ready Lisp.app

copy-docs:
	cp -p README NEWS /tmp/Ready\ Lisp
	cp -p slime/doc/slime.info* "$(APP)"/Contents/Resources/info/
	cp -p doc/info/ansi* "$(APP)"/Contents/Resources/info/
	cp -p $(SBCL_I386)/share/info/*.info* "$(APP)"/Contents/Resources/info/
	patch -p1 -d "$(APP)"/Contents/Resources < doc/info/dir.patch
	rsync -av $(SBCL_I386)/share/man/ "$(APP)"/Contents/Resources/man/
	mkdir "$(APP)"/Contents/Resources/pdf/
	cp -p $(SBCL_I386)/share/doc/sbcl/*.pdf "$(APP)"/Contents/Resources/pdf/
	cp -p slime/doc/*.pdf "$(APP)"/Contents/Resources/pdf/
	mkdir "$(APP)"/Contents/Resources/html/
	rsync -av doc/html/HyperSpec "$(APP)"/Contents/Resources/html
	rsync -av slime/doc/html/ "$(APP)"/Contents/Resources/html/slime/
	rsync -av $(SBCL_I386)/share/doc/sbcl/html/asdf \
		"$(APP)"/Contents/Resources/html
	rsync -av $(SBCL_I386)/share/doc/sbcl/html/sbcl \
		"$(APP)"/Contents/Resources/html
	mv "$(APP)"/Contents/Resources/Aquamacs\ Help \
		"$(APP)"/Contents/Resources/html
	mv "$(APP)"/Contents/Resources/Emacs\ Lisp\ Reference \
		"$(APP)"/Contents/Resources/html
	mv "$(APP)"/Contents/Resources/elisp \
		"$(APP)"/Contents/Resources/html
	mv "$(APP)"/Contents/Resources/Emacs\ Manual \
		"$(APP)"/Contents/Resources/html
	chflags hidden /tmp/Ready\ Lisp/README
	chflags hidden /tmp/Ready\ Lisp/NEWS

build/ReadyLisp-$(VERSION).dmg:
	rm -fr /tmp/Ready\ Lisp
	mkdir /tmp/Ready\ Lisp
	mkdir /tmp/Ready\ Lisp/.background
	cp -p dist/image.png /tmp/Ready\ Lisp/.background
	cp -p dist/DS_Store /tmp/Ready\ Lisp/.DS_Store
	rsync -aE aquamacs/"$(AQUA_APP)"/ "$(APP)"/
	rsync -a --delete slime/ \
		"$(APP)"/Contents/Resources/site-lisp/edit-modes/slime/
	rsync -av site-lisp/ "$(APP)"/Contents/Resources/site-lisp/
	patch -p0 -d "$(APP)"/Contents/Resources < site-lisp/site-start.patch
	rsync -av --exclude=share/ --exclude=bin/sbcl --exclude=lib/sbcl/sbcl.core \
		build/sbcl/ "$(APP)"/Contents/Resources/sbcl/
	rsync -av --exclude=doc/ --exclude=obj/ --exclude=output/ \
		--exclude=tests/ --exclude=tools-for-build/ \
		sbcl/ "$(APP)"/Contents/Resources/sbcl/source/
	rsync -av site/ "$(APP)"/Contents/Resources/sbcl/site/
	rsync -av systems/ "$(APP)"/Contents/Resources/sbcl/systems/
	test ! -x $(shell which latex) || make copy-docs
	chmod -R go+rX /tmp/Ready\ Lisp
	(cd /tmp/Ready\ Lisp; ln -s /Applications .)
	(cd /tmp; \
	 hdiutil create -format UDBZ -srcfolder Ready\ Lisp \
		ReadyLisp-$(VERSION).dmg)
	mv /tmp/ReadyLisp-$(VERSION).dmg build

disk-image: build/ReadyLisp-$(VERSION).dmg

clean:
	rm -fr build *.dmg
	test ! -d slime || find slime -name '*.fasl' -delete
	test ! -d slime || find slime -name '*.elc' -delete
	find site-lisp -name '*.elc' -delete
	test ! -d sbcl || (cd sbcl; sh clean.sh)
	test ! -d slime/doc || (cd slime/doc; make clean)

scour: clean
	rm -fr aquamacs sbcl slime systems site
