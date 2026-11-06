#!/bin/sh
# Runs inside a renderer image with two folders mounted at /a and /b; started by
# compare-run-artifacts.ps1. Compares README.pdf in each, page by page as images,
# because PDF timestamps always differ, plus their font lists and README.html.
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq poppler-utils >/dev/null 2>&1

WORK="$(mktemp -d)"
for side in a b; do
    mkdir "$WORK/$side"
    pdftoppm -r 100 "/$side/README.pdf" "$WORK/$side/page"
    pdffonts "/$side/README.pdf" | tail -n +3 | sed 's/^[A-Z]*+//' | cut -c1-30 | sort > "$WORK/$side/fonts"
done

report() {
    if cmp -s "$1" "$2"; then echo "$3: identical"; else echo "$3: DIFFERS"; fi
}

report /a/README.html /b/README.html "html"
report "$WORK/a/fonts" "$WORK/b/fonts" "fonts"
for page in "$WORK/a/"page*.ppm; do
    name="$(basename "$page")"
    report "$page" "$WORK/b/$name" "$name"
done
echo "pages: $(ls "$WORK/a/"page*.ppm | wc -l) and $(ls "$WORK/b/"page*.ppm | wc -l)"
