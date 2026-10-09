# İki Kullanıcılı LibreOffice Makro Laboratuvarı

Bu proje tek bir soruyu güvenli biçimde yanıtlar:

> Bir kullanıcı tarafından hazırlanan makrolu belge başka bir kullanıcı tarafından açılırsa, makro hangi kullanıcının yetkileriyle çalışır?

Kısa cevap: **Makro, belgeyi açan LibreOffice sürecinin yetkileriyle çalışır.**

Bu laboratuvarda `kali` belgeyi hazırlayan rolündedir. `root` belgeyi alan ve açan rolündedir. Belgedeki kod yalnızca iki laboratuvar dizinine metin makbuzu yazabilir; shell, ağ bağlantısı, indirme, veri toplama veya kalıcılık içermez.

## Senaryo

```text
kali belgeye zararsız bir mesaj ve makro gömer
                    │
                    ▼
        belge root'un gelen alanına teslim edilir
                    │
                    ▼
       root belgeyi LibreOffice Calc ile açar
                    │
                    ▼
       OnLoad makrosu LibreOffice içinde çalışır
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
 kullanıcı alanına       root alanına
 makbuz yazmayı dener    makbuz yazmayı dener
```

Makro `kali` olarak çalışırsa kullanıcı alanına yazabilir fakat root alanına yazamaz. Aynı makro root tarafından çalışan LibreOffice içinde çalışırsa iki alana da yazabilir.

Bu sonuç bir yetki yükseltme değildir. LibreOffice zaten hangi UID ile başlatılmışsa makro da o sürecin mevcut yetkilerini kullanır.

## Kali bu deneyde ne elde eder?

Kali ek bir hesap, parola, root shell veya uzaktan erişim elde etmez. Kali yalnızca:

1. Belgeye gömülecek zararsız mesajı önceden seçer.
2. Belgenin root tarafından açılmasından sonra kullanıcı alanındaki çalıştırma makbuzunu okuyabilir.
3. Kendi hazırladığı kodun alıcı uygulamasının yetkileriyle çalıştığını gözlemler.

Bu proje bir arka kapı veya komuta-kontrol sistemi değildir. Belge teslim edildikten sonra Kali root'a canlı komut gönderemez.

## Güvenlik sınırı

Makro yalnızca şu dizinlere benzersiz kimlikli metinler yazmayı dener:

```text
/opt/makro-lab/hedef/kullanici-alani/
/opt/makro-lab/hedef/root-alani/
```

Projede şunlar bulunmaz:

- sistem komutu veya shell çalıştırma;
- ters bağlantı veya başka bir ağ iletişimi;
- program indirme;
- parola ya da dosya toplama;
- kalıcılık;
- laboratuvarın iki hedefi dışında makro tarafından dosya yazılması.

Root deneyi yalnızca izole bir sanal makinede ve doğrulanmış snapshot sonrasında yapılmalıdır. Günlük LibreOffice profili kullanılmaz; her izinli deney ayrı bir profil ile başlatılır.

## Dizinler

| Yol | Görev | Sahiplik/izin |
|---|---|---|
| `/home/kali/makro-lab-proje/` | Kaynak kod, betikler ve belgeler | `kali` |
| `/opt/makro-lab/hazirlik/` | Hazırlayanın çalışma kopyaları | `kali`, `0750` |
| `/opt/makro-lab/gelen/` | Alıcıya teslim edilen belgeler | belgeler `root:root 0444` |
| `/opt/makro-lab/hedef/kullanici-alani/` | Kali'nin yazabildiği kanıt hedefi | `kali`, `0700` |
| `/opt/makro-lab/hedef/root-alani/` | Yalnızca root'un yazabildiği hedef | `root`, `0700` |
| `/opt/makro-lab/kanit/` | Süreç UID ve deney kayıtları | kullanıcıya göre ayrılmış |
| `/opt/makro-lab/analiz/` | Statik analiz çıktıları | `kali`, `0750` |
| `/opt/makro-lab/rapor/` | Deney raporları | `kali`, `0750` |

## Gereksinimler

- Kali Linux sanal makinesi
- LibreOffice Calc
- Python ve LibreOffice UNO modülü
- `oledump.py`
- `unzip`, `file` ve standart GNU araçları
- Görünür deney için çalışan Xorg/LightDM masaüstü
- Root deneyi öncesinde VirtualBox snapshot'ı

Proje, `/usr/bin/libreoffice` ve `/usr/local/bin/oledump.py` yollarını kullanır.

## İlk kurulum

Belgeleri Kali hesabında üretin:

```bash
/usr/bin/python3 /home/kali/makro-lab-proje/scripts/build_documents.py --project /home/kali/makro-lab-proje
```

Laboratuvar dizinlerini bir kez kurun:

```bash
sudo /home/kali/makro-lab-proje/scripts/install_lab.sh
```

İzinleri doğrulayın:

```bash
/home/kali/makro-lab-proje/scripts/verify_lab.sh
```

Kurulum betiği mevcut `/opt/makro-lab` alanını otomatik olarak ezmez.

## Kontrollü görev deneyi

Bu deney Kali'nin seçtiği zararsız mesajı belgeye gömer. Mesaj çalıştırılacak bir sistem komutu değildir.

### 1. Kali mesajı seçer ve belgeyi üretir

Kali terminalinde:

```bash
/usr/bin/python3 /home/kali/makro-lab-proje/scripts/build_benign_task_document.py --message 'KALI-TARAFINDAN-SECILEN-GOREV'
```

