# These are the versions that Ready Lisp is known to work with.  Update at
# your own risk!  All you have to do is the change the version number here,
# and the corresponding file will automatically be uploaded from the author's
# server.  Note that paredit.el and redshank.el must be updated manually.

VERSION	       = $(shell date +%Y%m%d)
SBCL_VER       = $(shell ./sbcl-ver)
SLIME_VER      = $(shell ./slime-ver)

AQUA_VER       = 1.3b

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

all: dependencies sbcl slime-build site-lisp-elc disk-image

update:
	git pull
	test -d sbcl && (cd sbcl && git pull)
	test -d slime && (cd slime && git pull)

######################################################################

dependencies: aquamacs sbcl-git slime-git hyperspec cl-fad cl-ppcre local-time series systems

######################################################################

AQUA_DMG=Aquamacs-Emacs-$(AQUA_VER).dmg
AQUA_URL=http://www.tardis.ed.ac.uk/~dreitter/$(AQUA_DMG)
AQUA_APP=Aquamacs Emacs.app

RESOURCES = aquamacs/$(AQUA_APP)/Contents/Resources

aquamacs/$(AQUA_DMG):
	@test -d aquamacs || mkdir aquamacs
	curl -Lo "$@" "$(AQUA_URL)"

aquamacs-app: aquamacs/$(AQUA_DMG)
	@test -d "aquamacs/$(AQUA_APP)" || \
	    (hdiutil attach aquamacs/$(AQUA_DMG) && \
	    cp -R "/Volumes/Aquamacs Emacs/$(AQUA_APP)" aquamacs && \
	    hdiutil detach /Volumes/Aquamacs\ Emacs)

aquamacs: aquamacs-app

apply-patches: site-lisp/site-start.patch
	patch -N -p0 < site-lisp/site-start.patch

######################################################################

SBCL_GIT=git://sbcl.boinkor.net/sbcl.git

sbcl-git:
	@test -d sbcl || git clone $(SBCL_GIT)

sbcl/version.lisp-expr: sbcl-git

# (cd tests; sh run-tests.sh); \

$(SBCL_PPC)/bin/sbcl: sbcl-git
	(cd sbcl && sh clean.sh && sh make.sh && \
	 (cd doc && sh make-doc.sh) && \
	 rm -fr $(SBCL_PPC) && mkdir -p $(SBCL_PPC) && \
	 INSTALL_ROOT=$(SBCL_PPC) sh install.sh)

$(SBCL_X86_64)/bin/sbcl: sbcl/version.lisp-expr
	(cd sbcl && sh clean.sh && SBCL_ARCH=x86-64 sh make.sh && \
	 rm -fr $(SBCL_X86_64) && mkdir -p $(SBCL_X86_64) && \
	 INSTALL_ROOT=$(SBCL_X86_64) sh install.sh)

$(SBCL_I386)/bin/sbcl: sbcl/version.lisp-expr
	(cd sbcl && sh clean.sh && sh make.sh && \
	 (cd doc && sh make-doc.sh) && \
	 rm -fr $(SBCL_I386) && mkdir -p $(SBCL_I386) && \
	 INSTALL_ROOT=$(SBCL_I386) sh install.sh)

build/sbcl/sbcl: $(SBCL_I386)/bin/sbcl $(SBCL_X86_64)/bin/sbcl
	if [   -f sbcl-$(SBCL_VER)-ppc.tar.bz2 -a \
	     ! -d $(SBCL_PPC) ]; then \
	    tar xvjf sbcl-$(SBCL_VER)-ppc.tar.bz2; \
	fi
	if [ -x $(SBCL_PPC)/bin/sbcl ]; then \
	    lipo -create \
		-arch x86_64 $(SBCL_X86_64)/bin/sbcl \
		-arch i386   $(SBCL_I386)/bin/sbcl \
		-arch ppc    $(SBCL_PPC)/bin/sbcl \
		-output $@; \
	else \
	    lipo -create \
		-arch x86_64 $(SBCL_X86_64)/bin/sbcl \
		-arch i386   $(SBCL_I386)/bin/sbcl \
		-output $@; \
	fi

