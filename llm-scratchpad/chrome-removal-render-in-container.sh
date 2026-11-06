#!/bin/sh
# Runs inside a renderer image, in /github/workspace; started by chrome-removal-test.sh.
# Renders the workspace, then writes each PDF's font list and page images to
# generated/ for comparison. Poppler is installed after rendering, so it cannot
# affect the result.
markdown-to-pdf >/dev/null || exit 1
echo "render exit: 0"

apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq poppler-utils >/dev/null 2>&1

for name in README sample; do
    pdffonts "generated/$name.pdf" | tail -n +3 | sed 's/^[A-Z]*+//' | cut -c1-30 | sort > "generated/$name.fonts"
    pdftoppm -r 100 "generated/$name.pdf" "generated/$name-page"
done
