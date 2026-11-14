#!/bin/sh
# Runs scripts/render-check.sh with two images, then compares their HTML output.
# Use it to check whether a change to the code, Dockerfile or dependencies
# changes what gets rendered. Results go to generated/baseline and generated/candidate.
#
# Usage: <engine> <baseline_image> <candidate_image>
#   engine           docker or podman, whichever built the images
#   baseline_image   image built before the change
#   candidate_image  image built with the change
set -eu

USAGE="usage: $(basename "$0") <docker|podman> <baseline_image> <candidate_image>"
ENGINE="${1:?$USAGE}"
BASE="${2:?$USAGE}"
CANDIDATE="${3:?$USAGE}"

cd "$(dirname "$0")/.."

# Usage: check <image> <side>
# Shows only the render-check lines, or the whole log if the check fails.
check() {
    mkdir -p "generated/$2"
    if ! sh scripts/render-check.sh "$ENGINE" "$1" "generated/$2" > "generated/$2.log" 2>&1; then
        cat "generated/$2.log"
        echo "render check failed for $2 image: $1" >&2
        exit 1
    fi
    grep 'render-check:' "generated/$2.log"
}

echo "=== baseline"
check "$BASE" baseline
echo "=== candidate"
check "$CANDIDATE" candidate

echo "=== compare"
for file in README.html image-import.html; do
    if cmp -s "generated/baseline/$file" "generated/candidate/$file"; then
        echo "$file: identical"
    else
        echo "$file: DIFFERS"
    fi
done