$(SBCL_PPC_CORE): $(SBCL_PPC)/bin/sbcl bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_PPC_LIB) $(SBCL_PPC)/bin/sbcl \
		--core $(SBCL_PPC_LIB)/sbcl.core \
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

$(SBCL_X86_64_CORE): $(SBCL_X86_64)/bin/sbcl bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_X86_64_LIB) $(SBCL_X86_64)/bin/sbcl \
		--core $(SBCL_X86_64_LIB)/sbcl.core \
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

sbcl-x86_64-core: $(SBCL_X86_64_CORE)

$(SBCL_I386_CORE): $(SBCL_I386)/bin/sbcl bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_I386_LIB) $(SBCL_I386)/bin/sbcl \
		--core $(SBCL_I386_LIB)/sbcl.core \
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

# Building the i386 core is preceded by building the x86_64 core
sbcl-i386-core: $(SBCL_I386_CORE) sbcl-x86_64-core

ppc-tarball: sbcl-ppc-core
	tar cvjf sbcl-$(SBCL_VER)-ppc.tar.bz2 build/sbcl/ppc

sbcl: sbcl-$(shell uname -p)-core build/sbcl/sbcl

######################################################################

SLIME_GIT=git://github.com/nablaone/slime.git

slime-git:
	@test -d slime || git clone $(SLIME_GIT)

slime/slime.elc: slime/slime.el
	find slime -name '*.el' -type f | \
	while read file; do \
	    EMACSDATA="$(RESOURCES)/etc" \
	    EMACSDOC="$(RESOURCES)/etc" \
	    EMACSPATH="$(RESOURCES)/libexec" \
	    "$(RESOURCES)"/../MacOS/"Aquamacs Emacs" -q --no-site-file \
		-L "$(RESOURCES)"/lisp \
		-L "$(RESOURCES)"/lisp/international \
		-L "$(RESOURCES)"/lisp/emacs-lisp \
		-L "$(RESOURCES)"/lisp/progmodes \
		-L "$(RESOURCES)"/lisp/net \
		-L slime \
		-L slime/contrib \
		-l slime/slime.el \
		--eval '(setq byte-compile-warnings nil)' \
		-batch -f batch-byte-compile $$file; \
	done

slime-doc: slime/doc/slime.pdf
	(cd slime/doc; make)

slime-build: slime/slime.elc #slime-doc

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
	echo $? | while read file; do \
	    EMACSDATA="$(RESOURCES)/etc" \
	    EMACSDOC="$(RESOURCES)/etc" \
	    EMACSPATH="$(RESOURCES)/libexec" \
	    "$(RESOURCES)"/../MacOS/"Aquamacs Emacs" -q --no-site-file \
		-L "$(RESOURCES)"/lisp \
		-L "$(RESOURCES)"/lisp/international \
		-L "$(RESOURCES)"/lisp/emacs-lisp \
		-L "$(RESOURCES)"/lisp/progmodes \
		-L "$(RESOURCES)"/lisp/net \
		-L site-lisp -l slime/slime.elc \
		--eval '(setq byte-compile-warnings nil)' \
		-batch -f batch-byte-compile $$file; \
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

