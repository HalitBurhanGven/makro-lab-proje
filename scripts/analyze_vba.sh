#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "Kullanim: $0 BELGE CIKTI-DIZINI" >&2
    exit 2
fi

DOCUMENT=$1
OUT=$2
test -f "$DOCUMENT"
if [ -e "$OUT" ]; then
    echo "Mevcut analiz dizini ezilmeyecek: $OUT" >&2
    exit 1
fi
mkdir -m 0750 "$OUT"

file "$DOCUMENT" > "$OUT/file.txt"
sha256sum "$DOCUMENT" > "$OUT/sha256.txt"
oledump.py "$DOCUMENT" > "$OUT/akislar.txt" 2>&1 || true
awk '$2 ~ /^[Mm!]$/ {gsub(":", "", $1); print $1}' "$OUT/akislar.txt" > "$OUT/makro-akis-kimlikleri.txt"

if [ ! -s "$OUT/makro-akis-kimlikleri.txt" ]; then
    printf '%s\n' 'Gercek VBA modulu gosteren M/m/! akisi bulunamadi.' > "$OUT/VBA-BULUNAMADI.txt"
    exit 3
fi

while IFS= read -r stream; do
    safe_stream=$(printf '%s' "$stream" | tr -cd 'A-Za-z0-9_-')
    oledump.py -s "$stream" -v "$DOCUMENT" > "$OUT/stream-$safe_stream.vba" 2> "$OUT/stream-$safe_stream.stderr" || true
done < "$OUT/makro-akis-kimlikleri.txt"
