#!/bin/sh
set -eu

PROJECT=/home/kali/makro-lab-proje
LAB=/opt/makro-lab
SNAPSHOT=$LAB/kanit/root/snapshot.env
DOCUMENT_NAME=${MAKRO_LAB_DOCUMENT_NAME:-yetki-deneyi-acilista-v3.ods}
DOCUMENT=$LAB/gelen/$DOCUMENT_NAME
EXPERIMENT_PREFIX=${MAKRO_LAB_EXPERIMENT_PREFIX:-ROOT-GORUNUR-IZINLI-V3}
EXPECTED_HASH_FILE=${MAKRO_LAB_EXPECTED_HASH_FILE:-}
EXPECTED_HASH=${MAKRO_LAB_EXPECTED_HASH:-d8ca56e7aeae884fe89e79e7be672855266176ee1e49bd237c13ab2753ee1f5b}
USER_EVIDENCE_SUFFIX=${MAKRO_LAB_USER_EVIDENCE_SUFFIX:-kullanici-hedefi}
ROOT_EVIDENCE_SUFFIX=${MAKRO_LAB_ROOT_EVIDENCE_SUFFIX:-root-hedefi}

fail() {
    echo "HATA: $*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || fail "Bu deney root olarak calistirilmalidir."
[ -n "${DISPLAY-}" ] || fail "DISPLAY tanimli degil."
[ -r "${XAUTHORITY-}" ] || fail "XAUTHORITY okunamiyor: ${XAUTHORITY-<bos>}"
[ -s "$SNAPSHOT" ] || fail "Snapshot kaydi yok: $SNAPSHOT"
[ -f "$DOCUMENT" ] || fail "Alici belgesi yok: $DOCUMENT"

if [ -n "$EXPECTED_HASH_FILE" ]; then
    [ -f "$EXPECTED_HASH_FILE" ] || fail "Hash kaydi yok: $EXPECTED_HASH_FILE"
    EXPECTED_HASH=$(awk 'NR == 1 {print $1}' "$EXPECTED_HASH_FILE")
fi
printf '%s\n' "$EXPECTED_HASH" | grep -Eq '^[0-9a-f]{64}$' || \
    fail "Gecersiz beklenen SHA-256: $EXPECTED_HASH"

[ "$(grep -c '^snapshot_name=' "$SNAPSHOT")" -eq 1 ] || fail "snapshot_name tam olarak bir kez bulunmali."
[ "$(grep -c '^snapshot_time=' "$SNAPSHOT")" -eq 1 ] || fail "snapshot_time tam olarak bir kez bulunmali."
SNAPSHOT_NAME=$(sed -n 's/^snapshot_name=//p' "$SNAPSHOT")
SNAPSHOT_TIME=$(sed -n 's/^snapshot_time=//p' "$SNAPSHOT")
case "$SNAPSHOT_NAME|$SNAPSHOT_TIME" in
    *SNAPSHOT-ADI*|*SNAPSHOT-ZAMANI*|*DOGRULANAN*|'|'|\ *|' '*|*'| '|*'|')
        fail "Gercek snapshot adi ve zamani kaydedilmemis."
        ;;
esac

ACTUAL_HASH=$(sha256sum "$DOCUMENT" | awk '{print $1}')
[ "$ACTUAL_HASH" = "$EXPECTED_HASH" ] || fail "Belge hash'i beklenenden farkli: $ACTUAL_HASH"

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
EXPERIMENT_ID=$EXPERIMENT_PREFIX-$STAMP
OUT=$LAB/kanit/root/$EXPERIMENT_ID
[ ! -e "$OUT" ] || fail "Mevcut kanit dizini ezilmeyecek: $OUT"
mkdir -m 0700 "$OUT"

# Profil deney kanit dizininin icinde tutulur; gunluk veya kalici profil degismez.
PROFILE=$OUT/libreoffice-profili
mkdir -m 0700 "$PROFILE" "$PROFILE/user"
install -o root -g root -m 0600 \
    "$PROJECT/profiles/xvfb-test-registrymodifications.xcu" \
    "$PROFILE/user/registrymodifications.xcu"
PROFILE_URI=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$PROFILE")

