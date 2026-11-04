#!/bin/sh
# Does an emoji render in the PDF, with and without an emoji font in the image?
# From the repo root (out_dir is a path as WSL sees it):
#   wsl -e sh llm-scratchpad/emoji-font-test.sh <out_dir> [image]
#
# Experiment only: fonts are installed in throwaway containers, so the image and
# Dockerfile are unchanged. Poppler is installed after rendering, so it cannot
# affect the result. Output goes to <out_dir>/{without,with}/generated.
OUT="${1:?usage: emoji-font-test.sh <out_dir> [image]}"
IMAGE="${2:-localhost/markdown-to-pdf:step3-lf}"

run_case() {
    name="$1"; font_step="$2"
    ws="$OUT/$name"
    rm -rf "$ws"; mkdir -p "$ws"
    cat > "$ws/sample.md" <<'EOF'
# Emoji test

Literal rocket: 🚀

Shortcode: :tada:
EOF
    echo "=== $name emoji font"
    timeout 300 podman run --rm \
        -v "$ws:/github/workspace" -w /github/workspace \
        -e INPUT_INPUT_PATH=sample.md \
        -e INPUT_OUTPUT_DIR=generated \
        -e INPUT_BUILD_HTML=false \
        "$image_arg" sh -c "
            apt-get update -qq >/dev/null 2>&1
            $font_step
            echo 'emoji fonts visible to fontconfig:'; fc-list | grep -i emoji || echo '(none)'
            markdown-to-pdf
            echo \"render exit: \$?\"
            apt-get install -y -qq poppler-utils >/dev/null 2>&1
            pdffonts generated/sample.pdf
            pdftoppm -png -r 90 -f 1 -l 1 generated/sample.pdf generated/page
        "
}

image_arg="$IMAGE"
run_case without ":"
run_case with "apt-get install -y -qq fonts-noto-color-emoji >/dev/null 2>&1"
