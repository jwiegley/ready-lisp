VERSION = $(date +%Y%m%d)

SBCL_VER = $(shell ./sbcl-ver)

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

all: dependencies sbcl slime-elc site-lisp-elc dist

######################################################################

dependencies: aquamacs sbcl-git slime-git \
	cl-fad cl-ppcre local-time series systems
	@echo Dependencies are up-to-date.

######################################################################

AQUA_VER=1.3b
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
	 rm -fr $(SBCL_PPC) && mkdir -p $(SBCL_PPC) && \
	 INSTALL_ROOT=$(SBCL_PPC) sh install.sh)

sbcl-ppc: $(SBCL_PPC)/bin/sbcl

$(SBCL_X86_64)/bin/sbcl: sbcl/version.lisp-expr
	(cd sbcl && sh clean.sh && SBCL_ARCH=x86-64 sh make.sh && \
	 rm -fr $(SBCL_X86_64) && mkdir -p $(SBCL_X86_64) && \
	 INSTALL_ROOT=$(SBCL_X86_64) sh install.sh)

sbcl-x86_64: $(SBCL_X86_64)/bin/sbcl

$(SBCL_I386)/bin/sbcl: sbcl/version.lisp-expr
	(cd sbcl && sh clean.sh && sh make.sh && \
	 rm -fr $(SBCL_I386) && mkdir -p $(SBCL_I386) && \
	 INSTALL_ROOT=$(SBCL_I386) sh install.sh)

sbcl-i386: $(SBCL_I386)/bin/sbcl

sbcl-bin: sbcl-$(shell uname -p)
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

$(SBCL_PPC_CORE): sbcl-ppc bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_PPC_LIB) $(SBCL_PPC)/bin/sbcl \
		--core $(SBCL_PPC_LIB)/sbcl.core \
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

$(SBCL_X86_64_CORE): sbcl-x86_64 bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_X86_64_LIB) $(SBCL_X86_64)/bin/sbcl \
		--core $(SBCL_X86_64_LIB)/sbcl.core \
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

sbcl-x86_64-core: $(SBCL_X86_64_CORE)

$(SBCL_I386_CORE): sbcl-i386 bootstrap.lisp
	find slime site -name '*.fasl' -delete
	rm -fr ~/.slime
	SBCL_HOME=$(SBCL_I386_LIB) $(SBCL_I386)/bin/sbcl \
		--core $(SBCL_I386_LIB)/sbcl.core \
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

# Building the i386 core is preceded by building the x86_64 core
sbcl-i386-core: $(SBCL_I386_CORE) sbcl-x86_64-core

ppc: sbcl-ppc-core
	tar cvjf sbcl-$(SBCL_VER)-ppc.tar.bz2 build/sbcl/ppc

sbcl: sbcl-$(shell uname -p)-core sbcl-bin

######################################################################

SLIME_GIT=git://github.com/nablaone/slime.git

slime-git:
	@test -d slime || git clone $(SLIME_GIT)

slime-elc:
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

######################################################################

CL_FAD_URL=http://www.weitz.de/cl-fad/
CL_FAD_VER=0.6.2
CL_FAD_TGZ=cl-fad.tar.gz
CL_FAD_TGZ_URL=http://weitz.de/files/$(CL_FAD_TGZ)

site/$(CL_FAD_TGZ):
	@test -d site || mkdir site
	curl -Lo $@ $(CL_FAD_TGZ_URL)

site/cl-fad-$(CL_FAD_VER): site site/$(CL_FAD_TGZ)
	(cd site; tar xvzf $(CL_FAD_TGZ))

cl-fad: site/cl-fad-$(CL_FAD_VER)

######################################################################

CL_PPCRE_URL=http://www.weitz.de/cl-ppcre/
CL_PPCRE_VER=1.3.2
CL_PPCRE_TGZ=cl-ppcre.tar.gz
CL_PPCRE_TGZ_URL=http://weitz.de/files/$(CL_PPCRE_TGZ)

site/$(CL_PPCRE_TGZ):
	@test -d site || mkdir site
	curl -Lo $@ $(CL_PPCRE_TGZ_URL)

site/cl-ppcre-$(CL_PPCRE_VER): site site/$(CL_PPCRE_TGZ)
	(cd site; tar xvzf $(CL_PPCRE_TGZ))

cl-ppcre: site/cl-ppcre-$(CL_PPCRE_VER)

######################################################################

LOCAL_TIME_URL=http://common-lisp.net/project/local-time/
LOCAL_TIME_VER=0.9.3
LOCAL_TIME_TGZ=local-time-$(LOCAL_TIME_VER).tar.gz
LOCAL_TIME_TGZ_URL=http://common-lisp.net/project/local-time/$(LOCAL_TIME_TGZ)

site/$(LOCAL_TIME_TGZ):
	@test -d site || mkdir site
	curl -Lo $@ $(LOCAL_TIME_TGZ_URL)

site/local-time-$(LOCAL_TIME_VER): site site/$(LOCAL_TIME_TGZ)
	(cd site; tar xvzf $(LOCAL_TIME_TGZ))