id > "$OUT/baslatici-kimligi.txt"
printf 'snapshot_name=%s\nsnapshot_time=%s\n' "$SNAPSHOT_NAME" "$SNAPSHOT_TIME" > "$OUT/snapshot-dogrulamasi.txt"
sha256sum "$DOCUMENT" > "$OUT/belge-sha256.txt"
stat -c '%A %a %U:%G %n' "$DOCUMENT" "$PROFILE" > "$OUT/girdi-izinleri.txt"
cp "$PROFILE/user/registrymodifications.xcu" "$OUT/baslangic-profil-ayari.xcu"
find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f \
    -printf '%M %m %u:%g %s %p\n' | sort > "$OUT/hedefler-once.txt"

export MAKRO_LAB_DENEY_ID=$EXPERIMENT_ID
/usr/bin/libreoffice --nologo --nodefault --nofirststartwizard --norestore \
    "--pidfile=$OUT/soffice.pid" "-env:UserInstallation=$PROFILE_URI" "$DOCUMENT" \
    > "$OUT/libreoffice.stdout" 2> "$OUT/libreoffice.stderr" &
LAUNCH_PID=$!
printf 'launcher_pid=%s\n' "$LAUNCH_PID" > "$OUT/process.txt"

APP_PID=
i=0
while [ "$i" -lt 200 ]; do
    if [ -s "$OUT/soffice.pid" ]; then
        APP_PID=$(sed -n '1{s/[^0-9].*$//;p;}' "$OUT/soffice.pid")
    fi
    [ -n "$APP_PID" ] && break
    kill -0 "$LAUNCH_PID" 2>/dev/null || break
    i=$((i + 1))
    sleep 0.1
done

if [ -n "$APP_PID" ] && [ -r "/proc/$APP_PID/status" ]; then
    ps -p "$APP_PID" -o pid,ppid,ruid,euid,suid,user,args >> "$OUT/process.txt" || true
    sed -n '/^Name:/p;/^Pid:/p;/^PPid:/p;/^Uid:/p;/^Gid:/p' \
        "/proc/$APP_PID/status" > "$OUT/process-status.txt"
else
    printf 'soffice_bin_found=false\n' >> "$OUT/process.txt"
fi

echo "Calc gorunur durumda. Bu deneye ozel profil makroya izin verir; acilis makrosu otomatik tetiklenmelidir."
echo "Gozlem bitince LibreOffice'in tum pencerelerini kapatin."
set +e
wait "$LAUNCH_PID"
EXIT_CODE=$?
set -e
printf 'libreoffice_exit=%s\n' "$EXIT_CODE" >> "$OUT/process.txt"

find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f \
    -printf '%M %m %u:%g %s %p\n' | sort > "$OUT/hedefler-sonra.txt"
diff -u "$OUT/hedefler-once.txt" "$OUT/hedefler-sonra.txt" > "$OUT/hedef-farki.diff" || true
find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f \
    -name "$EXPERIMENT_ID-*" -exec stat -c '%A %a %U:%G %s %n' {} + \
    > "$OUT/deney-kanitlari.txt" 2>&1 || true

if [ -f "$OUT/process-status.txt" ] && grep -q '^Uid:[[:space:]]*0[[:space:]]*0[[:space:]]*0[[:space:]]*0' "$OUT/process-status.txt"; then
    UID0=true
else
    UID0=false
fi
if [ -f "$LAB/hedef/kullanici-alani/$EXPERIMENT_ID-$USER_EVIDENCE_SUFFIX.txt" ]; then
    USER_WRITTEN=true
else
    USER_WRITTEN=false
fi
if [ -f "$LAB/hedef/root-alani/$EXPERIMENT_ID-$ROOT_EVIDENCE_SUFFIX.txt" ]; then
    ROOT_WRITTEN=true
else
    ROOT_WRITTEN=false
fi

printf 'uid0_verified=%s\nuser_target_written=%s\nroot_target_written=%s\n' \
    "$UID0" "$USER_WRITTEN" "$ROOT_WRITTEN" > "$OUT/sonuc-ozeti.txt"

echo "$EXPERIMENT_ID"
cat "$OUT/sonuc-ozeti.txt"
if [ "$USER_WRITTEN" != true ] && [ "$ROOT_WRITTEN" != true ]; then
    echo "NOT: Belge acildi fakat makro kaniti yok; makro izni verilmemis veya tetiklenmemis olabilir."
fi
