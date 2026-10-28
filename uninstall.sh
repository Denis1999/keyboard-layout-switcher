#!/bin/bash
# Полное удаление layout-fix, возвращает обычный Caps Lock. Запускать от пользователя:
#   bash uninstall.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
python3 -I "$DIR/remove-old-shortcuts.py" || true
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript layout-fix >/dev/null 2>&1 || true

ROOT_SCRIPT="$(mktemp)"
cat > "$ROOT_SCRIPT" <<'EOF'
#!/bin/bash
systemctl disable --now layout-fix.service 2>/dev/null
rm -f /etc/systemd/system/layout-fix.service /usr/local/sbin/layout-fix-daemon
rm -rf /usr/local/share/layout-fix
systemctl daemon-reload
rm -f /etc/udev/hwdb.d/90-capslock-pause.hwdb
systemd-hwdb update
udevadm trigger --subsystem-match=input --action=change
EOF
chmod +x "$ROOT_SCRIPT"
pkexec "$ROOT_SCRIPT"
rm -f "$ROOT_SCRIPT"
echo "layout-fix удалён. Caps Lock станет обычным после перезагрузки или переподключения клавиатуры."
