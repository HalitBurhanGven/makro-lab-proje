#!/bin/sh
set -eu

LAB=/opt/makro-lab
for path in \
    "$LAB" "$LAB/hazirlik" "$LAB/gelen" "$LAB/analiz" \
    "$LAB/hedef" "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" \
    "$LAB/kanit" "$LAB/kanit/kali" "$LAB/kanit/root" "$LAB/rapor" \
    "$LAB/profiller/kali-engelli" "$LAB/profiller/kali-izinli" \
    "$LAB/profiller/root-engelli" "$LAB/profiller/root-izinli"; do
    stat -c '%A %a %U:%G %n' "$path"
done

namei -om "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" "$LAB/gelen/yetki-deneyi-acilista-v3.ods"
getfacl -cp "$LAB/hedef/kullanici-alani" "$LAB/hedef/root-alani" "$LAB/gelen" 2>/dev/null || true

printf 'kali_user_target_writable=%s\n' "$(test -w "$LAB/hedef/kullanici-alani" && echo true || echo false)"
printf 'kali_root_target_writable=%s\n' "$(test -w "$LAB/hedef/root-alani" && echo true || echo false)"
printf 'kali_incoming_document_writable=%s\n' "$(test -w "$LAB/gelen/yetki-deneyi-acilista-v3.ods" && echo true || echo false)"

sha256sum "$LAB/hazirlik/kontrol-makrosuz.ods" "$LAB/gelen/kontrol-makrosuz.ods"
sha256sum "$LAB/hazirlik/yetki-deneyi-acilista-v3.ods" "$LAB/gelen/yetki-deneyi-acilista-v3.ods"
