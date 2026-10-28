#!/bin/bash
# Удаление. То же самое: sudo apt remove keyboard-layout-switcher
# Запускать от пользователя:  bash uninstall.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

pkexec apt-get remove -y keyboard-layout-switcher
# выгрузить скрипт KWin из текущего сеанса (иначе Pause перехватывается до перезахода)
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript layout-fix >/dev/null 2>&1 || true
python3 -I "$DIR/remove-old-shortcuts.py" >/dev/null 2>&1 || true
echo "Удалено. Обычный Caps Lock вернётся после перезагрузки или переподключения клавиатуры."
