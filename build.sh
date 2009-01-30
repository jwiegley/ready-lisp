#!/bin/bash

TMPDIR=/tmp

local=false
if [[ "$1" == "--local" ]]; then
    local=true
    shift 1
fi

make=false
if [[ "$1" == "--make" ]]; then
    make=true
    shift 1
fi

PPC_HOST=$1

# Bootstrap a Ready Lisp disk image from complete scratch.  Just make sure all
# relevant version numbers and URLs have been updated and pushed to the Github
# repository first.

HERE=$(pwd)

if [[ $make == true && -d $TMPDIR/ready-lisp ]]; then
    echo Updating changed files in temporary build tree ...
    rsync -rlpgoDv		  \
	--exclude=.git/	  \
	--exclude='.git*'	  \
	--exclude='*.dmg'	  \
	--exclude='build.log' \
	--exclude='*.fasl'	  \
	./ $TMPDIR/ready-lisp/
else
    if [[ -d $TMPDIR/ready-lisp ]]; then
	echo Removing previous ready-lisp build ...
	rm -fr $TMPDIR/ready-lisp
    fi

    cd $TMPDIR

    if [[ $local == true ]]; then
	echo Copying source tree to $TMPDIR/ready-lisp ...
	rsync -a ~/src/ready-lisp . || exit 1
    else
	echo Cloning ready-lisp from GitHub to $TMPDIR/ready-lisp ...
	git clone git://github.com/jwiegley/ready-lisp.git || exit 1
    fi
fi

if [[ -n "$PPC_HOST" ]]; then
    cd $TMPDIR/ready-lisp && make PPC_HOST=$PPC_HOST || exit 1
else
    cd $TMPDIR/ready-lisp && make || exit 1
fi

DISK_IMAGE=ReadyLisp-$(date +%Y%m%d).dmg

echo Moving final disk image back to source tree ...
mv build/$DISK_IMAGE $HERE

echo Zipping disk image to guard against improper MIME types on download ...
cd $HERE && zip -r $DISK_IMAGE.zip $DISK_IMAGE

echo Ready Lisp build complete.

# build.sh ends here
