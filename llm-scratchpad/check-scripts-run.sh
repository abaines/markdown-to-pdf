#!/bin/sh
# Read-only check: do scripts in the Markdown run while the PDF renders?
# Renders a throwaway document whose script adds the text SCRIPT-RAN and 20 page breaks,
# then reads the PDF's text and page count. Output goes to generated/scripts-test (gitignored).
# From the repo root:
#   wsl -e sh llm-scratchpad/check-scripts-run.sh <engine> <image>
set -eu
USAGE="usage: check-scripts-run.sh <docker|podman> <image>"
ENGINE="${1:?$USAGE}"
IMAGE="${2:?$USAGE}"

OUT=generated/scripts-test
mkdir -p "$OUT"
cp llm-scratchpad/scripts-run.md "$OUT/scripts-run.md"
rm -f "$OUT/scripts-run.pdf"

"$ENGINE" run --rm -v "$PWD:/github/workspace" -w /github/workspace \
    -e INPUT_INPUT_PATH="$OUT/scripts-run.md" -e INPUT_OUTPUT_DIR="$OUT/" \
    -e INPUT_BUILD_HTML=false -e INPUT_BUILD_PDF=true \
    "$IMAGE" > "$OUT/render.log" 2>&1 || { cat "$OUT/render.log"; exit 1; }

# The renderer image has no poppler; install it in a throwaway container to read the PDF.
"$ENGINE" run --rm -v "$PWD/$OUT:/w:ro" --entrypoint sh "$IMAGE" -c '
    apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq poppler-utils >/dev/null 2>&1
    pdfinfo /w/scripts-run.pdf | grep "^Pages"
    if pdftotext /w/scripts-run.pdf - | grep -q SCRIPT-RAN; then
        echo "scripts RUN"
    else
        echo "scripts blocked"
    fi
'
echo "page tree count in the raw PDF: $(grep -ao '/Count [0-9]*' "$OUT/scripts-run.pdf" | head -n 1)"
