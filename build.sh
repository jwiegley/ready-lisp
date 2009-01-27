#!/bin/bash

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

if [[ -d /tmp/ready-lisp ]]; then
    if [[ $make == true ]]; then
	echo Updating changed files in temporary build tree ...
	rsync -rlpgoDv		  \
	    --exclude=.git/	  \
	    --exclude='.git*'	  \
	    --exclude='*.dmg'	  \
	    --exclude='build.log' \
	    --exclude='*.fasl'	  \
	    ./ /tmp/ready-lisp/
    else
	echo Removing previous ready-lisp build ...
	rm -fr /tmp/ready-lisp
    fi
fi

cd /tmp

if [[ $local == true ]]; then
    echo Copying source tree to /tmp/ready-lisp ...
    rsync -a ~/src/ready-lisp . || exit 1
else
    echo Cloning ready-lisp from GitHub to /tmp/ready-lisp ...
    git clone git://github.com/jwiegley/ready-lisp.git || exit 1
fi

if [[ -n "$PPC_HOST" ]]; then
    cd ready-lisp && make PPC_HOST=$PPC_HOST || exit 1
else
    cd ready-lisp && make || exit 1
fi

DISK_IMAGE=ReadyLisp-$(date +%Y%m%d).dmg

echo Moving final disk image back to source tree ...
mv build/$DISK_IMAGE $HERE

echo Zipping disk image to guard against improper MIME types on download ...
zip -r $DISK_IMAGE.zip $DISK_IMAGE

echo Ready Lisp build complete.

# build.sh ends here
