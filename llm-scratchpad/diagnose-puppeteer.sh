#!/bin/sh
# Compares Puppeteer's browser launch across images, using diagnose-puppeteer-launch.js.
# From the repo root:
#   wsl -e sh llm-scratchpad/diagnose-puppeteer.sh <image> [image...]
# Set DUMPIO=1 to show the browser's own output.
HERE="$(cd "$(dirname "$0")" && pwd)"

for image in "$@"; do
    echo "=== $image"
    podman run --rm --entrypoint node "$image" --version
    timeout 90 podman run --rm \
        -v "$HERE/diagnose-puppeteer-launch.js:/scratch/launch.js:ro" \
        -e DUMPIO="${DUMPIO:-0}" \
        --entrypoint node "$image" /scratch/launch.js 2>&1 | tail -n 12
done
