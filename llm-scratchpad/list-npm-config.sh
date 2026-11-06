#!/bin/sh
# Read-only: lists an image's npm config keys that look security related, with their
# default values. From the repo root:
#   wsl -e sh llm-scratchpad/list-npm-config.sh <image>
IMAGE="${1:?usage: list-npm-config.sh <image>}"
PATTERN='script|audit|sign|provenance|trust|strict|exact|git|engine|registry|release|age|before|lock|shrinkwrap|omit|bin|token|integrity|allow'

podman run --rm --entrypoint npm "$IMAGE" --version
podman run --rm --entrypoint npm "$IMAGE" config ls -l 2>/dev/null | grep -E "^(; )?[a-z-]+ = " | grep -E "$PATTERN"
