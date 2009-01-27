#!/bin/sh
exec rsync -aP --exclude=.localized --exclude=.DS_Store \
    --exclude=README --exclude='*.sh' \
    ./ johnwiegley.com:/srv/ftp/pub/lisp/ready-lisp/deps/
