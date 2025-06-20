#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

sed -E \
    -e 's/<div class="floating-image">//g'  \
    -e 's/width="[0-9]+"/width="800"/g'  \
    -e 's/ width=""//g'  \
    -e 's/ height="[0-9]+"//g'  \
    -e 's/ data-src="[^"]+"//g'  \
    -e 's/<\/div>//g'  \
    -e 's/<figure class="float bordered ">//g'  \
    -e 's/<figure class="float full-width ">//g'  \
    -e 's/<figure class="full-width ">//g'  \
    -e 's/<\/figure>//g'  \
    -e 's/rel="noopener noreferrer nofollow"/rel="noopener"/g'  \
    habr.html > wp.html

sed -E -i 's/<img [^>]+>/\n&\n/g' wp.html
sed -E -i '/^$/N;/^\n$/D' wp.html
