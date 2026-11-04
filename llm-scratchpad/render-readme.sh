#!/bin/sh
# Local stand-in for the test-usage job in test.yml: renders the working tree's
# README.md with the same inputs, once as the image stands and once with an emoji
# font installed in a throwaway container. Skips checkout and artifact upload.
# From the repo root (out_dir is a path as WSL sees it):
#   wsl -e sh llm-scratchpad/render-readme.sh <out_dir> [image]
#
# README.md is copied to <out_dir>/{current,with-emoji-font}, so no output lands
# in the repo. Use an image built with LF line endings, as a CRLF one won't start.
OUT="${1:?usage: render-readme.sh <out_dir> [image]}"
IMAGE="${2:-localhost/markdown-to-pdf:step3-lf}"

run_case() {
    name="$1"; font_step="$2"
    ws="$OUT/$name"
    rm -rf "$ws"; mkdir -p "$ws"
    cp README.md "$ws/README.md" || exit 1
    echo "=== $name"
    timeout 300 podman run --rm \
        -v "$ws:/github/workspace" -w /github/workspace \
        -e INPUT_INPUT_PATH=README.md \
        -e INPUT_OUTPUT_DIR=generated \
        -e INPUT_BUILD_HTML=false \
        "$IMAGE" sh -c "
            apt-get update -qq >/dev/null 2>&1
            $font_step
            markdown-to-pdf
            echo \"render exit: \$?\"
            apt-get install -y -qq poppler-utils >/dev/null 2>&1
            pdfinfo generated/README.pdf | grep -E '^(Producer|Pages)'
            pdffonts generated/README.pdf
            pdftoppm -png -r 80 -f 1 -l 1 generated/README.pdf generated/page
        "
}

run_case current ":"
run_case with-emoji-font "apt-get install -y -qq fonts-noto-color-emoji >/dev/null 2>&1"
