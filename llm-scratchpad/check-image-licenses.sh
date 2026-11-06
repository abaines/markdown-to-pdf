#!/bin/sh
# Read-only look at the licenses of notable software in the renderer image, plus
# the emoji font if it were added. The font is installed in a throwaway container.
# The checks themselves are in image-licenses-in-container.sh.
# From the repo root:
#   wsl -e sh llm-scratchpad/check-image-licenses.sh [image]
IMAGE="${1:-localhost/markdown-to-pdf:step3-lf}"
HERE="$(cd "$(dirname "$0")" && pwd)"

podman run --rm \
    -v "$HERE/image-licenses-in-container.sh:/scratch/run.sh:ro" \
    --entrypoint sh "$IMAGE" /scratch/run.sh
