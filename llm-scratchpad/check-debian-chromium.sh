#!/bin/sh
# Read-only: reports the chromium version Debian offers in a base image, and the
# license fields of the package. Installs nothing into any saved image.
# From the repo root:
#   wsl -e sh llm-scratchpad/check-debian-chromium.sh <image> [image...]
for image in "$@"; do
    echo "=== $image"
    podman run --rm --entrypoint sh "$image" -c 'apt-get update -qq >/dev/null 2>&1; apt-cache policy chromium | head -n 3; apt-get download chromium >/dev/null 2>&1; dpkg -I chromium_*.deb | grep -E "Version|Installed-Size"'
done
