SBCL_VERSION = 1.0.12
VERSION = 10.5.1-2

SBCL_X86_64 = /usr/local/stow/sbcl-$(SBCL_VERSION)-x86_64
SBCL_I386   = /usr/local/stow/sbcl-$(SBCL_VERSION)-i386
SBCL_PPC    = /usr/local/stow/sbcl-$(SBCL_VERSION)-ppc

all: dependencies

#all:	sbcl \
#	sbcl.core-with-slime-x86_64 \
#	sbcl.core-with-slime-i386

######################################################################

dependencies: aquamacs sbcl slime cl-fad cl-ppcre local-time series systems
	echo Dependencies are up-to-date.

######################################################################

AQUA_VER=1.3b
AQUA_DMG=Aquamacs-Emacs-$(AQUA_VER).dmg
AQUA_URL=http://www.tardis.ed.ac.uk/~dreitter/$(AQUA_DMG)
AQUA_APP="Aquamacs Emacs.app"

aquamacs/$(AQUA_DMG):
	test -d aquamacs || mkdir aquamacs
	curl -O $@ $(AQUA_URL)

aquamacs/$(AQUA_APP): aquamacs/$(AQUA_DMG)
	hdiutil attach aquamacs/$(AQUA_DMG)
	cp -R /Volumes/Aquamacs\ Emacs/$(AQUA_APP) aquamacs
	hdiutil detach Aquamacs\ Eamcs

aquamacs: aquamacs/$(AQUA_APP)

######################################################################

SBCL_GIT=git://sbcl.boinkor.net/sbcl.git

sbcl:
	git clone $(SBCL_GIT)

######################################################################

SLIME_GIT=git://github.com/nablaone/slime.git

slime:
	git clone $(SLIME_GIT)

######################################################################

site:
	mkdir site

######################################################################

CL_FAD_URL=http://www.weitz.de/cl-fad/
CL_FAD_VER=0.6.2
CL_FAD_TGZ=cl-fad.tar.gz
CL_FAD_TGZ_URL=http://weitz.de/files/$(CL_FAD_TGZ)

site/$(CL_FAD_TGZ):
	curl -O $@ $(CL_FAD_TGZ_URL)

site/cl-fad: site site/$(CL_FAD_TGZ)
	(cd site; tar xvzf $(CL_FAD_TGZ))

cl-fad: site/cl-fad

######################################################################

CL_PPCRE_URL=http://www.weitz.de/cl-ppcre/
CL_PPCRE_TGZ=cl-ppcre.tar.gz
CL_PPCRE_TGZ_URL=http://weitz.de/files/$(CL_PPCRE_TGZ)

site/$(CL_PPCRE_TGZ):
	curl -O $@ $(CL_PPCRE_TGZ_URL)

site/cl-ppcre: site site/$(CL_PPCRE_TGZ)
	(cd site; tar xvzf $(CL_PPCRE_TGZ))

cl-ppcre: site/cl-ppcre

######################################################################

LOCAL_TIME_URL=http://common-lisp.net/project/local-time/
LOCAL_TIME_VER=0.9.3
LOCAL_TIME_TGZ=local-time-$(LOCAL_TIME_VER).tar.gz
LOCAL_TIME_TGZ_URL=http://common-lisp.net/project/local-time/$(LOCAL_TIME_TGZ)

site/$(LOCAL_TIME_TGZ):
	curl -O $@ $(LOCAL_TIME_TGZ_URL)

site/local-time: site site/$(LOCAL_TIME_TGZ)
	(cd site; tar xvzf $(LOCAL_TIME_TGZ))

local-time: site/local-time

######################################################################

SERIES_URL=http://series.sourceforge.net/
SERIES_VER=2.2.9
SERIES_TBZ=series-$(SERIES_VER).tar.bz2
SERIES_TBZ_URL=http://downloads.sourceforge.net/series/$(SERIES_TBZ)

site/$(SERIES_TGZ):
	curl -O $@ $(SERIES_TBZ_URL)

site/series: site site/$(SERIES_TBZ)
	(cd site; tar xvjf $(SERIES_TBZ))

series: site/series

######################################################################

