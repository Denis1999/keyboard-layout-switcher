#!/bin/bash
# Установка из исходников: собирает .deb и ставит его через apt.
# Готовый пакет можно скачать на странице Releases — тогда достаточно:
#   sudo apt install ./keyboard-layout-switcher_<версия>_all.deb
# Запускать от обычного пользователя:  bash install.sh   (пароль спросят один раз)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$(id -u)" = 0 ]; then
    echo "Запускай от обычного пользователя, не от root." >&2; exit 1
fi

DEB="$(bash "$DIR/build-deb.sh")"
echo "Собран пакет: $DEB"

# старые ярлыки ранних версий мешают скрипту KWin занять Pause
if [ -n "$WAYLAND_DISPLAY" ] && ls ~/.local/share/applications/net.local.layout-fix-*.desktop >/dev/null 2>&1; then
    python3 -I "$DIR/remove-old-shortcuts.py"
fi

# apt берёт файл от имени root; копия в /tmp, чтобы не было предупреждения о доступе к домашней папке
TMP="$(mktemp -d)"; chmod 755 "$TMP"; cp "$DEB" "$TMP/"; chmod 644 "$TMP"/*.deb
pkexec apt-get install -y --reinstall "$TMP/$(basename "$DEB")"
rm -rf "$TMP"

sleep 2
systemctl is-active layout-fix.service >/dev/null \
    && echo "Готово: Caps Lock — слово, Shift+Caps Lock — выделенное (в терминале — строка)." \
    || { echo "Служба не запустилась, смотри: journalctl -u layout-fix"; exit 1; }
