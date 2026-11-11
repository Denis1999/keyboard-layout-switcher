#!/bin/bash
# Коммит, push и публикация релиза с .deb на GitHub.
#   bash publish-release.sh -n NOTES.md [-m "сообщение коммита" | -F COMMIT_MSG_FILE]
#
#   -n  файл со списком изменений (Markdown); раздел про установку
#       добавляется к нему сам
#   -m  сообщение коммита строкой, -F — из файла; нужно, только если есть
#       незакоммиченные изменения
# Версия берётся из VERSION, тег — v<версия>.
set -e
cd "$(dirname "$0")"
REPO=Denis1999/keyboard-layout-switcher

usage() { sed -n '3,8s/^# \{0,1\}//p' "$0" >&2; exit 2; }
NOTES= MSG= MSG_FILE=
while getopts "n:m:F:h" opt; do
    case $opt in
        n) NOTES="$(realpath "$OPTARG")" ;;
        m) MSG="$OPTARG" ;;
        F) MSG_FILE="$(realpath "$OPTARG")" ;;
        *) usage ;;
    esac
done
[ -n "$NOTES" ] || usage
[ -s "$NOTES" ] || { echo "Нет файла с изменениями или он пуст: $NOTES" >&2; exit 1; }

VERSION="$(cat VERSION)"
if gh release view "v$VERSION" -R "$REPO" >/dev/null 2>&1; then
    echo "Релиз v$VERSION уже есть. Подними версию в VERSION." >&2
    exit 1
fi

git add -A
if ! git diff --cached --quiet; then
    if [ -n "$MSG_FILE" ]; then
        git commit -F "$MSG_FILE"
    elif [ -n "$MSG" ]; then
        git commit -m "$MSG"
    else
        git reset -q
        echo "Есть незакоммиченные изменения: укажи сообщение коммита (-m или -F)." >&2
        exit 1
    fi
fi
DEB="$(bash build-deb.sh)"
git push

{
    echo "## Changes"
    echo
    cat "$NOTES"
    echo
    echo "## Install"
    echo
    echo "Download \`$(basename "$DEB")\` and run"
    echo
    echo '```'
    echo "sudo apt install ./$(basename "$DEB")"
    echo '```'
    echo
    echo "Requires KDE Plasma 6 on Wayland with us + ru layouts. See README for details."
} | gh release create "v$VERSION" "$DEB" -R "$REPO" --title "$VERSION" --notes-file -

gh release view "v$VERSION" -R "$REPO" --json url --jq .url
