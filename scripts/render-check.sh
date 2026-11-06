#!/bin/sh
# Renders README.md with a renderer image, the way the action does, and fails if
# the PDF or HTML is missing or empty. Used locally and by the workflows.
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

# Clear old results, so they can't pass the check below.
rm -f "$OUT/README.pdf" "$OUT/README.html"

# The trailing slash matters: without it, the action writes to generatedREADME.pdf
# when the folder already exists.
"$ENGINE" run --rm \
    -v "$PWD:/github/workspace" -w /github/workspace \
    -e INPUT_INPUT_PATH=README.md \
    -e INPUT_OUTPUT_DIR="$OUT/" \
    -e INPUT_BUILD_HTML=true \
    -e INPUT_BUILD_PDF=true \
    "$IMAGE"

for file in "$OUT/README.pdf" "$OUT/README.html"; do
    if [ ! -s "$file" ]; then
        echo "render-check: missing or empty: $file" >&2
        exit 1
    fi
    echo "render-check: ok: $file ($(wc -c < "$file") bytes)"
done
