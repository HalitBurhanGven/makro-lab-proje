#!/bin/sh
set -eu

PROJECT=/home/kali/makro-lab-proje
LAB=/opt/makro-lab

if [ "$(id -u)" -ne 0 ]; then
    echo "Bu betik yalnizca laboratuvar dizinlerini kurmak icin root olarak calistirilmalidir." >&2
    exit 1
fi

if [ -e "$LAB" ]; then
    echo "Mevcut alan otomatik degistirilmeyecek: $LAB" >&2
    exit 1
fi

for document in kontrol-makrosuz.ods mesaj-manuel.ods mesaj-acilista.ods yetki-deneyi-acilista.ods yetki-deneyi-acilista-v2.ods yetki-deneyi-acilista-v3.ods; do
    test -f "$PROJECT/dist/$document"
done

install -d -o root -g root -m 0755 "$LAB"
install -d -o kali -g kali -m 0750 "$LAB/hazirlik" "$LAB/analiz" "$LAB/rapor"
install -d -o root -g root -m 0755 "$LAB/gelen" "$LAB/hedef" "$LAB/kanit" "$LAB/profiller"
install -d -o kali -g kali -m 0700 "$LAB/hedef/kullanici-alani" "$LAB/kanit/kali"
install -d -o root -g root -m 0700 "$LAB/hedef/root-alani" "$LAB/kanit/root"
install -d -o kali -g kali -m 0750 "$LAB/hazirlik/makro-kaynaklari" "$LAB/analiz/cyberchef" "$LAB/analiz/vba-adayi"

install -d -o kali -g kali -m 0700 "$LAB/profiller/kali-engelli/user" "$LAB/profiller/kali-izinli/user"
install -d -o root -g root -m 0700 "$LAB/profiller/root-engelli/user" "$LAB/profiller/root-izinli/user"
install -o kali -g kali -m 0600 "$PROJECT/profiles/blocked-registrymodifications.xcu" "$LAB/profiller/kali-engelli/user/registrymodifications.xcu"
install -o kali -g kali -m 0600 "$PROJECT/profiles/allowed-registrymodifications.xcu" "$LAB/profiller/kali-izinli/user/registrymodifications.xcu"
install -o root -g root -m 0600 "$PROJECT/profiles/blocked-registrymodifications.xcu" "$LAB/profiller/root-engelli/user/registrymodifications.xcu"
install -o root -g root -m 0600 "$PROJECT/profiles/allowed-registrymodifications.xcu" "$LAB/profiller/root-izinli/user/registrymodifications.xcu"

for document in kontrol-makrosuz.ods mesaj-manuel.ods mesaj-acilista.ods yetki-deneyi-acilista.ods yetki-deneyi-acilista-v2.ods yetki-deneyi-acilista-v3.ods; do
    install -o kali -g kali -m 0640 "$PROJECT/dist/$document" "$LAB/hazirlik/$document"
done
install -o kali -g kali -m 0640 "$PROJECT/src/MesajMakrosu.bas" "$LAB/hazirlik/makro-kaynaklari/MesajMakrosu.bas"
install -o kali -g kali -m 0640 "$PROJECT/src/YetkiDeneyi.bas" "$LAB/hazirlik/makro-kaynaklari/YetkiDeneyi.bas"

for document in kontrol-makrosuz.ods yetki-deneyi-acilista-v3.ods; do
    install -o root -g root -m 0444 "$PROJECT/dist/$document" "$LAB/gelen/$document"
done

cp -a "$PROJECT/analiz/." "$LAB/analiz/"
chown -R kali:kali "$LAB/analiz"
find "$LAB/analiz" -type d -exec chmod 0750 {} +
find "$LAB/analiz" -type f -exec chmod 0640 {} +
install -o kali -g kali -m 0640 "$PROJECT/cyberchef/girdi-base64.txt" "$LAB/analiz/cyberchef/girdi-base64.txt"
install -o kali -g kali -m 0640 "$PROJECT/cyberchef/tarif.json" "$LAB/analiz/cyberchef/tarif.json"
install -o kali -g kali -m 0640 "$PROJECT/cyberchef/beklenen-metin.txt" "$LAB/analiz/cyberchef/beklenen-metin.txt"
install -o kali -g kali -m 0640 "$PROJECT/dist/vba-adayi/yetki-deneyi-acilista.xlsm" "$LAB/analiz/vba-adayi/GEÇERSİZ-VBA-ADAYI.xlsm"
install -o kali -g kali -m 0640 "$PROJECT/README.md" "$LAB/rapor/README.md"
install -o kali -g kali -m 0640 "$PROJECT/docs/KISA-DENEY-RAPORU.md" "$LAB/rapor/KISA-DENEY-RAPORU.md"
install -o kali -g kali -m 0640 "$PROJECT/docs/VBA-SINIRLARI.md" "$LAB/rapor/VBA-SINIRLARI.md"
install -o kali -g kali -m 0640 "$PROJECT/docs/SNAPSHOT-VE-GUI.md" "$LAB/rapor/SNAPSHOT-VE-GUI.md"
install -o kali -g kali -m 0640 "$PROJECT/docs/DEVAM-ADIMLARI.md" "$LAB/rapor/DEVAM-ADIMLARI.md"

install -o root -g root -m 0600 /dev/null "$LAB/kanit/root/SNAPSHOT-GEREKLI.txt"
printf '%s\n' \
    'Root LibreOffice deneyi henuz yapilmadi.' \
    'Once VirtualBox host tarafinda snapshot adini ve zamanini dogrulayin.' \
    'Ardindan snapshot.env dosyasina snapshot_name ve snapshot_time degerlerini yazin.' \
    > "$LAB/kanit/root/SNAPSHOT-GEREKLI.txt"

sha256sum "$LAB/hazirlik/kontrol-makrosuz.ods" "$LAB/gelen/kontrol-makrosuz.ods"
sha256sum "$LAB/hazirlik/yetki-deneyi-acilista-v3.ods" "$LAB/gelen/yetki-deneyi-acilista-v3.ods"
