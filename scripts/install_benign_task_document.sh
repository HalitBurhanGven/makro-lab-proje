#!/bin/sh
set -eu

PROJECT=/home/kali/makro-lab-proje
LAB=/opt/makro-lab
SOURCE=$PROJECT/dist/gorev-deneyi-acilista-v4.ods
TARGET=$LAB/gelen/gorev-deneyi-acilista-v4.ods
HASHFILE=$LAB/gelen/gorev-deneyi-acilista-v4.sha256

[ "$(id -u)" -eq 0 ] || { echo "Bu teslim adimi root olarak calistirilmalidir." >&2; exit 1; }
[ -f "$SOURCE" ] || { echo "Once Kali rolunde belgeyi uretin: $SOURCE" >&2; exit 1; }
[ ! -e "$TARGET" ] || { echo "Mevcut alici belgesi ezilmeyecek: $TARGET" >&2; exit 1; }
[ ! -e "$HASHFILE" ] || { echo "Mevcut hash kaydi ezilmeyecek: $HASHFILE" >&2; exit 1; }

install -o root -g root -m 0444 "$SOURCE" "$TARGET"
sha256sum "$TARGET" > "$HASHFILE"
chown root:root "$HASHFILE"
chmod 0444 "$HASHFILE"

stat -c '%A %a %U:%G %n' "$TARGET" "$HASHFILE"
sha256sum "$SOURCE" "$TARGET"
