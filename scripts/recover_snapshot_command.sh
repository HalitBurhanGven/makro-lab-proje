#!/bin/sh
set -eu

ROOT_EVIDENCE=/opt/makro-lab/kanit/root
SNAPSHOT=$ROOT_EVIDENCE/snapshot.env

if [ "$(id -u)" -ne 0 ]; then
    echo "Kurtarma root olarak calistirilmalidir." >&2
    exit 1
fi
if [ "$#" -ne 2 ]; then
    echo "Kullanim: $0 GERCEK_SNAPSHOT_ADI GERCEK_SNAPSHOT_ZAMANI" >&2
    exit 2
fi
NAME=$1
TIME=$2
case "$NAME|$TIME" in
    *SNAPSHOT-ADI*|*SNAPSHOT-ZAMANI*|*DOGRULANAN*|'|'|\ *|' '*|*'| '|*'|')
        echo "Placeholder veya bos snapshot bilgisi kabul edilmedi." >&2
        exit 2
        ;;
esac

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
ARCHIVE=$ROOT_EVIDENCE/yanlis-komut-$STAMP
if [ -e "$ARCHIVE" ]; then
    echo "Mevcut arsiv ezilmeyecek: $ARCHIVE" >&2
    exit 1
fi
mkdir -m 0700 "$ARCHIVE"

for accidental in /home/kali/sudo /home/kali/chmod /home/kali/0600; do
    if [ -e "$accidental" ]; then
        if ! grep -q '^snapshot_name=' "$accidental"; then
            echo "Beklenmeyen icerik nedeniyle dosya tasinmadi: $accidental" >&2
            exit 1
        fi
        mv "$accidental" "$ARCHIVE/"
    fi
done
if [ -e "$SNAPSHOT" ]; then
    mv "$SNAPSHOT" "$ARCHIVE/snapshot.env.invalid"
fi

TEMP=$(mktemp "$ROOT_EVIDENCE/snapshot.env.new.XXXXXX")
chmod 0600 "$TEMP"
printf 'snapshot_name=%s\nsnapshot_time=%s\n' "$NAME" "$TIME" > "$TEMP"
mv "$TEMP" "$SNAPSHOT"
chmod 0600 "$SNAPSHOT"

echo "Yanlis komut dosyalari silinmedi; $ARCHIVE altina tasindi."
echo "Snapshot kaydi olusturuldu:"
cat "$SNAPSHOT"
