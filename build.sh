#!/bin/sh

PPC_HOST=$1

# Bootstrap a Ready Lisp disk image from complete scratch.  Just make sure all
# relevant version numbers and URLs have been updated and pushed to the Github
# repository first.

cd /tmp

rm -fr ready-lisp

ssh $PPC_HOST rm -fr /tmp/ready-lisp

git clone git://github.com/jwiegley/ready-lisp.git && \
    cd ready-lisp && \
    time make PPC_HOST=$PPC_HOST && \
    cp /tmp/ready-lisp/build/ReadyLisp-*.dmg .

# build.sh ends here