build/ReadyLisp-$(VERSION).dmg:
	rm -fr /tmp/Ready\ Lisp
	mkdir /tmp/Ready\ Lisp
	mkdir /tmp/Ready\ Lisp/.background
	cp -p README NEWS /tmp/Ready\ Lisp
	cp -p dist/image.png /tmp/Ready\ Lisp/.background
	cp -p dist/DS_Store /tmp/Ready\ Lisp/.DS_Store
	rsync -aE aquamacs/"$(AQUA_APP)"/ "$(APP)"/
	rsync -a --delete slime/ \
		"$(APP)"/Contents/Resources/site-lisp/edit-modes/slime/
	rsync -av site-lisp/ "$(APP)"/Contents/Resources/site-lisp/
	patch -p0 -d "$(APP)"/Contents/Resources < site-lisp/site-start.patch
	patch -p1 -d "$(APP)"/Contents/Resources < doc/info/dir.patch
	rsync -av --exclude=share/ --exclude=bin/sbcl --exclude=lib/sbcl/sbcl.core \
		build/sbcl/ "$(APP)"/Contents/Resources/sbcl/
	rsync -av site/ "$(APP)"/Contents/Resources/sbcl/site/
	rsync -av systems/ "$(APP)"/Contents/Resources/sbcl/systems/
	chmod -R go+rX /tmp/Ready\ Lisp
	chflags hidden /tmp/Ready\ Lisp/README
	chflags hidden /tmp/Ready\ Lisp/NEWS
	(cd /tmp/Ready\ Lisp; ln -s /Applications .)
	(cd /tmp; \
	 hdiutil create -format UDBZ -srcfolder Ready\ Lisp \
		ReadyLisp-$(VERSION).dmg)
	mv /tmp/ReadyLisp-$(VERSION).dmg build

disk-image: build/ReadyLisp-$(VERSION).dmg

dist2:
	rm -fr /tmp/Ready\ Lisp
	mkdir /tmp/Ready\ Lisp
	mkdir /tmp/Ready\ Lisp/.background
	cp -p README NEWS /tmp/Ready\ Lisp
	cp -p dist/image.png /tmp/Ready\ Lisp/.background
	cp -p dist/DS_Store /tmp/Ready\ Lisp/.DS_Store
	rsync -aE aquamacs/"$(AQUA_APP)"/ "$(APP)"/
	rsync -a --delete slime/ \
		"$(APP)"/Contents/Resources/site-lisp/edit-modes/slime/
	rsync -av site-lisp/ "$(APP)"/Contents/Resources/site-lisp/
	cp -p slime/doc/slime.info* "$(APP)"/Contents/Resources/info/
	cp -p doc/info/ansi* "$(APP)"/Contents/Resources/info/
	cp -p $(SBCL_I386)/share/info/*.info* "$(APP)"/Contents/Resources/info/
	patch -p0 -d "$(APP)"/Contents/Resources < site-lisp/site-start.patch
	patch -p1 -d "$(APP)"/Contents/Resources < doc/info/dir.patch
	rsync -av $(SBCL_I386)/share/man/ "$(APP)"/Contents/Resources/man/
	mkdir Ready\ Lisp.app/Contents/Resources/pdf/
	cp -p $(SBCL_I386)/share/doc/sbcl/*.pdf "$(APP)"/Contents/Resources/pdf/
	cp -p slime/doc/*.pdf "$(APP)"/Contents/Resources/pdf/
	mkdir Ready\ Lisp.app/Contents/Resources/html/
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
	rsync -av --exclude=share/ --exclude=bin/sbcl --exclude=lib/sbcl/sbcl.core \
		build/sbcl/ "$(APP)"/Contents/Resources/sbcl/
	rsync -av site/ "$(APP)"/Contents/Resources/sbcl/site/
	rsync -av systems/ "$(APP)"/Contents/Resources/sbcl/systems/
	chmod -R go+rX /tmp/Ready\ Lisp
	chflags hidden /tmp/Ready\ Lisp/README
	chflags hidden /tmp/Ready\ Lisp/NEWS
	(cd /tmp/Ready\ Lisp; ln -s /Applications .)
	(cd /tmp; \
	 hdiutil create -format UDBZ -srcfolder Ready\ Lisp \
		ReadyLisp-$(VERSION).dmg)
	mv /tmp/ReadyLisp-$(VERSION).dmg build

clean:
	rm -fr build *.dmg
	find slime -name '*.fasl' -delete
	find slime site-lisp -name '*.elc' -delete

scour: clean
	rm -fr sbcl slime systems site
