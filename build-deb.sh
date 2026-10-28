#!/bin/bash
# Сборка пакета: bash build-deb.sh  ->  dist/keyboard-layout-switcher_<версия>_all.deb
# Нужен только dpkg-deb (есть в любой Debian/Ubuntu).
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(cat "$DIR/VERSION")"
PKG=keyboard-layout-switcher
ROOT="$(mktemp -d)"
chmod 755 "$ROOT"  # mktemp даёт 700, а это права корня пакета
trap 'rm -rf "$ROOT"' EXIT

install -D -m 755 "$DIR/layout-fix-daemon"        "$ROOT/usr/sbin/layout-fix-daemon"
install -D -m 644 "$DIR/focus.js"                 "$ROOT/usr/share/layout-fix/focus.js"
install -D -m 644 "$DIR/layout-fix.service"       "$ROOT/usr/lib/systemd/system/layout-fix.service"
install -D -m 644 "$DIR/90-capslock-pause.hwdb"   "$ROOT/usr/lib/udev/hwdb.d/90-capslock-pause.hwdb"
install -D -m 644 "$DIR/README.md"                "$ROOT/usr/share/doc/$PKG/README.md"
install -D -m 644 "$DIR/README.ru.md"             "$ROOT/usr/share/doc/$PKG/README.ru.md"

mkdir -p "$ROOT/DEBIAN"
sed "s/@VERSION@/$VERSION/" "$DIR/debian/control" > "$ROOT/DEBIAN/control"
echo "Installed-Size: $(du -sk --exclude=DEBIAN "$ROOT" | cut -f1)" >> "$ROOT/DEBIAN/control"
for s in postinst prerm postrm; do
    install -m 755 "$DIR/debian/$s" "$ROOT/DEBIAN/$s"
done

mkdir -p "$DIR/dist"
OUT="$DIR/dist/${PKG}_${VERSION}_all.deb"
dpkg-deb --root-owner-group -Zxz --build "$ROOT" "$OUT" >/dev/null
echo "$OUT"
