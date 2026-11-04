#!/bin/sh
# Render test for the renderer image, mimicking how GitHub runs a Docker action
# (workspace mounted at /github/workspace, inputs passed as INPUT_* env vars).
# From the repo root (out_dir is a path as WSL sees it):
#   wsl -e sh llm-scratchpad/render-test.sh <out_dir> [commit]
#
# Compares two images built from the same commit:
#   crlf: localhost/markdown-to-pdf:step3 (built from the Windows working tree)
#   lf:   localhost/markdown-to-pdf:step3-lf (built here from a clean Linux clone,
#         which is what a GitHub runner would see)
# The clone goes in a temp dir and is deleted afterwards. The working repo is
# not touched. Rendered output is written to <out_dir>/{crlf,lf}.
OUT="${1:?usage: render-test.sh <out_dir> [commit]}"
COMMIT="${2:-7562ca07177202ca22ac421b876a28c4d07819a7}"
REPO_URL="https://github.com/abaines/markdown-to-pdf.git"

SRC="$(mktemp -d)"
trap 'rm -rf "$SRC"' EXIT

echo "=== clean LF clone at $COMMIT"
git clone --quiet "$REPO_URL" "$SRC/repo" || exit 1
git -C "$SRC/repo" -c advice.detachedHead=false checkout --quiet "$COMMIT" || exit 1
printf 'entrypoint first line: '
head -n 1 "$SRC/repo/src/github_interface.js" | od -c | sed -n 2p

echo "=== build LF image"
podman build --quiet --platform linux/amd64 -t localhost/markdown-to-pdf:step3-lf "$SRC/repo" || exit 1

render() {
    name="$1"; image="$2"
    ws="$OUT/$name"
    rm -rf "$ws"; mkdir -p "$ws"
    cat > "$ws/sample.md" <<'EOF'
# Render test

Plain paragraph with **bold**, *italic* and a [link](https://example.com).

## Table

| Tool | Version |
|------|---------|
| Node | 18 |

## Code

```js
const answer = 42;
```

Emoji shortcode: :tada:

## Script execution check

<p id="js">SCRIPT DID NOT RUN</p>
<script>document.getElementById('js').textContent = 'SCRIPT RAN';</script>
EOF
    echo "=== render with $name image"
    timeout 180 podman run --rm \
        -v "$ws:/github/workspace" -w /github/workspace \
        -e INPUT_INPUT_PATH=sample.md \
        -e INPUT_OUTPUT_DIR=generated \
        -e INPUT_BUILD_HTML=true \
        -e INPUT_BUILD_PDF=true \
        "$image"
    echo "exit code: $?"
    ls -l "$ws/generated" 2>/dev/null || echo "(no output directory)"
    if [ -f "$ws/generated/sample.pdf" ]; then
        printf 'pdf header: '; head -c 8 "$ws/generated/sample.pdf"; echo
        printf 'pdf metadata: '; grep -a -o -E '/(Creator|Producer) \([^)]*\)' "$ws/generated/sample.pdf" | tr '\n' ' '; echo
    fi
}

render crlf localhost/markdown-to-pdf:step3
render lf localhost/markdown-to-pdf:step3-lf
