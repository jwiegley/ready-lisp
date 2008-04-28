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

rm -fr /tmp/ready-lisp

if [[ -n "$PPC_HOST" ]]; then
    ssh $PPC_HOST rm -fr /tmp/ready-lisp || exit 1
fi

if [[ $local == true ]]; then
    rsync -a ~/src/ready-lisp . || exit 1
else
    git clone git://github.com/jwiegley/ready-lisp.git || exit 1
fi

cd ready-lisp && make PPC_HOST=$PPC_HOST || exit 1

mv build/ReadyLisp-*.dmg $HERE

# build.sh ends here