local-time: site/local-time-$(LOCAL_TIME_VER)

######################################################################

SERIES_URL=http://series.sourceforge.net/
SERIES_VER=2.2.9
SERIES_TBZ=series-$(SERIES_VER).tar.bz2
SERIES_TBZ_URL=http://downloads.sourceforge.net/series/$(SERIES_TBZ)

site/$(SERIES_TBZ):
	@test -d site || mkdir site
	curl -Lo $@ $(SERIES_TBZ_URL)

site/series-$(SERIES_VER): site site/$(SERIES_TBZ)
	(cd site; tar xvjf $(SERIES_TBZ))

series: site/series-$(SERIES_VER)

######################################################################

systems:
	@test -d systems || mkdir systems
	(cd systems; ln -sf ../site/*/*.asd .)

######################################################################

site-lisp-elc:
	find site-lisp -name '*.el' ! -name init-lisp.el -type f | \
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
		-L site-lisp \
		--eval '(setq byte-compile-warnings nil)' \
		-batch -f batch-byte-compile $$file; \
	done

######################################################################

install: all
	rsync -av --delete slime/ \
		Ready\ Lisp.app/Contents/Resources/site-lisp/edit-modes/slime/
	rsync -av site-lisp/ Ready\ Lisp.app/Contents/Resources/site-lisp/
	cp -p slime/doc/slime.info* \
		Ready\ Lisp.app/Contents/Resources/info/
	cp -p info/* Ready\ Lisp.app/Contents/Resources/info/
	cp -p $(SBCL_I386)/share/info/*.info* \
		Ready\ Lisp.app/Contents/Resources/info/
	rsync -av $(SBCL_I386)/share/man/ \
		Ready\ Lisp.app/Contents/Resources/man/
	-mkdir -p Ready\ Lisp.app/Contents/Resources/doc/
	cp -p $(SBCL_I386)/share/doc/sbcl/*.pdf \
		Ready\ Lisp.app/Contents/Resources/doc/
	cp -p slime/doc/*.pdf \
		Ready\ Lisp.app/Contents/Resources/doc/
	-mkdir -p Ready\ Lisp.app/Contents/Resources/html/
	rsync -av --delete $(HOME)/Projects/dpans2texi-1.03/ansicl.html/ \
		Ready\ Lisp.app/Contents/Resources/html/hyperspec/
	rsync -av --delete slime/doc/html/ \
		Ready\ Lisp.app/Contents/Resources/html/slime/
	rsync -av --delete $(SBCL_I386)/share/doc/sbcl/html/asdf/ \
		Ready\ Lisp.app/Contents/Resources/html/asdf/
	rsync -av --delete $(SBCL_I386)/share/doc/sbcl/html/sbcl/ \
		Ready\ Lisp.app/Contents/Resources/html/sbcl/
	rsync -av --delete site/ Ready\ Lisp.app/Contents/Resources/sbcl/site/
	ln -f bootstrap.lisp Ready\ Lisp.app/Contents/Resources/
	rm -fr Ready\ Lisp.app/Contents/Resources/sbcl/*/share
	rm -f Ready\ Lisp.app/Contents/Resources/sbcl/*/bin/sbcl
	rm -f Ready\ Lisp.app/Contents/Resources/sbcl/*/lib/sbcl/sbcl.core*
	ln -f sbcl Ready\ Lisp.app/Contents/Resources/sbcl/
	ln -f sbcl.core-with-slime-i386 Ready\ Lisp.app/Contents/Resources/sbcl/
	ln -f sbcl.core-with-slime-x86_64 Ready\ Lisp.app/Contents/Resources/sbcl/
	ln -f sbcl.core-with-slime-ppc Ready\ Lisp.app/Contents/Resources/sbcl/
	chmod -R go+rX .

uninstall:
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/bootstrap.lisp
	rm -fr aquamacs/Aquamacs\ Emacs.app/Contents/Resources/sbcl*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/site-lisp/cldoc.el*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/site-lisp/init-lisp.el*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/site-lisp/paredit.el*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/site-lisp/redshank.el*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/site-lisp/site-start.el*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/info/ansicl*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/info/slime.info*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/info/sbcl.info*
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/sbcl/sbcl
	rm -f aquamacs/Aquamacs\ Emacs.app/Contents/Resources/sbcl/sbcl.core*
	rm -fr aquamacs/Aquamacs\ Emacs.app/Contents/Resources/site-lisp/edit-modes/slime

dist: install
	rm -fr /tmp/Ready\ Lisp
	mkdir /tmp/Ready\ Lisp
	rsync -aEHS Ready\ Lisp.app /tmp/Ready\ Lisp
	cp -p README.txt NEWS.txt /tmp/Ready\ Lisp
	(cd /tmp; \
	 hdiutil create -format UDBZ -srcfolder Ready\ Lisp \
		ReadyLisp-$(SBCL_VER)-$(VERSION).dmg)
	mv /tmp/ReadyLisp-$(SBCL_VER)-$(VERSION).dmg .

clean:
	rm -fr build *.dmg
	find site-lisp -name '*.elc' -delete

scour: clean
	rm -fr sbcl slime systems site
