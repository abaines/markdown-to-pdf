#!/bin/sh
# Lints the repo's GitHub workflows with actionlint, in a container that has no
# network access and a read-only view of the repo. From the repo root:
#   wsl -e sh llm-scratchpad/lint-workflows.sh <actionlint_version>
# The version is a tag without the leading v, for example 1.7.7.
VERSION="${1:?usage: lint-workflows.sh <actionlint_version>}"

podman run --rm --network=none \
    -v "$PWD:/repo:ro" -w /repo \
    "docker.io/rhysd/actionlint:$VERSION" -color=false
echo "actionlint exit: $?"

echo "=== uses lines not pinned to a full commit SHA"
grep -n -E '^\s*-?\s*uses:' .github/workflows/*.yml | grep -v -E '@[0-9a-f]{40}( |$)' | grep -v 'uses: \./' || echo "(none)"
