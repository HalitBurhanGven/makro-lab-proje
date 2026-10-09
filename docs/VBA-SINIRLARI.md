# VBA/OLE sınırı

LibreOffice Basic içeren ODF belgesi gerçek Microsoft VBA projesi değildir. ODF, ZIP/XML yapısı ve `Basic/` kitaplığı üzerinden incelenir.

Bir `.xlsm` dosyası yalnızca uzantısı nedeniyle makrolu kabul edilmez. Bu laboratuvarda gerçek VBA kabul ölçütleri şunlardır:

1. OOXML paketinde `xl/vbaProject.bin` bulunmalıdır.
2. Bu parça geçerli OLE/CFBF olmalıdır.
3. `oledump.py` çıktısında `M`, `m` veya `!` işaretli VBA modül akışları bulunmalıdır.
4. Bütün ilgili akışlar `oledump.py -s <kimlik> -v` ile çıkarılabilmelidir.

LibreOffice’in VBA uyumluluğu sınırlıdır ve LibreOffice Basic kodunu güvenilir biçimde yeni bir VBA projesine dönüştürdüğü varsayılmayacaktır. Bu koşullar sağlanmazsa gerçek VBA belgesi hazırlamak ve Microsoft Office davranışını sınamak için izole bir Windows/Microsoft Office ortamı gerekir.
