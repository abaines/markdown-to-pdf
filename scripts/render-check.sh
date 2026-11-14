#!/bin/sh
# Renders sample documents with a renderer image, the way the action does, and fails
# if a PDF or HTML file is missing or empty, a local image wasn't embedded,
# or a script in the Markdown ran.
# Used locally and by the workflows.
#
# Usage: scripts/render-check.sh <engine> <image> [output_dir]
#   engine      docker or podman, whichever built the image
#   image       image to test, for example markdown-to-pdf:dev
#   output_dir  folder inside the repo, default generated
set -eu

USAGE="usage: render-check.sh <docker|podman> <image> [output_dir]"
ENGINE="${1:?$USAGE}"
IMAGE="${2:?$USAGE}"
OUT="${3:-generated}"

cd "$(dirname "$0")/.."

# Usage: render <input_path> [extra container args...]
# The trailing slash on the output folder matters: without it, the action writes to
# generatedREADME.pdf when the folder already exists.
render() {
    input="$1"
    shift
    "$ENGINE" run --rm \
        -v "$PWD:/github/workspace" -w /github/workspace \
        -e INPUT_INPUT_PATH="$input" \
        -e INPUT_OUTPUT_DIR="$OUT/" \
        -e INPUT_BUILD_HTML=true \
        -e INPUT_BUILD_PDF=true \
        "$@" \
        "$IMAGE"
}

check_exists() {
    if [ ! -s "$1" ]; then
        echo "render-check: missing or empty: $1" >&2
        exit 1
    fi
    echo "render-check: ok: $1 ($(wc -c < "$1") bytes)"
}

# Clear old results, so they can't pass the checks below.
rm -f "$OUT/README.pdf" "$OUT/README.html" "$OUT/image-import.pdf" "$OUT/image-import.html" \
    "$OUT/scripts.pdf" "$OUT/scripts.html"

render README.md
render test/fixtures/image-import.md \
    -e INPUT_IMAGE_IMPORT=./images \
    -e INPUT_IMAGES_DIR=test/fixtures/images
render test/fixtures/scripts.md

check_exists "$OUT/README.pdf"
check_exists "$OUT/README.html"
check_exists "$OUT/image-import.pdf"
check_exists "$OUT/image-import.html"
check_exists "$OUT/scripts.pdf"
check_exists "$OUT/scripts.html"

if ! grep -q 'src="data:image/svg+xml;base64,' "$OUT/image-import.html"; then
    echo "render-check: local image was not embedded in $OUT/image-import.html" >&2
    exit 1
fi
echo "render-check: ok: local image embedded"

# The fixture's script adds 20 pages if it runs. Count page objects in the raw PDF;
# "/Type /Pages" nodes are the page tree, not pages.
pages="$(grep -ao '/Type */Pages*' "$OUT/scripts.pdf" | grep -cx '/Type /Page' || true)"
if [ "$pages" != 1 ]; then
    echo "render-check: scripts.pdf has $pages pages, expected 1; a script in the Markdown ran" >&2
    exit 1
fi
echo "render-check: ok: scripts blocked"
