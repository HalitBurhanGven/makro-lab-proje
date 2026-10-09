Option Explicit

Const KULLANICI_DIZINI = "/opt/makro-lab/hedef/kullanici-alani/"
Const ROOT_DIZINI = "/opt/makro-lab/hedef/root-alani/"

Sub ElleYetkiDeneyi
    YetkiDeneyiniCalistir
End Sub

Sub AcilistaYetkiDeneyi(oEvent)
    YetkiDeneyiniCalistir
End Sub

Sub YetkiDeneyiniCalistir
    Dim deneyKimligi As String
    Dim kullaniciHatasi As String
    Dim rootHatasi As String
    Dim sonucHatasi As String
    Dim yedekHatasi As String
    Dim kullaniciBasarili As Boolean
    Dim rootBasarili As Boolean
    Dim sonucMetni As String

    deneyKimligi = GuvenliDeneyKimligi(Environ("MAKRO_LAB_DENEY_ID"))

    ' Bilerek once yazilamaz olmasi beklenen root hedefi denenir.
    ' Bu hatadan sonra kullanici hedefinin yazilmasi, iki denemenin bagimsiz oldugunu gosterir.
    rootBasarili = KanitYaz( _
        ROOT_DIZINI & deneyKimligi & "-root-hedefi.txt", _
        HedefMetni(deneyKimligi, "root-alani"), _
        rootHatasi)

    kullaniciBasarili = KanitYaz( _
        KULLANICI_DIZINI & deneyKimligi & "-kullanici-hedefi.txt", _
        HedefMetni(deneyKimligi, "kullanici-alani"), _
        kullaniciHatasi)

    sonucMetni = "deney_kimligi=" & deneyKimligi & Chr(10) & _
        "belge_makrosu=LibreOffice Basic" & Chr(10) & _
        "kullanici_alani_basarili=" & LCase(CStr(kullaniciBasarili)) & Chr(10) & _
        "kullanici_alani_hata=" & TekSatir(kullaniciHatasi) & Chr(10) & _
        "root_alani_basarili=" & LCase(CStr(rootBasarili)) & Chr(10) & _
        "root_alani_hata=" & TekSatir(rootHatasi) & Chr(10)

    If Not KanitYaz(KULLANICI_DIZINI & deneyKimligi & "-sonuclar.txt", sonucMetni, sonucHatasi) Then
        Call KanitYaz(ROOT_DIZINI & deneyKimligi & "-sonuclar.txt", _
            sonucMetni & "sonuc_kaydi_ilk_hata=" & TekSatir(sonucHatasi) & Chr(10), _
            yedekHatasi)
    End If
End Sub

Function HedefMetni(deneyKimligi As String, hedef As String) As String
    HedefMetni = "MAKRO-LAB ZARARSIZ KANIT" & Chr(10) & _
        "deney_kimligi=" & deneyKimligi & Chr(10) & _
        "hedef=" & hedef & Chr(10) & _
        "aciklama=Bu dosya yalnizca mevcut uygulama yetkisini gostermek icin olusturuldu." & Chr(10)
End Function

Function KanitYaz(dosyaYolu As String, icerik As String, ByRef hataMetni As String) As Boolean
    Dim dosyaNo As Integer
    Dim dosyaAcik As Boolean
    Dim hataKodu As Long
    Dim hataAciklamasi As String
    dosyaNo = 0
    dosyaAcik = False
    hataMetni = ""
    Err = 0
    On Local Error GoTo HataYakala

    If Dir(dosyaYolu) <> "" Then
        hataMetni = "MEVCUT_DOSYA_EZILMEDI"
        KanitYaz = False
        Exit Function
    End If

    dosyaNo = FreeFile
    Open dosyaYolu For Output Access Write As #dosyaNo
    dosyaAcik = True
    Print #dosyaNo, icerik
    Close #dosyaNo
    dosyaAcik = False
    dosyaNo = 0
    On Local Error GoTo 0
    Err = 0
    KanitYaz = True
    Exit Function

HataYakala:
    hataKodu = Err
    hataAciklamasi = Error$
    On Local Error Resume Next
    If dosyaAcik Then Close #dosyaNo
    dosyaAcik = False
    dosyaNo = 0
    On Local Error GoTo 0
    Err = 0
    hataMetni = "ERR=" & CStr(hataKodu) & ";DESC=" & hataAciklamasi
    KanitYaz = False
    Exit Function
End Function

Function GuvenliDeneyKimligi(hamDeger As String) As String
    Dim i As Integer
    Dim karakter As String
    Dim sonuc As String
    Dim izinli As String

    izinli = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    sonuc = ""
    hamDeger = Left(hamDeger, 64)

    For i = 1 To Len(hamDeger)
        karakter = Mid(hamDeger, i, 1)
        If InStr(izinli, karakter) > 0 Then sonuc = sonuc & karakter
    Next i

    If sonuc = "" Then sonuc = "LO-" & Format(Now, "YYYYMMDD-HHMMSS")
    GuvenliDeneyKimligi = sonuc
End Function

Function TekSatir(deger As String) As String
    TekSatir = Replace(Replace(deger, Chr(13), " "), Chr(10), " ")
End Function
