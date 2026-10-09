#!/bin/sh
set -eu

PROJECT=/home/kali/makro-lab-proje
LAB=/opt/makro-lab
SNAPSHOT=$LAB/kanit/root/snapshot.env
DOCUMENT=$LAB/gelen/yetki-deneyi-acilista-v3.ods
EXPECTED_HASH=d8ca56e7aeae884fe89e79e7be672855266176ee1e49bd237c13ab2753ee1f5b

fail() {
    echo "HATA: $*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || fail "Bu deney root olarak calistirilmalidir."
[ -s "$SNAPSHOT" ] || fail "Snapshot kaydi yok: $SNAPSHOT"
[ -f "$DOCUMENT" ] || fail "Alici belgesi yok: $DOCUMENT"

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
EXPERIMENT_ID=ROOT-IZINLI-V3-$STAMP
OUT=$LAB/kanit/root/$EXPERIMENT_ID
[ ! -e "$OUT" ] || fail "Mevcut kanit dizini ezilmeyecek: $OUT"
mkdir -m 0700 "$OUT"

PROFILE=$(mktemp -d /tmp/makro-lab-root-izinli.XXXXXX)
chmod 0700 "$PROFILE"
mkdir -m 0700 "$PROFILE/user"
install -o root -g root -m 0600 "$PROJECT/profiles/xvfb-test-registrymodifications.xcu" "$PROFILE/user/registrymodifications.xcu"
PROFILE_URI=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$PROFILE")

id > "$OUT/baslatici-kimligi.txt"
printf 'snapshot_name=%s\nsnapshot_time=%s\n' "$SNAPSHOT_NAME" "$SNAPSHOT_TIME" > "$OUT/snapshot-dogrulamasi.txt"
sha256sum "$DOCUMENT" > "$OUT/belge-sha256.txt"
stat -c '%A %a %U:%G %n' "$DOCUMENT" "$PROFILE" > "$OUT/girdi-izinleri.txt"
cp "$PROFILE/user/registrymodifications.xcu" "$OUT/profil-ayari.xcu"
find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f -printf '%M %m %u:%g %s %p\n' | sort > "$OUT/hedefler-once.txt"

EXPERIMENT_ID=$EXPERIMENT_ID DOCUMENT=$DOCUMENT PROFILE_URI=$PROFILE_URI OUT=$OUT \
xvfb-run -a sh -c '
    set -u
    export MAKRO_LAB_DENEY_ID="$EXPERIMENT_ID"
    /usr/bin/libreoffice --nologo --nodefault --nofirststartwizard --norestore \
        "--pidfile=$OUT/soffice.pid" "-env:UserInstallation=$PROFILE_URI" "$DOCUMENT" \
        > "$OUT/libreoffice.stdout" 2> "$OUT/libreoffice.stderr" &
    launcher_pid=$!
    printf "launcher_pid=%s\n" "$launcher_pid" > "$OUT/process.txt"
    app_pid=
    i=0
    while [ "$i" -lt 200 ]; do
        if [ -s "$OUT/soffice.pid" ]; then
            app_pid=$(sed -n '"'"'1{s/[^0-9].*$//;p;}'"'"' "$OUT/soffice.pid")
        fi
        [ -n "$app_pid" ] && break
        kill -0 "$launcher_pid" 2>/dev/null || break
        i=$((i + 1))
        sleep 0.1
    done
    if [ -n "$app_pid" ] && [ -r "/proc/$app_pid/status" ]; then
        ps -p "$app_pid" -o pid,ppid,ruid,euid,suid,user,args >> "$OUT/process.txt" || true
        sed -n "/^Name:/p;/^Pid:/p;/^PPid:/p;/^Uid:/p;/^Gid:/p" "/proc/$app_pid/status" > "$OUT/process-status.txt"
    else
        printf "soffice_bin_found=false\n" >> "$OUT/process.txt"
    fi
    sleep 4
    xwd -silent -root > "$OUT/ekran.xwd" 2>/dev/null || true
    if [ -s "$OUT/ekran.xwd" ]; then
        xwdtopnm "$OUT/ekran.xwd" 2>/dev/null | pnmtopng > "$OUT/ekran.png" || true
    fi
    kill "$launcher_pid" 2>/dev/null || true
    wait "$launcher_pid" 2>/dev/null || true
'

sleep 1
find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f -printf '%M %m %u:%g %s %p\n' | sort > "$OUT/hedefler-sonra.txt"
diff -u "$OUT/hedefler-once.txt" "$OUT/hedefler-sonra.txt" > "$OUT/hedef-farki.diff" || true
find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f -name "$EXPERIMENT_ID-*" -exec stat -c '%A %a %U:%G %s %n' {} + > "$OUT/deney-kanitlari.txt" 2>&1 || true
for evidence in "$LAB/hedef/kullanici-alani/$EXPERIMENT_ID-"*.txt "$LAB/hedef/root-alani/$EXPERIMENT_ID-"*.txt; do
    [ -f "$evidence" ] || continue
    printf '\n===== %s =====\n' "$evidence" >> "$OUT/deney-kanit-icerigi.txt"
    sed -n '1,120p' "$evidence" >> "$OUT/deney-kanit-icerigi.txt"
done

if [ -f "$OUT/process-status.txt" ] && grep -q '^Uid:[[:space:]]*0[[:space:]]*0[[:space:]]*0[[:space:]]*0' "$OUT/process-status.txt"; then
    printf 'uid0_verified=true\n' > "$OUT/sonuc-ozeti.txt"
else
    printf 'uid0_verified=false\n' > "$OUT/sonuc-ozeti.txt"
fi
if [ -f "$LAB/hedef/kullanici-alani/$EXPERIMENT_ID-kullanici-hedefi.txt" ]; then
    printf 'user_target_written=true\n' >> "$OUT/sonuc-ozeti.txt"
else
    printf 'user_target_written=false\n' >> "$OUT/sonuc-ozeti.txt"
fi
if [ -f "$LAB/hedef/root-alani/$EXPERIMENT_ID-root-hedefi.txt" ]; then
    printf 'root_target_written=true\n' >> "$OUT/sonuc-ozeti.txt"
else
    printf 'root_target_written=false\n' >> "$OUT/sonuc-ozeti.txt"
fi

echo "$EXPERIMENT_ID"
cat "$OUT/sonuc-ozeti.txt"
