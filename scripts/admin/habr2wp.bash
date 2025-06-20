#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

sed -E \
    -e 's/<\/?(div|figure|span)[^>]*>//g'  \
    -e 's/<img src="([^"]+)"[^>]*>/<a href="\1"><img width=800 src="\1" \/><\/a>/g'  \
    -e 's/<img src="([^"]+)"[^>]*$/<a href="\1"><img width=800 src="\1" \/><\/a>/g'  \
    -e 's/ +https:\/\/habrastorage.org\/[^>]+>//g'  \
    -e 's/rel="noopener noreferrer nofollow"/rel="noopener"/g'  \
    habr.html > wp.html

sed -E -i 's/<a [^>]+><img [^>]+><\/a>/\n&\n/g' wp.html
sed -E -i '/^$/N;/^\n$/D' wp.html


#     -e 's/<\/?(div|figure|span)[^>]*>//g'  \
