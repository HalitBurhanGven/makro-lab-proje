#!/bin/sh
set -eu

LAB=/opt/makro-lab
SNAPSHOT="$LAB/kanit/root/snapshot.env"

if [ "$(id -u)" -ne 0 ]; then
    echo "Root deneyi root olarak calistirilmalidir." >&2
    exit 1
fi
if [ ! -s "$SNAPSHOT" ]; then
    echo "Root deneyi durduruldu: $SNAPSHOT ile snapshot adi/zamani kaydedilmedi." >&2
    exit 5
fi
if ! grep -Eq '^snapshot_name=.+$' "$SNAPSHOT" || ! grep -Eq '^snapshot_time=.+$' "$SNAPSHOT"; then
    echo "Root deneyi durduruldu: snapshot.env gerekli alanlari icermiyor." >&2
    exit 5
fi

exec /home/kali/makro-lab-proje/scripts/run_experiment.sh \
    ROOT-IZINLI \
    "$LAB/profiller/root-izinli" \
    "$LAB/gelen/yetki-deneyi-acilista-v3.ods" \
    "$LAB/kanit/root"
