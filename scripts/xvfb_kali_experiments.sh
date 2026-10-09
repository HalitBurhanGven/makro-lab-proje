#!/bin/sh
set -eu

PROJECT=/home/kali/makro-lab-proje
LAB=/opt/makro-lab

if [ "$(id -u)" -ne 1000 ]; then
    echo "Bu deney kali (UID 1000) olarak calistirilmalidir." >&2
    exit 1
fi
test -d "$LAB/kanit/kali"
test -w "$LAB/hedef/kullanici-alani"
test ! -w "$LAB/hedef/root-alani"

new_low_profile() {
    profile=$(mktemp -d /tmp/makro-lab-kali-izinli.XXXXXX)
    mkdir -m 0700 "$profile/user"
    install -m 0600 "$PROJECT/profiles/xvfb-test-registrymodifications.xcu" "$profile/user/registrymodifications.xcu"
    printf '%s\n' "$profile"
}

run_case() {
    label=$1
    profile=$2
    document=$3
    stamp=$(date -u +%Y%m%dT%H%M%SZ)
    experiment_id="$label-$stamp"
    out="$LAB/kanit/kali/$experiment_id"
    if [ -e "$out" ]; then
        echo "Mevcut kanit dizini ezilmeyecek: $out" >&2
        exit 1
    fi
    mkdir -m 0700 "$out"
    profile_uri=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$profile")

    id > "$out/baslatici-kimligi.txt"
    sha256sum "$document" > "$out/belge-sha256.txt"
    stat -c '%A %a %U:%G %n' "$document" "$profile" > "$out/girdi-izinleri.txt"
    find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f -printf '%M %m %u:%g %s %p\n' 2>&1 | sort > "$out/hedefler-once.txt"
    cp "$profile/user/registrymodifications.xcu" "$out/profil-ayari.xcu"
    chmod 0600 "$out/profil-ayari.xcu"

    CASE_LABEL=$label EXPERIMENT_ID=$experiment_id DOCUMENT=$document PROFILE_URI=$profile_uri OUT=$out \
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
        if [ -n "$app_pid" ]; then
            ps -p "$app_pid" -o pid,ppid,ruid,euid,suid,user,args >> "$OUT/process.txt" || true
            if [ -r "/proc/$app_pid/status" ]; then
                sed -n "/^Name:/p;/^Pid:/p;/^PPid:/p;/^Uid:/p;/^Gid:/p" "/proc/$app_pid/status" > "$OUT/process-status.txt"
            fi
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
    find "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" -maxdepth 1 -type f -printf '%M %m %u:%g %s %p\n' 2>&1 | sort > "$out/hedefler-sonra.txt"
    diff -u "$out/hedefler-once.txt" "$out/hedefler-sonra.txt" > "$out/hedef-farki.diff" || true
    find "$LAB/hedef/kullanici-alani" -maxdepth 1 -type f -name "$experiment_id-*" -exec stat -c '%A %a %U:%G %s %n' {} + > "$out/deney-kanitlari.txt" 2>&1 || true
    for evidence in "$LAB/hedef/kullanici-alani/$experiment_id-"*.txt; do
        [ -f "$evidence" ] || continue
        printf '\n===== %s =====\n' "$evidence" >> "$out/deney-kanit-icerigi.txt"
        sed -n '1,120p' "$evidence" >> "$out/deney-kanit-icerigi.txt"
    done
    printf '%s\n' "$experiment_id"
}

if [ "${1-}" = "--v2-only" ]; then
    V2_PROFILE=$(new_low_profile)
    run_case KALI-IZINLI-V2 "$V2_PROFILE" "$PROJECT/dist/yetki-deneyi-acilista-v2.ods"
    exit 0
fi

if [ "${1-}" = "--v3-only" ]; then
    V3_PROFILE=$(new_low_profile)
    run_case KALI-IZINLI-V3 "$V3_PROFILE" "$PROJECT/dist/yetki-deneyi-acilista-v3.ods"
    exit 0
fi

if [ "${1-}" = "--final-control-blocked" ]; then
    FINAL_CONTROL_PROFILE=$(new_low_profile)
    run_case KONTROL-KALI-FINAL "$FINAL_CONTROL_PROFILE" "$LAB/gelen/kontrol-makrosuz.ods"
    run_case KALI-ENGELLI-V3 "$LAB/profiller/kali-engelli" "$PROJECT/dist/yetki-deneyi-acilista-v3.ods"
    exit 0
fi

CONTROL_PROFILE=$(new_low_profile)
run_case KONTROL-KALI "$CONTROL_PROFILE" "$LAB/gelen/kontrol-makrosuz.ods"
run_case KALI-ENGELLI "$LAB/profiller/kali-engelli" "$LAB/gelen/yetki-deneyi-acilista-v3.ods"
ALLOWED_PROFILE=$(new_low_profile)
run_case KALI-IZINLI-IZOLE "$ALLOWED_PROFILE" "$LAB/gelen/yetki-deneyi-acilista-v3.ods"
