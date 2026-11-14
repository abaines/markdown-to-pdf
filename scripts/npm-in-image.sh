#!/bin/sh
# Runs npm from a renderer image against copies of .npmrc, package.json and
# package-lock.json, then writes back whichever package file changed.
# The npm version and settings match the build, and no node_modules lands in the repo.
# Use it to change dependencies, for example:
#   scripts/npm-in-image.sh podman markdown-to-pdf:dev install <package>@<version> --package-lock-only
# Add --dry-run to preview a change without writing anything.
#
# Usage: scripts/npm-in-image.sh <engine> <image> <npm args...>
#   engine    docker or podman, whichever built the image
#   image     image whose npm to use, for example markdown-to-pdf:dev
#   npm args  passed to npm unchanged
set -eu

USAGE="usage: npm-in-image.sh <docker|podman> <image> <npm args...>"
ENGINE="${1:?$USAGE}"
IMAGE="${2:?$USAGE}"
shift 2
if [ "$#" -eq 0 ]; then
    echo "$USAGE" >&2
    exit 1
fi

cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp .npmrc package.json package-lock.json "$WORK/"
"$ENGINE" run --rm -v "$WORK:/work" -w /work --entrypoint npm "$IMAGE" "$@"

# Status goes to stderr, so npm's own output (for example --json) stays parseable.
for file in package.json package-lock.json; do
    if cmp -s "$file" "$WORK/$file"; then
        echo "unchanged: $file" >&2
    else
        cp "$WORK/$file" "$file"
        echo "updated: $file" >&2
    fi
done
