#!/bin/sh
# Runs inside the renderer image; started by check-image-licenses.sh.
# Installs the emoji font in this throwaway container, then reports licenses.
CHROMIUM_DIR=/node_modules/puppeteer/.local-chromium/linux-970485/chrome-linux
OTHER_FONTS="fonts-liberation fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf"

apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq fonts-noto-color-emoji >/dev/null 2>&1

echo "--- emoji font package"
dpkg-query -W -f='${Package} ${Version} ${Installed-Size}KB\n' fonts-noto-color-emoji
grep -E '^License:' /usr/share/doc/fonts-noto-color-emoji/copyright | sort -u

echo "--- chrome package"
dpkg-query -W -f='${Package} ${Version} ${Installed-Size}KB\n' google-chrome-stable
echo "license-like files in /opt/google/chrome:"
ls /opt/google/chrome | grep -i -E 'licen|eula|terms|credits' || echo "(none)"
echo "doc dir:"
ls /usr/share/doc/google-chrome-stable/ 2>&1
echo "dpkg description:"
dpkg-query -W -f='${Description}\n' google-chrome-stable | head -n 3

echo "--- bundled chromium"
ls "$CHROMIUM_DIR" | grep -i -E 'licen|credits|readme' || echo "(no license-like files)"

echo "--- other fonts"
for package in $OTHER_FONTS; do
    printf '%s: ' "$package"
    grep -E '^License:' "/usr/share/doc/$package/copyright" 2>/dev/null | sort -u | tr '\n' ' '
    echo
done
