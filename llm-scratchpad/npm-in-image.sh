#!/bin/sh
# Runs npm from a renderer image against copies of package.json and package-lock.json,
# then writes back whichever changed. No node_modules lands in the repo, and the npm
# version matches the build. From the repo root:
#   wsl -e sh llm-scratchpad/npm-in-image.sh <image> <npm args...>
#
# Example, to preview a change without writing anything:
#   wsl -e sh llm-scratchpad/npm-in-image.sh <image> install <package>@<version> --dry-run
IMAGE="${1:?usage: npm-in-image.sh <image> <npm args...>}"
shift

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp package.json package-lock.json "$WORK/" || exit 1
podman run --rm -v "$WORK:/work" -w /work --entrypoint npm "$IMAGE" "$@" || exit 1

for file in package.json package-lock.json; do
    if cmp -s "$file" "$WORK/$file"; then
        echo "unchanged: $file"
    else
        cp "$WORK/$file" "$file"
        echo "updated: $file"
    fi
done
