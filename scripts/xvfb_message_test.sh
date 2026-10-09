#!/bin/sh
set -eu

PROJECT=/home/kali/makro-lab-proje
OUT=${1:-$PROJECT/kanit/xvfb-mesaj-uyumlulugu}
if [ -e "$OUT" ]; then
    echo "Mevcut kanit dizini ezilmeyecek: $OUT" >&2
    exit 1
fi
mkdir -p -m 0750 "$PROJECT/kanit"
mkdir -m 0750 "$OUT"

run_case() {
    case_name=$1
    document=$2
    macro_uri=$3
    profile=$(mktemp -d "/tmp/makro-lab-$case_name.XXXXXX")
    mkdir -m 0700 "$profile/user"
    install -m 0600 "$PROJECT/profiles/xvfb-test-registrymodifications.xcu" "$profile/user/registrymodifications.xcu"
    profile_uri=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$profile")
    printf 'profile=%s\nprofile_uri=%s\ndocument=%s\nmacro_uri=%s\n' "$profile" "$profile_uri" "$document" "$macro_uri" > "$OUT/$case_name-girdi.txt"

    CASE_NAME=$case_name DOCUMENT=$document MACRO_URI=$macro_uri PROFILE_URI=$profile_uri OUT=$OUT \
    xvfb-run -a sh -c '
        set -u
        if [ -n "$MACRO_URI" ]; then
            /usr/bin/libreoffice --nologo --nodefault --nofirststartwizard --norestore "-env:UserInstallation=$PROFILE_URI" "$DOCUMENT" "$MACRO_URI" > "$OUT/$CASE_NAME.stdout" 2> "$OUT/$CASE_NAME.stderr" &
        else
            /usr/bin/libreoffice --nologo --nodefault --nofirststartwizard --norestore "-env:UserInstallation=$PROFILE_URI" "$DOCUMENT" > "$OUT/$CASE_NAME.stdout" 2> "$OUT/$CASE_NAME.stderr" &
        fi
        lo_pid=$!
        printf "launcher_pid=%s\n" "$lo_pid" > "$OUT/$CASE_NAME-process.txt"
        found=
        i=0
        while [ "$i" -lt 150 ]; do
            found=$(xdotool search --name "Makro Laboratuvari" 2>/dev/null | head -n 1 || true)
            [ -n "$found" ] && break
            kill -0 "$lo_pid" 2>/dev/null || break
            i=$((i + 1))
            sleep 0.1
        done
        if [ -z "$found" ]; then
            printf "message_window_found=false\n" >> "$OUT/$CASE_NAME-process.txt"
            kill "$lo_pid" 2>/dev/null || true
            wait "$lo_pid" 2>/dev/null || true
            exit 6
        fi
        printf "message_window_found=true\nwindow_id=%s\n" "$found" >> "$OUT/$CASE_NAME-process.txt"
        ps -eo pid=,ppid=,ruid=,euid=,suid=,user=,args= | awk -v p="$PROFILE_URI" '"'"'index($0,p) && /soffice.bin/ {print}'"'"' >> "$OUT/$CASE_NAME-process.txt"
        xdotool getwindowname "$found" > "$OUT/$CASE_NAME-window-title.txt"
        xwd -silent -id "$found" > "$OUT/$CASE_NAME.xwd"
        xwdtopnm "$OUT/$CASE_NAME.xwd" 2>/dev/null | pnmtopng > "$OUT/$CASE_NAME.png"
        xwd -silent -root > "$OUT/$CASE_NAME-root.xwd"
        xwdtopnm "$OUT/$CASE_NAME-root.xwd" 2>/dev/null | pnmtopng > "$OUT/$CASE_NAME-root.png"
        xdotool key --window "$found" Return
        sleep 0.5
        kill "$lo_pid" 2>/dev/null || true
        wait "$lo_pid" 2>/dev/null || true
    '
}

# Bu ilk kosul UI menusunden elle baslatma degil, acik CLI macro URI cagrisi ile uyumluluk testidir.
run_case cli-acik-cagri "$PROJECT/dist/mesaj-manuel.ods" 'macro://./Standard.Module1.MesajiGoster'
# Bu kosulda ayrica macro URI verilmez; pencere ancak belgede kayitli OnLoad bagiyla olusabilir.
run_case onload-otomatik "$PROJECT/dist/mesaj-acilista.ods" ''

sha256sum "$PROJECT/dist/mesaj-manuel.ods" "$PROJECT/dist/mesaj-acilista.ods" > "$OUT/belge-hashleri.txt"
