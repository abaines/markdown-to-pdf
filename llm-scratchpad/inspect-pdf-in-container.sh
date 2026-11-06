#!/bin/sh
# Runs inside a renderer image with a folder of PDFs mounted at /w.
# Prints each PDF's metadata and fonts, and writes a PNG of page 1 beside it.
# Usage, from the repo root (pdf_dir is a path as WSL sees it):
#   wsl -e podman run --rm -v <pdf_dir>:/w -v <this_file>:/scratch/run.sh:ro \
#       --entrypoint sh <image> /scratch/run.sh
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq poppler-utils >/dev/null 2>&1

for pdf in /w/*.pdf; do
    echo "=== $(basename "$pdf")"
    pdfinfo "$pdf" | grep -E '^(Creator|Producer|Pages|Page size)'
    pdffonts "$pdf"
    pdftoppm -png -r 80 -f 1 -l 1 "$pdf" "${pdf%.pdf}-page"
done
