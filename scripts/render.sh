#!/bin/sh
# Renders Markdown to PDF and HTML with the image that action.yml pins,
# the same way the action does, so a local render matches a workflow's.
# The current folder is mounted as the workspace, like the repository in a workflow,
# so the input and output paths are relative to it and must be inside it.
# Prints the image it used, to compare with a workflow that pins this action.
#
# Usage: scripts/render.sh <engine> <input_path> [output_dir]
#   engine      docker or podman
#   input_path  a .md file, or a folder of them, inside the current folder
#   output_dir  folder inside the current folder, default generated
set -eu

USAGE="usage: render.sh <docker|podman> <input_path> [output_dir]"
ENGINE="${1:?$USAGE}"
INPUT="${2:?$USAGE}"
OUT="${3:-generated}"

ACTION_YML="$(dirname "$0")/../action.yml"
IMAGE="$(sed -n "s|^ *image: *'docker://\([^']*\)'.*|\1|p" "$ACTION_YML")"
if [ -z "$IMAGE" ]; then
    echo "render: no docker:// image found in $ACTION_YML" >&2
    exit 1
fi
echo "render: image $IMAGE" >&2

# The trailing slash on the output folder matters: without it, the action writes to
# generatedREADME.pdf when the folder already exists.
"$ENGINE" run --rm \
    -v "$PWD:/github/workspace" -w /github/workspace \
    -e INPUT_INPUT_PATH="$INPUT" \
    -e INPUT_OUTPUT_DIR="${OUT%/}/" \
    -e INPUT_BUILD_HTML=true \
    -e INPUT_BUILD_PDF=true \
    "$IMAGE"
