#!/bin/bash
# Установка layout-fix (вместо Easy Switcher).
# Запускать от обычного пользователя внутри сеанса KDE Plasma 6 (Wayland):
#   bash install.sh
# Пароль спросят один раз (pkexec).
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
ME="$(id -un)"

if [ "$(id -u)" = 0 ]; then
    echo "Запускай от обычного пользователя, не от root." >&2; exit 1
fi
if [ -z "$WAYLAND_DISPLAY" ] || ! command -v plasmashell >/dev/null; then
    echo "Нужен сеанс KDE Plasma на Wayland." >&2; exit 1
fi

# старые ярлыки ранних версий мешают скрипту KWin занять Pause
python3 -I "$DIR/remove-old-shortcuts.py"

ROOT_SCRIPT="$(mktemp)"
cat > "$ROOT_SCRIPT" <<EOF
#!/bin/bash
set -e
echo "== Удаление Easy Switcher (если есть)"
systemctl disable --now easy-switcher.service 2>/dev/null || true
if dpkg -s easy-switcher >/dev/null 2>&1; then apt-get purge -y easy-switcher; fi
rm -f /lib/systemd/system/easy-switcher.service /etc/systemd/system/easy-switcher.service \
      /usr/bin/easy-switcher /usr/local/bin/easy-switcher
rm -rf /etc/easy-switcher

echo "== Пакеты"
apt-get install -y wl-clipboard qdbus-qt6 python3-dbus

echo "== Caps Lock -> Pause"
install -o root -g root -m 644 "$DIR/90-capslock-pause.hwdb" /etc/udev/hwdb.d/
systemd-hwdb update
udevadm trigger --subsystem-match=input --action=change

echo "== Служба layout-fix"
install -o root -g root -m 755 "$DIR/layout-fix-daemon" /usr/local/sbin/
install -o root -g root -m 755 -d /usr/local/share/layout-fix
install -o root -g root -m 644 "$DIR/focus.js" /usr/local/share/layout-fix/
sed "s/@USER@/$ME/" "$DIR/layout-fix.service" > /etc/systemd/system/layout-fix.service
chmod 644 /etc/systemd/system/layout-fix.service
systemctl daemon-reload
systemctl enable layout-fix.service
systemctl restart layout-fix.service
EOF
chmod +x "$ROOT_SCRIPT"
pkexec "$ROOT_SCRIPT"
rm -f "$ROOT_SCRIPT"


sleep 1
systemctl is-active layout-fix.service >/dev/null && echo "Готово: Caps Lock — слово, Shift+Caps Lock — выделенное." \
    || { echo "Служба не запустилась, смотри: journalctl -u layout-fix"; exit 1; }
