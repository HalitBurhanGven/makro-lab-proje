# Kısa Deney Raporu

İlk deney tarihi: 2026-10-03
Root deney tarihi: 2026-10-09
Hazırlayan süreç: `kali` (UID 1000)

## Gözlenen ortam

- LibreOffice: 26.8.0.3
- oledump.py: 0.0.85
- UNO kullanan sistem Python’u: `/usr/bin/python3` 3.14.7
- Ayrıca `/home/kali/.local/bin/python3.12` altında Python 3.12.14 var; bu yorumlayıcı `uno` modülünü görmüyor.
- Codex araç oturumu `container-other` bildirdi ve grafik `DISPLAY` sunmadı. Bu, kullanıcının VM içinde doğruladığı `oracle` sonucunun yerine geçirilmedi.
- VirtualBox host API bilgisine Codex oturumundan erişilemedi. Root deneyi, kullanıcı tarafından doğrulanıp `snapshot.env` içine yazılan gerçek ad/zaman kaydını sıkı biçim denetiminden geçirerek kabul etti; bu kabul host API'sinden bağımsız bir ikinci doğrulama değildir.
- `/opt/makro-lab` kullanıcı tarafından sudo ile kuruldu; host izinleri sandbox dışında ayrıca doğrulandı.

## Gerçekten üretilen ODF belgeleri

| Belge | SHA-256 | Basic modülü | Otomatik olay |
|---|---|---:|---:|
| `kontrol-makrosuz.ods` | `86170cde3c682ee13edf7c34ae00567eba3105f60851bf61234b0bd46cf89a13` | Yok | Yok |
| `mesaj-manuel.ods` | `4551bd77ed9ac2258de357b8ed05c79346b18539fe69cb56953e2ea92325c1f5` | Var | Yok |
| `mesaj-acilista.ods` | `46eab377fc57694438e0db8df6e21075ac0dd1b5c865c0e02ef24b0e4118e69e` | Var | `dom:load` → `AcilistaMesaj` |
| `yetki-deneyi-acilista.ods` | `e1aa96ecf9ea1e2e265bf4166494c56089d426631d26c2760b33927f0f58f0fa` | Var | `dom:load` → `AcilistaYetkiDeneyi` |
| `yetki-deneyi-acilista-v3.ods` | `d8ca56e7aeae884fe89e79e7be672855266176ee1e49bd237c13ab2753ee1f5b` | Var | `dom:load` → `AcilistaYetkiDeneyi` |

Belgelerin tümü `file` tarafından OpenDocument Spreadsheet olarak tanındı ve `unzip -t` testini geçti. Basic kaynakları gerçek `Basic/Standard/Module1.xml` parçaları olarak gömülü.

## Mesaj makrosu ve otomatik tetik

İzole Xvfb ekranında, yalnızca test profiline özgü düşük güvenlik ayarı kullanıldı; günlük LibreOffice profili değiştirilmedi.

- `mesaj-manuel.ods`, açık `macro://./Standard.Module1.MesajiGoster` URI çağrısıyla çalıştırıldı ve `Makro Laboratuvari` başlıklı pencere gözlendi. Bu koşul UI üzerinden elle çalıştırma değildir ve öyle raporlanmamalıdır; yalnızca Basic yükleme/çalışma uyumluluğu kanıtıdır.
- `mesaj-acilista.ods` ek macro URI verilmeden açıldı. Aynı mesaj penceresinin görünmesi ve statik `dom:load` bağı, bu koşulda otomatik `OnLoad` tetiklenmesinin çalıştığını gösterdi.
- Pencere-ID ekran görüntüsü, pencere yöneticisi bulunmayan Xvfb’de yalnızca boş çerçeve yakaladı. Bu nedenle esas kanıt pencere başlığı, süreç durumu, sıfır stderr ve statik olay bağıdır.

## ODF ve VBA statik analizi

oledump.py her dört ODF için `Warning: no OLE file was found inside this ZIP container` verdi. Bu beklenen sonuçtur: LibreOffice Basic içeren ODF, Microsoft VBA/OLE belgesi değildir.

LibreOffice ile `yetki-deneyi-acilista.xlsm` adlı bir dışa aktarım adayı da oluşturuldu:

- SHA-256: `ec0a0b15a3b771d35250c1af11b31965261d2b86fd5cc9558d78e7bfabf97550`
- Paket ana çalışma kitabını `macroEnabled` olarak işaretliyor.
- Ancak `xl/vbaProject.bin` ve VBA ilişkisi yok.
- oledump.py OLE bulamadı; `M/m/!` işaretli hiçbir VBA modülü yok.

Sonuç: Bu `.xlsm` gerçek VBA makrolu belge değildir ve çalışma deneyinde kullanılmayacaktır. Gerçek VBA/OLE üretme ve Microsoft Office davranışını doğrulama bölümü Windows/Microsoft Office gerektiriyor.

