#!/bin/sh
# Downloads the current stable Chrome for Testing linux64 build and reports what
# license files it ships. Nothing from the archive is run. Everything goes in out_dir.
# unzip runs in a container, because WSL doesn't have it.
# From the repo root (out_dir is a path as WSL sees it):
#   wsl -e sh llm-scratchpad/inspect-chrome-for-testing.sh <out_dir> [image]
OUT="${1:?usage: inspect-chrome-for-testing.sh <out_dir> [image]}"
IMAGE="${2:-markdown-to-pdf:dev}"
JSON_URL="https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions.json"
PATTERN='licen|eula|terms|credits|notice|copying'

mkdir -p "$OUT/extracted"
VERSION="$(curl -fsS "$JSON_URL" | tr -d '\n ' | sed 's/.*"Stable":{[^}]*"version":"\([^"]*\)".*/\1/')"
echo "stable version: $VERSION"

ZIP="$OUT/chrome-linux64.zip"
if [ ! -s "$ZIP" ]; then
    curl -fsS -o "$ZIP" "https://storage.googleapis.com/chrome-for-testing-public/$VERSION/linux64/chrome-linux64.zip" || exit 1
fi
echo "archive bytes: $(wc -c < "$ZIP")"

unzip_in_container() {
    podman run --rm -v "$OUT:/w" --entrypoint unzip "$IMAGE" "$@"
}

unzip_in_container -Z1 /w/chrome-linux64.zip > "$OUT/entries.txt" || { echo "LISTING FAILED"; exit 1; }
echo "archive entries: $(wc -l < "$OUT/entries.txt")"

echo "=== license-like entries"
grep -i -E "$PATTERN" "$OUT/entries.txt" || echo "(none)"

echo "=== top-level files"
grep -E '^[^/]+/[^/]+$' "$OUT/entries.txt" | head -n 40

echo "=== extracted"
grep -i -E "$PATTERN" "$OUT/entries.txt" | while read -r entry; do
    unzip_in_container -q -o /w/chrome-linux64.zip "$entry" -d /w/extracted </dev/null
done
find "$OUT/extracted" -type f -exec ls -l {} \;
