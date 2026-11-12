#!/bin/sh
# Read-only: for each apt package the Dockerfile installs, reports whether listing it
# changes anything. A package is "redundant" when apt would install the exact same set
# without it: it's already in the base image, or the kept packages pull it in.
# Kept packages: ca-certificates, chromium and fonts-*. Uses apt-get -s (simulate only).
#
# Runs inside the base image with the repo mounted read-only at /repo;
# started by find-redundant-apt-packages.sh.
apt-get update -qq >/dev/null 2>&1 || exit 1

# Package names between "apt-get -y install" and "rm -rf" in the Dockerfile.
PKGS="$(sed -n '/apt-get -y install/,/rm -rf/p' /repo/Dockerfile \
    | grep -vE 'apt-get|rm -rf' \
    | grep -oE '^ +[a-z0-9][a-z0-9.+-]+' | tr -d ' ')"
KEEP="$(echo "$PKGS" | grep -E '^(ca-certificates|chromium|fonts-.*)$')"

# Same as the Dockerfile's install: recommends included.
# Fails if apt can't resolve the request, so an unknown name is never called redundant.
installs() {
    apt-get install -s "$@" > /tmp/sim 2>&1 || return 1
    awk '/^Inst /{print $2}' /tmp/sim | sort
}

installs $KEEP > /tmp/keep || { echo "error: apt can't install the kept packages"; exit 1; }
echo "kept: $(echo $KEEP)"
echo "kept packages install $(wc -l < /tmp/keep) packages"
echo

for pkg in $PKGS; do
    if echo "$KEEP" | grep -qx "$pkg"; then
        continue
    fi
    if ! installs $KEEP "$pkg" > /tmp/with; then
        echo "error:     $pkg ($(grep '^E:' /tmp/sim | head -n 1))"
        continue
    fi
    added="$(comm -13 /tmp/keep /tmp/with | tr '\n' ' ')"
    if [ -z "$added" ]; then
        echo "redundant: $pkg"
    else
        echo "adds:      $pkg -> $added"
    fi
done
