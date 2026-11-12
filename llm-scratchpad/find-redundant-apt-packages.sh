#!/bin/sh
# Read-only: reports which apt packages in the Dockerfile are installed anyway.
# Mounts the current directory read-only and runs find-redundant-apt-packages-in-container.sh
# inside the base image. From the repo root:
#   wsl -e sh llm-scratchpad/find-redundant-apt-packages.sh <engine> <base_image>
ENGINE="${1:?usage: find-redundant-apt-packages.sh <engine> <base_image>}"
IMAGE="${2:?usage: find-redundant-apt-packages.sh <engine> <base_image>}"

"$ENGINE" run --rm -v "$PWD:/repo:ro" --entrypoint sh "$IMAGE" \
    /repo/llm-scratchpad/find-redundant-apt-packages-in-container.sh
