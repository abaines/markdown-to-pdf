#!/bin/sh
# Regenerates package-lock.json so it matches package.json, without changing any
# already-locked version, then shows how it differs from the repo's lockfile.
# From the repo root (out_dir is a path as WSL sees it):
#   wsl -e sh llm-scratchpad/sync-lockfile.sh <out_dir> [image]
#
# Uses the npm inside the image, so the file format matches the build's npm.
# Scripts are skipped and only the lockfile is written; the repo is not touched.
# The result is <out_dir>/package-lock.json, for review before applying it.
OUT="${1:?usage: sync-lockfile.sh <out_dir> [image]}"
IMAGE="${2:-localhost/markdown-to-pdf:emoji}"
REPO_URL="https://github.com/abaines/markdown-to-pdf.git"

SRC="$(mktemp -d)"
trap 'rm -rf "$SRC"' EXIT

git clone --quiet "$REPO_URL" "$SRC/repo" || exit 1
mkdir -p "$OUT" "$SRC/work"
cp "$SRC/repo/package.json" "$SRC/repo/package-lock.json" "$SRC/work/"

podman run --rm -v "$SRC/work:/work" -w /work --entrypoint npm "$IMAGE" \
    install --package-lock-only --ignore-scripts --no-audit --no-fund || exit 1

cp "$SRC/work/package-lock.json" "$OUT/package-lock.json"
echo "=== package.json changed?"
cmp -s "$SRC/repo/package.json" "$SRC/work/package.json" && echo "no" || echo "YES"
echo "=== lockfile diff"
diff -u "$SRC/repo/package-lock.json" "$SRC/work/package-lock.json"
