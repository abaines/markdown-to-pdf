#!/bin/sh
# Confirms a published image can be pulled without credentials. From the repo root:
#   wsl -e sh llm-scratchpad/verify-published-image.sh <sha256:digest> [owner/name]
#
# Reports whether Podman holds a GHCR login, removes the local copy of this image
# (only that image), pulls it again, then asks the registry for its manifest with
# an anonymous token. Sends no credentials.
DIGEST="${1:?usage: verify-published-image.sh <sha256:digest> [owner/name]}"
IMAGE="${2:-abaines/markdown-to-pdf}"
REF="ghcr.io/$IMAGE@$DIGEST"
ACCEPT='application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json'

echo "=== podman login for ghcr.io"
podman login --get-login ghcr.io 2>&1 || echo "(not logged in)"

echo "=== fresh pull"
podman rmi --force "$REF" >/dev/null 2>&1
podman pull --quiet "$REF" || { echo "PULL FAILED"; exit 1; }

echo "=== digest and labels"
podman image inspect "$REF" --format '{{.Digest}} {{.Labels}}'

echo "=== anonymous manifest request"
TOKEN="$(curl -fsS "https://ghcr.io/token?scope=repository:$IMAGE:pull" | sed 's/.*"token":"\([^"]*\)".*/\1/')"
curl -fsS -o /dev/null -I \
    -H "Authorization: Bearer $TOKEN" -H "Accept: $ACCEPT" \
    -w 'status: %{http_code}\ndigest: %header{docker-content-digest}\ntype: %{content_type}\n' \
    "https://ghcr.io/v2/$IMAGE/manifests/$DIGEST"
