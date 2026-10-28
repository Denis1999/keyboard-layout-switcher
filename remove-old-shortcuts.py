#!/usr/bin/python3
"""Убирает старые глобальные клавиши layout-fix из ранних версий (ярлыки
net.local.layout-fix-*.desktop). Теперь Pause забирает скрипт KWin focus.js."""
import glob
import os
import subprocess

import dbus

ga = dbus.Interface(dbus.SessionBus().get_object("org.kde.kglobalaccel", "/kglobalaccel"),
                    "org.kde.KGlobalAccel")
for path in glob.glob(os.path.expanduser("~/.local/share/applications/net.local.layout-fix-*.desktop")):
    ga.unregister(os.path.basename(path), "_launch")
    os.remove(path)
    print("убран", os.path.basename(path))
subprocess.run(["kbuildsycoca6"], capture_output=True)