systems:
	(cd systems; ln -sf ../site/*/*.asd .)

######################################################################

sbcl: $(SBCL_X86_64)/bin/sbcl $(SBCL_I386)/bin/sbcl
	lipo -create \
		-arch x86_64 $(SBCL_X86_64)/bin/sbcl \
		-arch i386   $(SBCL_I386)/bin/sbcl \
		-arch ppc    $(SBCL_PPC)/bin/sbcl \
		-output $@

sbcl.core-with-slime-x86_64: $(SBCL_X86_64) bootstrap.lisp
	find $(HOME)/Library/Lisp . -name '*.fasl' -exec rm {} \;
	rm -fr ~/.slime
	$(SBCL_X86_64)/bin/sbcl \
		--core $(SBCL_X86_64)/lib/sbcl/sbcl.core \
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

sbcl.core-with-slime-i386: $(SBCL_I386) bootstrap.lisp
	find $(HOME)/Library/Lisp . -name '*.fasl' -exec rm {} \;
	rm -fr ~/.slime
	$(SBCL_I386)/bin/sbcl \
		--core $(SBCL_I386)/lib/sbcl/sbcl.core \
		--load bootstrap.lisp
	mv sbcl.core-with-slime $@

sbcl.core-with-slime-ppc: $(SBCL_PPC) bootstrap.lisp
	find $(HOME)/.sbcl . -name '*.fasl' -exec rm {} \;
	rm -fr ~/.slime
	$(SBCL_PPC)/bin/sbcl \
		--core $(SBCL_PPC)/lib/sbcl/sbcl.core \
		--load bootstrap.lisp \
		--eval "(sb-ext:save-lisp-and-die \"$@\")"

RESOURCES = $(shell pwd)/Ready Lisp.app/Contents/Resources

elc:
	find site-lisp -type d ! -name CVS ! -name doc ! -name html -print | \
	while read dir; do \
	    EMACSDATA="$(RESOURCES)/etc" \
	    EMACSDOC="$(RESOURCES)/etc" \
	    EMACSLOADPATH="$(RESOURCES)/lisp:$(RESOURCES)/site-lisp:$(shell pwd)/site-lisp:$(shell pwd)/slime:$(shell pwd)/slime/contrib" \
	    EMACSPATH="$(RESOURCES)/libexec" \
	    ./Ready\ Lisp.app/Contents/MacOS/bin/emacs -q --no-site-file -batch \
		-l slime/slime.el -f batch-byte-compile $$dir/*.el; \
	done
	rm -f site-lisp/init-lisp.elc site-lisp/site-start.elc

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
		ReadyLisp-$(SBCL_VERSION)-$(VERSION).dmg)
	mv /tmp/ReadyLisp-$(SBCL_VERSION)-$(VERSION).dmg .

clean:
	rm -f sbcl sbcl.core-with-slime-x86_64 sbcl.core-with-slime-i386
	find site-lisp -name '*.elc' -exec rm {} \;

# This must be run as root on my machine (sudo make -j1 bootstrap); it also
# assumes CMUCL is installed.
bootstrap:
	(cd /usr/local/stow && \
	 stow -D $(shell basename $(SBCL_X86_64)) && \
	 stow -D $(shell basename $(SBCL_I386)) && \
	 rm -fr $(SBCL_X86_64) $(SBCL_I386) && \
	 (cd /usr/local/src && \
	  rm -fr sbcl-$(SBCL_VERSION) && \
	  tar xvjf ~johnw/Public/lisp/sbcl-$(SBCL_VERSION)-source.tar.bz2 && \
	  cd sbcl-$(SBCL_VERSION) && \
	  sh make.sh 'lisp -batch -noinit' && \
	    INSTALL_ROOT=$(SBCL_I386) sh install.sh) && \
	 stow $(shell basename $(SBCL_I386)) && \
	 (cd /usr/local/src/sbcl-$(SBCL_VERSION) && \
	  sh clean.sh && \
	  SBCL_ARCH=x86-64 sh make.sh && \
	    INSTALL_ROOT=$(SBCL_X86_64) sh install.sh) && \
	 stow -D $(shell basename $(SBCL_I386)) && \
	 stow $(shell basename $(SBCL_X86_64)))
