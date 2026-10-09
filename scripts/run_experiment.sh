#!/bin/sh
set -eu

if [ "$#" -ne 4 ]; then
    echo "Kullanim: $0 DENEY_ETIKETI PROFIL_DIZINI BELGE KANIT_DIZINI" >&2
    exit 2
fi

LABEL=$1
PROFILE=$2
DOCUMENT=$3
EVIDENCE_ROOT=$4
LAB=/opt/makro-lab

case "$LABEL" in
    *[!A-Za-z0-9_-]*|'') echo "Deney etiketi yalnizca A-Z, a-z, 0-9, - ve _ icerebilir." >&2; exit 2 ;;
esac
test -d "$PROFILE"
test -f "$DOCUMENT"
test -d "$EVIDENCE_ROOT"

if [ -z "${DISPLAY-}" ] && [ -z "${WAYLAND_DISPLAY-}" ]; then
    echo "GUI oturumu bulunamadi. Bu deney VM masaustu terminalinden calistirilmalidir." >&2
    exit 4
fi

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
EXPERIMENT_ID="$LABEL-$STAMP"
OUT="$EVIDENCE_ROOT/$EXPERIMENT_ID"
if [ -e "$OUT" ]; then
    echo "Mevcut kanit dizini ezilmeyecek: $OUT" >&2
    exit 1
fi
mkdir -m 0700 "$OUT"

id > "$OUT/baslatici-kimligi.txt"
sha256sum "$DOCUMENT" > "$OUT/belge-sha256.txt"
stat -c '%A %a %U:%G %n' "$DOCUMENT" "$PROFILE" > "$OUT/girdi-izinleri.txt"
find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f -printf '%M %m %u:%g %s %p\n' 2>&1 | sort > "$OUT/hedefler-once.txt"

PROFILE_URI=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$PROFILE")
export MAKRO_LAB_DENEY_ID=$EXPERIMENT_ID
/usr/bin/libreoffice --nologo --nodefault --nofirststartwizard --norestore \
    "--pidfile=$OUT/soffice.pid" "-env:UserInstallation=$PROFILE_URI" "$DOCUMENT" \
    > "$OUT/libreoffice.stdout" 2> "$OUT/libreoffice.stderr" &
LAUNCH_PID=$!
printf 'launcher_pid=%s\n' "$LAUNCH_PID" > "$OUT/process.txt"

i=0
while [ "$i" -lt 100 ]; do
    if [ -s "$OUT/soffice.pid" ]; then
        APP_PID=$(sed -n '1{s/[^0-9].*$//;p;}' "$OUT/soffice.pid")
        MATCH=$(ps -p "$APP_PID" -o pid=,ppid=,ruid=,euid=,suid=,user=,args= 2>/dev/null || true)
        printf '%s\n' "$MATCH" >> "$OUT/process.txt"
        sed -n '/^Name:/p;/^Pid:/p;/^PPid:/p;/^Uid:/p;/^Gid:/p' "/proc/$APP_PID/status" > "$OUT/process-status.txt" 2>&1 || true
        break
    fi
    if ! kill -0 "$LAUNCH_PID" 2>/dev/null; then break; fi
    i=$((i + 1))
    sleep 0.1
done

echo "LibreOffice penceresindeki deneyi tamamlayip belgeyi kapatin. Bu betik kanitlari sonra toplayacak."
set +e
wait "$LAUNCH_PID"
EXIT_CODE=$?
set -e
printf 'libreoffice_exit=%s\n' "$EXIT_CODE" >> "$OUT/process.txt"

find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f -printf '%M %m %u:%g %s %p\n' 2>&1 | sort > "$OUT/hedefler-sonra.txt"
diff -u "$OUT/hedefler-once.txt" "$OUT/hedefler-sonra.txt" > "$OUT/hedef-farki.diff" || true
find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f -name "$EXPERIMENT_ID-*" -exec stat -c '%A %a %U:%G %s %n' {} + > "$OUT/deney-kanitlari.txt" 2>&1 || true
printf '%s\n' "$EXPERIMENT_ID"
