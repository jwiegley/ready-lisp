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

PWD=$(pwd)

cd /tmp

rm -fr ready-lisp

if [[ -n "$PPC_HOST" ]]; then
    ssh $PPC_HOST rm -fr /tmp/ready-lisp
fi

if [[ $local == true ]]; then
    rsync -a ~/src/ready-lisp .
else
    git clone git://github.com/jwiegley/ready-lisp.git
fi

cd ready-lisp && \
    time make PPC_HOST=$PPC_HOST && \
    mv /tmp/ready-lisp/build/ReadyLisp-*.dmg $PWD

# build.sh ends here
