#!/bin/sh
# Checks that a Dockerfile edit changes nothing: builds the working tree's Dockerfile,
# then compares its installed packages and rendered output to a baseline image.
# From the repo root (out_dir is a path as WSL sees it):
#   wsl -e sh llm-scratchpad/dockerfile-refactor-test.sh <out_dir> [baseline_image]
#
# Builds in a temp clone, with the Dockerfile's CRLF line endings stripped, so the
# entrypoint gets LF as it would on a GitHub runner. The clone is deleted afterwards.
# Uses chrome-removal-sample.md and chrome-removal-render-in-container.sh.
OUT="${1:?usage: dockerfile-refactor-test.sh <out_dir> [baseline_image]}"
BASE="${2:-localhost/markdown-to-pdf:no-chrome}"
CANDIDATE="localhost/markdown-to-pdf:refactor"
REPO_URL="https://github.com/abaines/markdown-to-pdf.git"
HERE="$(cd "$(dirname "$0")" && pwd)"

SRC="$(mktemp -d)"
trap 'rm -rf "$SRC"' EXIT

echo "=== build candidate"
git clone --quiet "$REPO_URL" "$SRC/repo" || exit 1
tr -d '\r' < Dockerfile > "$SRC/repo/Dockerfile"
podman build --quiet --platform linux/amd64 -t "$CANDIDATE" "$SRC/repo" 2>/dev/null || { echo "BUILD FAILED"; exit 1; }

echo "=== installed packages and versions"
podman run --rm --entrypoint dpkg-query "$BASE" -W -f '${Package} ${Version}\n' | sort > "$SRC/base.txt"
podman run --rm --entrypoint dpkg-query "$CANDIDATE" -W -f '${Package} ${Version}\n' | sort > "$SRC/candidate.txt"
wc -l < "$SRC/base.txt" | sed 's/^/baseline packages: /'
wc -l < "$SRC/candidate.txt" | sed 's/^/candidate packages: /'
if cmp -s "$SRC/base.txt" "$SRC/candidate.txt"; then
    echo "package lists: identical"
else
    echo "package lists: DIFFER"
    diff "$SRC/base.txt" "$SRC/candidate.txt"
fi

render() {
    ws="$OUT/$1"
    rm -rf "$ws"; mkdir -p "$ws"
    cp README.md "$ws/README.md" || exit 1
    cp "$HERE/chrome-removal-sample.md" "$ws/sample.md" || exit 1
    timeout 300 podman run --rm \
        -v "$ws:/github/workspace" -w /github/workspace \
        -v "$HERE/chrome-removal-render-in-container.sh:/scratch/run.sh:ro" \
        -e INPUT_INPUT_PATH=./ \
        -e INPUT_OUTPUT_DIR=generated \
        -e INPUT_BUILD_HTML=true \
        --entrypoint sh "$2" /scratch/run.sh
}

echo "=== render"
render baseline "$BASE" || { echo "BASELINE RENDER FAILED"; exit 1; }
render candidate "$CANDIDATE" || { echo "CANDIDATE RENDER FAILED"; exit 1; }

echo "=== compare rendered files"
for file in "$OUT/baseline/generated/"*.ppm "$OUT/baseline/generated/"*.html "$OUT/baseline/generated/"*.fonts; do
    name="$(basename "$file")"
    if cmp -s "$file" "$OUT/candidate/generated/$name"; then
        echo "$name: identical"
    else
        echo "$name: DIFFERS"
    fi
done
