#!/bin/sh
# Read-only inspection of a locally built renderer image. From the repo root:
#   wsl -e sh llm-scratchpad/inspect-image.sh [image]
# Reports the image, the entrypoint's line endings, and which browsers exist.
# Each container is removed on exit; nothing in the repo is touched.
IMAGE="${1:-localhost/markdown-to-pdf:step3}"

echo "--- image"
podman image inspect "$IMAGE" --format '{{.Id}} {{.Size}} {{.Architecture}} cmd={{.Config.Cmd}}'

podman run --rm --entrypoint sh "$IMAGE" -c '
echo "--- os / node"
. /etc/os-release; echo "$PRETTY_NAME"; node --version
echo "--- entrypoint first line, as bytes (\\r means CRLF)"
head -n 1 /github_interface.js | od -c | head -n 3
echo "--- is google-chrome installed?"
google-chrome --version 2>&1 | head -n 1
echo "--- which browser does puppeteer resolve?"
cd / && node -e "
const p = require(\"puppeteer\");
const path = p.executablePath();
console.log(\"executablePath:\", path);
console.log(\"exists:\", require(\"fs\").existsSync(path));
"
echo "--- bundled chromium version"
node -e "
const p = require(\"puppeteer\");
const cp = require(\"child_process\");
console.log(cp.execFileSync(p.executablePath(), [\"--version\"]).toString().trim());
" 2>&1 | tail -n 1
echo "--- PUPPETEER env"
env | grep -i puppeteer || echo "(none)"
echo "--- running as"
id -u
'
