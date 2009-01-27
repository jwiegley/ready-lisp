#!/bin/bash

local=false
if [[ "$1" == "--local" ]]; then
    local=true
    shift 1
fi

PPC_HOST=$1

# Bootstrap a Ready Lisp disk image from complete scratch.  Just make sure all
# relevant version numbers and URLs have been updated and pushed to the Github
# repository first.

HERE=$(pwd)

if [ -d /tmp/ready-lisp ]; then
    echo Removing previous ready-lisp build ...
    rm -fr /tmp/ready-lisp
fi

if [[ -n "$PPC_HOST" ]]; then
    ssh $PPC_HOST rm -fr /tmp/ready-lisp || exit 1
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

echo Moving final disk image back to source tree ...
mv build/ReadyLisp-*.dmg $HERE

echo Ready Lisp build complete.

# build.sh ends here
