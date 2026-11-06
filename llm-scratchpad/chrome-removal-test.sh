#!/bin/sh
# Experiment: can google-chrome-stable and the Google apt repo be dropped from the
# image without changing the rendered output?
# From the repo root (out_dir is a path as WSL sees it):
#   wsl -e sh llm-scratchpad/chrome-removal-test.sh <out_dir> [baseline_image]
#
# The Dockerfile is edited only in a temp clone, which is deleted afterwards.
# Builds localhost/markdown-to-pdf:no-chrome, then compares it to the baseline:
# Chromium's missing libraries, packages removed, PDF fonts, and rasterized pages.
# PDFs are compared as page images because their timestamps always differ.
# Uses chrome-removal-sample.md and chrome-removal-render-in-container.sh.
OUT="${1:?usage: chrome-removal-test.sh <out_dir> [baseline_image]}"
BASE="${2:-localhost/markdown-to-pdf:step3-lf}"
HERE="$(cd "$(dirname "$0")" && pwd)"
VARIANT="localhost/markdown-to-pdf:no-chrome"
REPO_URL="https://github.com/abaines/markdown-to-pdf.git"
CHROMIUM=/node_modules/puppeteer/.local-chromium/linux-970485/chrome-linux/chrome

SRC="$(mktemp -d)"
trap 'rm -rf "$SRC"' EXIT

echo "=== build variant"
git clone --quiet "$REPO_URL" "$SRC/repo" || exit 1
sed -i \
    -e '/dl-ssl\.google\.com/d' \
    -e '/dl\.google\.com\/linux\/chrome/d' \
    -e 's/^    apt-get update/RUN apt-get update/' \
    -e 's/ google-chrome-stable//' \
    "$SRC/repo/Dockerfile"
sed -n '1,4p' "$SRC/repo/Dockerfile" | cut -c1-70
grep -c -i 'google' "$SRC/repo/Dockerfile" | sed 's/^/remaining lines mentioning google: /'
podman build --quiet --platform linux/amd64 -t "$VARIANT" "$SRC/repo" 2>/dev/null || { echo "BUILD FAILED"; exit 1; }

echo "=== sizes"
podman image inspect "$BASE" --format "baseline: {{.Size}}"
podman image inspect "$VARIANT" --format "variant:  {{.Size}}"

echo "=== Chromium libraries missing in variant"
podman run --rm --entrypoint sh "$VARIANT" -c "ldd $CHROMIUM | grep 'not found' || echo '(none missing)'"

echo "=== google-chrome present in variant?"
podman run --rm --entrypoint sh "$VARIANT" -c "command -v google-chrome || echo '(not installed)'"

echo "=== packages in baseline but not variant"
podman run --rm --entrypoint dpkg-query "$BASE" -W -f '${Package}\n' | sort > "$SRC/base.txt"
podman run --rm --entrypoint dpkg-query "$VARIANT" -W -f '${Package}\n' | sort > "$SRC/variant.txt"
comm -23 "$SRC/base.txt" "$SRC/variant.txt"

render() {
    name="$1"; image="$2"
    ws="$OUT/$name"
    rm -rf "$ws"; mkdir -p "$ws"
    cp README.md "$ws/README.md" || exit 1
    cp "$HERE/chrome-removal-sample.md" "$ws/sample.md" || exit 1
    timeout 300 podman run --rm \
        -v "$ws:/github/workspace" -w /github/workspace \
        -v "$HERE/chrome-removal-render-in-container.sh:/scratch/run.sh:ro" \
        -e INPUT_INPUT_PATH=./ \
        -e INPUT_OUTPUT_DIR=generated \
        -e INPUT_BUILD_HTML=true \
        --entrypoint sh "$image" /scratch/run.sh
}

echo "=== render baseline"
render baseline "$BASE" || { echo "BASELINE RENDER FAILED"; exit 1; }
echo "=== render variant"
render variant "$VARIANT" || { echo "VARIANT RENDER FAILED"; exit 1; }

echo "=== compare"
for f in README sample; do
    if cmp -s "$OUT/baseline/generated/$f.fonts" "$OUT/variant/generated/$f.fonts"; then
        echo "$f fonts: identical"
    else
        echo "$f fonts: DIFFER"
        diff "$OUT/baseline/generated/$f.fonts" "$OUT/variant/generated/$f.fonts"
    fi
    if cmp -s "$OUT/baseline/generated/$f.html" "$OUT/variant/generated/$f.html"; then
        echo "$f html: identical"
    else
        echo "$f html: DIFFER"
    fi
    for page in "$OUT/baseline/generated/$f-page"*.ppm; do
        other="$OUT/variant/generated/$(basename "$page")"
        if cmp -s "$page" "$other"; then
            echo "$(basename "$page"): identical"
        else
            echo "$(basename "$page"): DIFFERS"
        fi
    done
    ls "$OUT/variant/generated/$f-page"*.ppm | wc -l | sed "s/^/$f variant page count: /"
done
