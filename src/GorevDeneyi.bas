Option Explicit

Const GOREV_KULLANICI_DIZINI = "/opt/makro-lab/hedef/kullanici-alani/"
Const GOREV_ROOT_DIZINI = "/opt/makro-lab/hedef/root-alani/"

Sub AcilistaZararsizGorev(oEvent)
    Dim sayfa As Object
    Dim kodluMesaj As String
    Dim gorevMesaji As String
    Dim deneyKimligi As String
    Dim rootBasarili As Boolean
    Dim kullaniciBasarili As Boolean
    Dim rootHatasi As String
    Dim kullaniciHatasi As String
    Dim sonucHatasi As String
    Dim yedekHatasi As String
    Dim makbuz As String

    sayfa = ThisComponent.Sheets.getByIndex(0)
    gorevMesaji = sayfa.getCellByPosition(1, 5).String
    kodluMesaj = sayfa.getCellByPosition(1, 6).String
    deneyKimligi = GuvenliGorevKimligi(Environ("MAKRO_LAB_DENEY_ID"))

    ' Gorunur ve zararsiz etki: yalnizca acik belgenin bir hucresini bellekte degistirir.
    sayfa.getCellByPosition(1, 7).String = "CALISTI: " & gorevMesaji

    makbuz = "MAKRO-LAB ZARARSIZ GOREV MAKBUZU" & Chr(10) & _
        "deney_kimligi=" & deneyKimligi & Chr(10) & _
        "gorev_base64=" & kodluMesaj & Chr(10) & _
        "gorev_mesaji=" & TekSatirGorev(gorevMesaji) & Chr(10) & _
        "aciklama=Bu metin sistem komutu degildir; belgeye onceden gomulmus izinli mesajdir." & Chr(10)

    rootBasarili = GorevKanitYaz( _
        GOREV_ROOT_DIZINI & deneyKimligi & "-gorev-makbuzu.txt", _
        makbuz & "hedef=root-alani" & Chr(10), rootHatasi)

    kullaniciBasarili = GorevKanitYaz( _
        GOREV_KULLANICI_DIZINI & deneyKimligi & "-gorev-makbuzu.txt", _
        makbuz & "hedef=kullanici-alani" & Chr(10), kullaniciHatasi)

    makbuz = makbuz & _
        "kullanici_alani_basarili=" & LCase(CStr(kullaniciBasarili)) & Chr(10) & _
        "kullanici_alani_hata=" & TekSatirGorev(kullaniciHatasi) & Chr(10) & _
        "root_alani_basarili=" & LCase(CStr(rootBasarili)) & Chr(10) & _
        "root_alani_hata=" & TekSatirGorev(rootHatasi) & Chr(10)

    If Not GorevKanitYaz(GOREV_KULLANICI_DIZINI & deneyKimligi & "-gorev-sonucu.txt", _
        makbuz, sonucHatasi) Then
        Call GorevKanitYaz(GOREV_ROOT_DIZINI & deneyKimligi & "-gorev-sonucu.txt", _
            makbuz & "sonuc_kaydi_ilk_hata=" & TekSatirGorev(sonucHatasi) & Chr(10), _
            yedekHatasi)
    End If
End Sub

Function GorevKanitYaz(dosyaYolu As String, icerik As String, ByRef hataMetni As String) As Boolean
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
        GorevKanitYaz = False
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
    GorevKanitYaz = True
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
    GorevKanitYaz = False
End Function

Function GuvenliGorevKimligi(hamDeger As String) As String
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
    If sonuc = "" Then sonuc = "LO-GOREV-" & Format(Now, "YYYYMMDD-HHMMSS")
    GuvenliGorevKimligi = sonuc
End Function

Function TekSatirGorev(deger As String) As String
    TekSatirGorev = Replace(Replace(deger, Chr(13), " "), Chr(10), " ")
End Function
