#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "Kullanim: $0 BELGE.ods CIKTI-DIZINI" >&2
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
unzip -t "$DOCUMENT" > "$OUT/zip-test.txt"
zipinfo -1 "$DOCUMENT" > "$OUT/zip-icerigi.txt"
unzip -p "$DOCUMENT" META-INF/manifest.xml > "$OUT/manifest.xml"
unzip -p "$DOCUMENT" content.xml > "$OUT/content.xml"
if zipinfo -1 "$DOCUMENT" | grep -qx 'Basic/Standard/Module1.xml'; then
    unzip -p "$DOCUMENT" Basic/Standard/Module1.xml > "$OUT/Module1.xml"
fi
oledump.py "$DOCUMENT" > "$OUT/oledump.txt" 2>&1 || true
xmllint --format "$OUT/manifest.xml" > "$OUT/manifest.pretty.xml"
xmllint --format "$OUT/content.xml" > "$OUT/content.pretty.xml"
if [ -f "$OUT/Module1.xml" ]; then
    xmllint --format "$OUT/Module1.xml" > "$OUT/Module1.pretty.xml"
fi
SEARCH_FILES="$OUT/content.pretty.xml"
if [ -f "$OUT/Module1.pretty.xml" ]; then
    SEARCH_FILES="$SEARCH_FILES $OUT/Module1.pretty.xml"
fi
# shellcheck disable=SC2086
grep -n -E 'OnLoad|Acilista|vnd\.sun\.star\.script|script:event|event-listener' $SEARCH_FILES > "$OUT/olay-ve-makro-eslesmeleri.txt" || true
