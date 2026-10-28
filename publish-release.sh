#!/bin/bash
# Коммит, push и публикация релиза с .deb на GitHub.
#   bash publish-release.sh
set -e
cd "$(dirname "$0")"
VERSION="$(cat VERSION)"
DEB="$(bash build-deb.sh)"

git add -A
if ! git diff --cached --quiet; then
    git commit -m "Debian package (.deb), automatic session user detection

- build-deb.sh builds keyboard-layout-switcher_<version>_all.deb with dpkg-deb
- standard paths: /usr/sbin, /usr/share/layout-fix, /usr/lib/systemd/system,
  /usr/lib/udev/hwdb.d; postinst migrates the old manual install
- the service finds the active Wayland session user via logind
  (no LAYOUT_FIX_USER needed) and follows user switches
- the KWin script is unloaded when the service stops
- add missing python3-gi dependency
- install.sh builds and installs the package; uninstall.sh uses apt

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
fi
git push

gh release create "v$VERSION" "$DEB" -R Denis1999/keyboard-layout-switcher \
    --title "$VERSION" \
    --notes "Install: download keyboard-layout-switcher_${VERSION}_all.deb and run

\`\`\`
sudo apt install ./keyboard-layout-switcher_${VERSION}_all.deb
\`\`\`

Requires KDE Plasma 6 on Wayland with us + ru layouts. See README for details."

gh release view "v$VERSION" -R Denis1999/keyboard-layout-switcher --json url --jq .url
