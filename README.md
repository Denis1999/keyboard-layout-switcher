# Keyboard Layout Switcher

[Русский](README.ru.md) | **English**

Fix text typed in the wrong keyboard layout (English ↔ Russian) on **KDE Plasma 6 / Wayland**. Similar to Punto Switcher, xneur or Easy Switcher, but it only acts when you press a key. It never switches layouts on its own.

| Key | What it does |
|---|---|
| **Caps Lock** | Fixes the last word: `ghbdtn` → `привет`. Press again to undo. Works everywhere, terminals included. |
| **Shift+Caps Lock** | Fixes the selected text, each word separately: `руддщ ghbdtn` → `hello привет`. In terminals it fixes the whole line typed since the last Enter instead. |

After the fix, the layout switches to the language of the result. Caps Lock no longer works as Caps Lock.

## Installation

Run as a regular user inside a Plasma Wayland session:

```bash
git clone https://github.com/Denis1999/keyboard-layout-switcher.git
bash keyboard-layout-switcher/install.sh
```

You will be asked for your password once. If Easy Switcher is installed, the installer removes it. The required packages (`wl-clipboard`, `qdbus-qt6`, `python3-dbus`) are installed automatically.

Uninstall: `bash keyboard-layout-switcher/uninstall.sh`. Normal Caps Lock comes back after a reboot or after reconnecting the keyboard.

## How it works

- `90-capslock-pause.hwdb`: a udev hwdb rule that turns Caps Lock into Pause on all USB keyboards. The remap happens in the kernel, so KDE keyboard settings don't affect it.
- `layout-fix-daemon` and `layout-fix.service`: a system service written in Python. It reads keyboards from `/dev/input` and remembers the key codes of the last word and the current line. On Pause it erases what you typed, switches the layout over KDE's D-Bus and types the same keys again through its own virtual keyboard (uinput). It talks to your session (layout, clipboard) as your user, without root.
- `focus.js`: a KWin script. It tells the service which window is active, so it can recognise terminals and password windows. It also grabs Pause so the key never reaches applications.

## Security

Like any tool of this kind, the service sees every key you press. That is why:

- The service runs as root and its files are owned by root. Regular programs can neither read the keyboard nor fake key presses.
- The service has no network access (`PrivateNetwork=yes`), and the system and home directories are read-only for it.
- Only the last word and the current line are kept in memory, 100 key presses at most. They are cleared on Enter, Tab, arrow keys, Ctrl/Alt/Super shortcuts, mouse clicks and window changes. Nothing is written to disk.
- No key presses are remembered at all in password windows (polkit, pinentry, KWallet, KeePassXC, Bitwarden and similar), in windows with titles like "password", "login" or "sign in", on the lock screen, or before you log in.

Two cases are not recognised: a password field on a page with an ordinary title, and a `sudo` prompt in a terminal. On Wayland detecting them would require accessibility (AT-SPI), which would expose the text of every application to any process.

## Limitations

- Shift+Caps Lock pastes the result with Ctrl+V. In terminals the line is fixed instead.
- If you moved the cursor or switched the layout within the line, the buffer is reset. This is deliberate: the service doesn't know where the cursor is.
- Only the `us` and `ru` layouts are supported.
