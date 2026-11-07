#!/bin/bash
# Публикация релиза с .deb на GitHub для версии из файла VERSION.
#   bash publish-release.sh "Что нового в этой версии"
# Сначала подними VERSION, закоммить и запушь изменения: скрипт сам ничего не коммитит.
set -e
cd "$(dirname "$0")"
REPO=Denis1999/keyboard-layout-switcher
VERSION="$(cat VERSION)"
TAG="v$VERSION"
CHANGES="$1"

die() { echo "$*" >&2; exit 1; }

[ -n "$CHANGES" ] || die "Укажи, что нового: bash publish-release.sh \"описание изменений\""
[ -z "$(git status --porcelain)" ] || die "Есть незакоммиченные изменения, сначала закоммить их."
git fetch -q origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] \
    || die "Ветка расходится с origin, сначала сделай push или pull."
! gh release view "$TAG" -R "$REPO" >/dev/null 2>&1 \
    || die "Релиз $TAG уже есть. Подними версию в файле VERSION."

DEB="$(bash build-deb.sh)"

gh release create "$TAG" "$DEB" -R "$REPO" \
    --target "$(git rev-parse HEAD)" \
    --title "$VERSION" \
    --notes "What's new: $CHANGES

Install: download keyboard-layout-switcher_${VERSION}_all.deb and run

\`\`\`
sudo apt install ./keyboard-layout-switcher_${VERSION}_all.deb
\`\`\`

Requires KDE Plasma 6 on Wayland with us + ru layouts. See README for details."

gh release view "$TAG" -R "$REPO" --json url --jq .url
