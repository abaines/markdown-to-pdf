#!/bin/sh
# Runs scripts/render-check.sh with two images, then compares their HTML output.
# Use it for code changes, which dockerfile-refactor-test.sh doesn't pick up.
# From the repo root:
#   wsl -e sh llm-scratchpad/compare-render-check.sh <baseline_image> <candidate_image>
BASE="${1:?usage: compare-render-check.sh <baseline_image> <candidate_image>}"
CANDIDATE="${2:?usage: compare-render-check.sh <baseline_image> <candidate_image>}"

mkdir -p generated/baseline generated/candidate

echo "=== baseline"
sh scripts/render-check.sh podman "$BASE" generated/baseline | grep 'render-check:' || exit 1
echo "=== candidate"
sh scripts/render-check.sh podman "$CANDIDATE" generated/candidate | grep 'render-check:' || exit 1

echo "=== compare"
for file in README.html image-import.html; do
    if cmp -s "generated/baseline/$file" "generated/candidate/$file"; then
        echo "$file: identical"
    else
        echo "$file: DIFFERS"
    fi
done
