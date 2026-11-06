#!/bin/sh
# Read-only: lists the PUPPETEER_* environment variables that a Puppeteer version's
# code actually reads. Unpacks the npm tarballs in a temp dir; runs none of their code.
# From the repo root:
#   wsl -e sh llm-scratchpad/check-puppeteer-env.sh <image> <version> [version...]
# npm runs inside <image>, because WSL may not have it.
IMAGE="${1:?usage: check-puppeteer-env.sh <image> <version> [version...]}"
shift

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for version in "$@"; do
    echo "=== puppeteer $version"
    mkdir -p "$WORK/$version"
    for package in puppeteer puppeteer-core; do
        podman run --rm -v "$WORK/$version:/w" -w /w --entrypoint npm "$IMAGE" pack "$package@$version" --silent >/dev/null 2>&1
    done
    for archive in "$WORK/$version/"*.tgz; do
        [ -f "$archive" ] && tar -xzf "$archive" -C "$WORK/$version" --one-top-level="$(basename "$archive" .tgz)"
    done
    grep -r -h -o -E 'PUPPETEER_[A-Z_]+' "$WORK/$version" --include='*.js' | sort | uniq -c
done