Oluşan belge:

```text
/home/kali/makro-lab-proje/dist/gorev-deneyi-acilista-v4.ods
```

Betik mesajın Base64 karşılığını da belgeye yerleştirir. Çözülen metin hiçbir zaman sistem komutu olarak çalıştırılmaz.

### 2. Belge alıcı alanına teslim edilir

Root terminalinde:

```bash
/home/kali/makro-lab-proje/scripts/install_benign_task_document.sh
```

Alıcı kopyası `root:root 0444` olur. Kali bu kopyayı okuyabilir fakat değiştiremez.

### 3. Root belgeyi görünür Calc penceresinde açar

LightDM/Xorg kullanılan doğrulanmış ortamda, root terminalinde:

```bash
env DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 /home/kali/makro-lab-proje/scripts/run_root_visible_benign_task.sh
```

Calc içinde şu alanlar görünür:

- `GOREV_MESAJI`: Kali'nin seçtiği metin;
- `GOREV_BASE64`: aynı metnin Base64 karşılığı;
- `GOREV_DURUMU`: makro çalışınca `CALISTI: ...` olur.

LibreOffice kapatıldığında başlatıcı gerçek `soffice.bin` UID'sini ve iki yazma sonucunu bildirir:

```text
uid0_verified=true
user_target_written=true
root_target_written=true
```

### 4. Kali çalıştırma makbuzunu okur

Kali, deney kimliğini kullanarak şu dosyayı okur:

```text
/opt/makro-lab/hedef/kullanici-alani/<DENEY-KIMLIGI>-gorev-sonucu.txt
```

Makbuz; seçilmiş mesajı, Base64 değerini ve iki hedefteki başarı/hata sonuçlarını içerir.

## Karşılaştırma deneyleri

Laboratuvar dört koşulu ayırır:

| Koşul | Beklenen sonuç |
|---|---|
| Makrosuz kontrol | Hedeflerde değişiklik yok |
| Makrolar engelli | Profil makroyu engeller; hedeflerde değişiklik yok |
| Kali/UID 1000, makro izinli | Kullanıcı alanı başarılı, root alanı izin hatalı |
| Root/UID 0, makro izinli | İki hedef de başarılı |

Dosya oluşmaması tek başına makronun engellendiğini kanıtlamaz. Profil ayarı, LibreOffice stderr çıktısı, gerçek süreç UID'si ve hedeflerin önce/sonra farkı birlikte değerlendirilir.

## Statik analiz: belgeyi çalıştırmadan inceleme

Bu projedeki gerçek makro biçimi LibreOffice Basic içeren ODF'dir. ODF bir ZIP/XML paketidir.

```bash
/home/kali/makro-lab-proje/scripts/analyze_odf.sh /opt/makro-lab/gelen/yetki-deneyi-acilista-v3.ods /opt/makro-lab/analiz/yetki-odf
```

İncelenecek temel parçalar:

| Paket parçası | Anlamı |
|---|---|
| `Basic/Standard/Module1.xml` | LibreOffice Basic makro kaynağı |
| `content.xml` | `dom:load` olayının makroya bağlantısı |
| `META-INF/manifest.xml` | Paket içeriği ve dosya türleri |

### oledump.py

`oledump.py` OLE/VBA akışları için tasarlanmıştır. ODF belgesinde `no OLE file was found` sonucu beklenir; bu hata değil, dosya biçiminin doğru tanımlanmasıdır.

Gerçek VBA içeren bir dosyada `analyze_vba.sh`, oledump listesindeki `M`, `m` ve `!` işaretli bütün modülleri seçerek çıkarır. LibreOffice'in `.xlsm` uzantılı çıktı üretmesi tek başına gerçek `vbaProject.bin` bulunduğunu kanıtlamaz.

### CyberChef

`cyberchef/tarif.json` yalnızca zararsız Base64 mesajını çözer. CyberChef makroyu çalıştırmaz, engellemez veya belgeyi güvenli hâle getirmez.

## Doğrulanan örnek sonuç

Görünür kontrollü görev deneyi:

```text
ROOT-GORUNUR-GOREV-V4-20261009T171135Z
uid0_verified=true
user_target_written=true
root_target_written=true
```

Bu sonuç yalnızca şunu kanıtlar: Kali'nin belgeye önceden gömdüğü zararsız kod, root tarafından çalıştırılan LibreOffice sürecinde UID 0 yetkileriyle çalışmıştır.

## Proje dosyaları

- `src/`: LibreOffice Basic kaynakları
- `scripts/`: üretim, kurulum, çalıştırma ve analiz betikleri
- `profiles/`: izole LibreOffice güvenlik profilleri
- `cyberchef/`: Base64 girdi ve tarif dosyaları
- `docs/`: deney raporu, snapshot yönergesi ve VBA sınırları
- `dist/`: üretilmiş örnek ODF belgeleri

## Sınırlar

- Bu proje gerçek Microsoft Excel/VBA yürütme laboratuvarı değildir.
- Gerçek VBA davranışını doğrulamak için Windows ve Microsoft Office gerekir.
- `root` rolü yalnızca yetki farkını görünür kılmak için kullanılır; günlük kullanımda ofis uygulamaları root olarak çalıştırılmamalıdır.
- oledump.py ve CyberChef analiz araçlarıdır; otomatik koruma sağlamaz.
