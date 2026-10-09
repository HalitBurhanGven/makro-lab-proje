# Snapshot ve GUI kapısı

Root ile LibreOffice açılmadan önce VirtualBox host tarafında:

1. VM’nin mevcut snapshot adını ve zamanını doğrulayın veya `makro-lab-oncesi-YYYYMMDD-HHMM` adlı yeni snapshot alın.
2. VM içindeki root terminalinde `/opt/makro-lab/kanit/root/snapshot.env` dosyasına şu iki satırı yazın:

   `snapshot_name=...`

   `snapshot_time=...`

3. Root deneyini VM masaüstündeki grafik oturumundan başlatın. Önce mevcut `DISPLAY`/`XAUTHORITY` aktarımı denenmelidir. X sunucusu reddederse yalnızca deney süresince `xhost +SI:localuser:root` verin ve ardından `xhost -SI:localuser:root` ile geri alın.

VirtualBox algılanması tek başına snapshot kanıtı değildir. `run_root_experiment.sh`, snapshot kaydı olmadan çalışmaz.