## Yetki karşılaştırması

| Koşul | Beklenen | Gözlenen |
|---|---|---|
| Makrosuz kontrol | Hedef dosyası oluşmaz | `KONTROL-KALI-FINAL-20261003T150848Z`: UID 1000, hedef farkı yok |
| Makrolar engelli | Profil ayarıyla makro çalışmaz; yalnızca dosya yokluğu kanıt sayılmaz | `KALI-ENGELLI-V3-20261003T150853Z`: UID 1000, `DisableMacrosExecution=true`, seviye 3, hedef farkı yok |
| `kali` izinli | Kullanıcı alanına başarı, root alanına izin hatası | `KALI-IZINLI-V3-20261003T150752Z`: UID 1000; kullanıcı alanı başarılı; root alanı `ERR=57 Device I/O error`; iki sonuç ayrı kaydedildi |
| `root` izinli (izole Xvfb) | LibreOffice root çalışmayı kabul ederse iki hedefe başarı | `ROOT-IZINLI-V3-20261009T152555Z`: başlatıcı gerçek `soffice.bin` `/proc` UID alanlarının tümünü 0 doğruladı; kullanıcı ve root hedefleri başarılı |
| `root` izinli (görünür Calc) | Belge masaüstünde görünür; izole izinli profilde açılış makrosu iki hedefe yazar | `ROOT-GORUNUR-IZINLI-V3-20261009T163154Z`: Calc görünür açıldı; UID 0 ve iki hedef de başarılı |

Kali deneylerinde `--pidfile` ile bulunan gerçek `soffice.bin` süreçlerinin `/proc/<pid>/status` kayıtlarında gerçek/effective/saved/filesystem UID değerlerinin tamamı 1000 görüldü. İzinli otomatik koşul, günlük profil dışında oluşturulan izole seviye-0 test profiliyle çalıştırıldı; orta güvenlik profilindeki kullanıcı düğmesiyle izin verme deneyi ayrıca GUI’de yapılmalıdır.

v1, root hatasından sonra sonuç kaydına ulaşamadı. v2, açılmamış dosya numarasını kapatmaya çalışarak Basic çalışma zamanı hatası verdi. Bu başarısızlıklar kanıtlarıyla korundu; doğrulanmış belge v3’tür.

Root deneyinde günlük profil yerine root sahipliğinde, geçici ve izole LibreOffice profili kullanıldı. Başlatıcı çıktısı `uid0_verified=true`, `user_target_written=true` ve `root_target_written=true` verdi. Kullanıcı hedefindeki makro sonuç dosyası iki yazmayı da `true` kaydetti. Root kanıt dizini kasıtlı olarak `root:root 0700` kaldığından, ayrıntılı `/proc` kaydı ve root hedef dosyası `kali` hesabından doğrudan okunamaz; bu erişim ayrımı laboratuvar tasarımının bir parçasıdır.

Görünür GUI doğrulamasında önce orta güvenlikli tek kullanımlık profil denendi. `ROOT-GORUNUR-V3-20261009T162948Z` koşulunda Calc UID 0 ile açıldı fakat iki hedef de `false` kaldı; bu koşul makro çalışması olarak raporlanmadı. Ardından yalnızca deney profilinde güvenlik seviyesi 0 kullanıldı. `ROOT-GORUNUR-IZINLI-V3-20261009T163154Z` koşulunda belge gerçek Calc penceresinde açıkken otomatik `dom:load` makrosu iki hedefe de başarıyla yazdı. Günlük kullanıcı profili değiştirilmedi.

Bu sonuç bir yetki yükseltme göstermiyor. Aynı belge makrosu `kali` tarafından çalışan LibreOffice içinde UID 1000 izinleriyle, root tarafından çalışan LibreOffice içinde UID 0 izinleriyle hareket etti. Terminal UID'si tek başına kanıt kabul edilmedi; root sonucu başlatıcının yakaladığı gerçek `soffice.bin` `/proc/<pid>/status` kaydına dayanıyor.

## Son durum

Dört temel karşılaştırma tamamlandı: makrosuz kontrol, makroları engelli koşul, `kali` izinli koşul ve UID 0 root izinli koşul. Root koşulu hem izole Xvfb ekranında hem gerçek görünür Calc penceresinde doğrulandı. Gerçek UI menüsünden elle mesaj makrosu çalıştırma, otomatik açılış tetikinden ayrı tutulan isteğe bağlı pedagojik adımdır; CLI ile açık makro URI uyumluluğu ve gerçek `dom:load` otomatik tetiki ayrı ayrı doğrulandı.

## Araçların anlamı

oledump.py ve CyberChef statik/yardımcı analiz araçlarıdır. Belgeyi otomatik engellemez, çalıştırmayı güvenli hâle getirmez ve uç nokta korumasının yerini tutmaz.
