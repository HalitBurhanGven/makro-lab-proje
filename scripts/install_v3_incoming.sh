#!/bin/sh
set -eu

SOURCE=/home/kali/makro-lab-proje/dist/yetki-deneyi-acilista-v3.ods
DEST=/opt/makro-lab/gelen/yetki-deneyi-acilista-v3.ods
EXPECTED=d8ca56e7aeae884fe89e79e7be672855266176ee1e49bd237c13ab2753ee1f5b

if [ "$(id -u)" -ne 0 ]; then
    echo "Bu alici kopyasi root olarak kurulmalidir." >&2
    exit 1
fi
test -f "$SOURCE"
test -d /opt/makro-lab/gelen
if [ -e "$DEST" ]; then
    echo "Mevcut alici kopyasi ezilmeyecek: $DEST" >&2
    exit 1
fi
ACTUAL=$(sha256sum "$SOURCE" | awk '{print $1}')
if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "Beklenmeyen v3 hash'i: $ACTUAL" >&2
    exit 1
fi
install -o root -g root -m 0444 "$SOURCE" "$DEST"
stat -c '%A %a %U:%G %n' "$DEST"
sha256sum "$SOURCE" "$DEST"
