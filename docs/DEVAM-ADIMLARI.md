# Uygulanan ve isteğe bağlı kullanıcı adımları

> Durum (2026-10-09): Kurulum, üç `kali` koşulu ve `ROOT-IZINLI-V3-20261009T152555Z` root/Xvfb koşulu tamamlandı. Aşağıdaki komutlar tekrarlanabilirlik kaydıdır; aynı deney kimliklerini veya mevcut kanıtları ezmez. Gerçek UI menüsünden elle mesaj çalıştırma testi isteğe bağlı olarak beklemektedir.

Codex oturumunda `sudo -n` parola istediği ve grafik oturumu bulunmadığı için aşağıdaki adımlar VM’nin masaüstü terminalinde yapılmalıdır.

## 1. Bir kerelik root kurulumu

```sh
sudo /home/kali/makro-lab-proje/scripts/install_lab.sh
/home/kali/makro-lab-proje/scripts/verify_lab.sh | tee /opt/makro-lab/kanit/kali/izin-dogrulama.txt
```

Kurulum betiği `/opt/makro-lab` zaten varsa durur; mevcut alanı veya dosyaları ezmez.

## 2. Kali deneyleri

Her komutta LibreOffice penceresi kapanana kadar başlatıcı kanıt toplar. İzinli koşulda LibreOffice sorarsa **Makroları Etkinleştir** seçilmelidir.

```sh
/home/kali/makro-lab-proje/scripts/run_experiment.sh KONTROL-KALI /opt/makro-lab/profiller/kali-izinli /opt/makro-lab/gelen/kontrol-makrosuz.ods /opt/makro-lab/kanit/kali

/home/kali/makro-lab-proje/scripts/run_experiment.sh KALI-ENGELLI /opt/makro-lab/profiller/kali-engelli /opt/makro-lab/gelen/yetki-deneyi-acilista-v3.ods /opt/makro-lab/kanit/kali

/home/kali/makro-lab-proje/scripts/run_experiment.sh KALI-IZINLI /opt/makro-lab/profiller/kali-izinli /opt/makro-lab/gelen/yetki-deneyi-acilista-v3.ods /opt/makro-lab/kanit/kali
```

Mesaj belgesinin gerçek UI elle çalıştırma testi için `mesaj-manuel.ods` dosyasını izinli profille açın; **Araçlar → Makrolar → Makroları Düzenle → Basic** yolundan `Standard.Module1.MesajiGoster` seçilip çalıştırılmalıdır. Bu gözlem otomatik tetik sonucu olarak kaydedilmemelidir.

## 3. Snapshot ve root deneyi

VirtualBox host arayüzünde snapshot adını/zamanını doğrulayın veya yeni snapshot alın. Sonra root terminalinde:

```sh
printf 'snapshot_name=%s\nsnapshot_time=%s\n' 'DOGRULANAN-AD' 'DOGRULANAN-ZAMAN' | sudo tee /opt/makro-lab/kanit/root/snapshot.env >/dev/null
sudo chmod 0600 /opt/makro-lab/kanit/root/snapshot.env
sudo --preserve-env=DISPLAY,XAUTHORITY /home/kali/makro-lab-proje/scripts/run_root_experiment.sh
```

Root GUI erişimi reddedilirse yalnızca deney süresince `xhost +SI:localuser:root` kullanın ve deneyden hemen sonra `xhost -SI:localuser:root` ile geri alın. LibreOffice root çalışmayı reddederse hata çıktısı sonuç olarak korunmalıdır.

Grafik masaüstüne root erişimi vermeden eşdeğer izole izinli koşulu çalıştırmak için snapshot kaydından sonra şu başlatıcı kullanılabilir:

```sh
sudo /home/kali/makro-lab-proje/scripts/run_root_xvfb_experiment.sh
```
