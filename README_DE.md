<p align="center">
  <img src="docs/assets/banner.svg" alt="CatCore UpdateGuard" width="100%">
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>Deutsch</strong> · <a href="README_ZH.md">中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Android-14–16-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android 14–16">
  <img src="https://img.shields.io/badge/Termux-erforderlich-111827?style=for-the-badge&logo=gnubash&logoColor=white" alt="Termux erforderlich">
  <img src="https://img.shields.io/badge/Zugriff-Root%20%7C%20ADB%20%7C%20Shizuku-F59E42?style=for-the-badge" alt="Root, ADB oder Shizuku">
</p>

<p align="center"><strong>Blockiere unerwünschte Android-Update-Komponenten aus Termux – mit Root, ADB oder Shizuku.</strong></p>

CatCore UpdateGuard ist ein mehrsprachiges Termux-Toolkit zur Steuerung von OTA-, Google- und Hersteller-Update-Komponenten auf Paket-/Komponentenebene. Du kannst für jede Berechtigungsstufe eine andere Methode verwenden: **ADB, Shizuku oder Root**—je nachdem, was auf deinem Gerät verfügbar ist.

Das ist besonders für moderne **TempRoot-Verfahren** relevant: Ein unerwartetes OTA kann temporären Root entfernen oder updatebedingte Boot-/Security-Probleme verursachen. UpdateGuard hilft, versehentliche Updates zu verhindern, bis du selbst entscheidest, wann und wie aktualisiert wird.

> UpdateGuard verändert weder `/system` noch `/vendor`, Boot oder `vbmeta`. Android-Firmwares unterscheiden sich; prüfe erkannte Pakete vor dem Anwenden. Blockierte Updates bedeuten außerdem, dass wichtige Sicherheitsupdates später bewusst manuell installiert werden müssen.

## Installation

1. Installiere [Termux über das offizielle Projekt](https://github.com/termux/termux-app#installation). Mische Termux und Plugins nicht aus unterschiedlichen Quellen.
2. Lade [`CCUpdateGuard.sh`](CCUpdateGuard.sh) in den **Download**-Ordner deines Smartphones.
3. Öffne Termux und führe aus:

```bash
pkg update
pkg install bash
termux-setup-storage
cp ~/storage/downloads/CCUpdateGuard.sh ~/
chmod +x ~/CCUpdateGuard.sh
```

## Start mit Root

Nutze eine passende [Android-Root-Anleitung](https://github.com/awesome-android-root/awesome-android-root/blob/main/docs%2Frooting-guides%2Findex.md) für dein Gerät. Erteile **Termux** in deinem Superuser-Manager (zum Beispiel Magisk, KernelSU oder APatch) die `su`-Berechtigung.

Löse die Berechtigungsabfrage aus und prüfe Root:

```bash
su -c id
```

Starte danach UpdateGuard und wähle **Root / su**:

```bash
bash ~/CCUpdateGuard.sh
```

## Start mit ADB

Aktiviere **Entwickleroptionen** und **Drahtloses Debugging** mithilfe der offiziellen [Android-Anleitung für ADB über WLAN](https://developer.android.com/tools/adb#connect-to-a-device-over-wi-fi). Lasse die Seite „Drahtloses Debugging“ und Termux möglichst im Splitscreen geöffnet.

Installiere ADB in Termux, kopple mit der von Android angezeigten Pairing-Adresse und dem Pairing-Port und verbinde dich danach mit der separaten Debugging-Adresse und dem Debugging-Port:

```bash
pkg install android-tools
adb pair IP_ADRESSE:PAIRING_PORT
adb connect IP_ADRESSE:DEBUG_PORT
adb devices
bash ~/CCUpdateGuard.sh
```

Wähle in UpdateGuard **ADB**. Das Gerät muss bei `adb devices` als `device` erscheinen.

## Start mit Shizuku

Installiere [Shizuku](https://github.com/RikkaApps/Shizuku) und starte es anhand der offiziellen [Shizuku-Einrichtung](https://shizuku.rikka.app/guide/setup/). Öffne in Shizuku **Use Shizuku in terminal apps**, exportiere die `rish`-Dateien für Termux und erlaube/aktiviere Termux bei der Shizuku-Abfrage.

Lege `rish` und `rish_shizuku.dex` so ab, dass Termux sie findet (zum Beispiel unter `$PREFIX/bin`), und mache `rish` ausführbar:

```bash
cp /pfad/zu/exportiertem/rish "$PREFIX/bin/rish"
cp /pfad/zu/exportiertem/rish_shizuku.dex "$PREFIX/bin/rish_shizuku.dex"
chmod +x "$PREFIX/bin/rish"
rish -c id
bash ~/CCUpdateGuard.sh
```

Wähle in UpdateGuard **Shizuku / rish**.

## Später erneut starten

```bash
bash ~/CCUpdateGuard.sh
```

Die Oberfläche nutzt abhängig von Android-/Termux-Sprache automatisch **Englisch, Deutsch oder Chinesisch**. Der gespeicherte Zustand liegt unter `~/.catcore-updateguard`; Reports und Logs werden bei vorhandenem Speicherzugriff unter `Download/CatCore-UpdateGuard` abgelegt.

### Root-only User Update Service Remover

Die letzte Menüoption ist bewusst mit **[DANGEROUS]** markiert. Sie zeigt updaterähnliche Systempakete und kann nur deine ausgewählten Pakete mit `pm uninstall --user` aus dem **aktuellen Android-Benutzerprofil** entfernen; die APKs auf der Systempartition werden niemals gelöscht. Vor jeder Entfernung verlangt UpdateGuard zuerst `Y`, danach das sprachabhängige Bestätigungswort und anschließend eine separate Bestätigung der roten Warnung. APK-Kopien und eine Paketliste werden unter `Dokumente/BackupsOSU/<Zeitstempel>` gesichert. **Reverse Select**, **Reverse all** und **Reverse + Hard Broken Checker** installieren diese Pakete mit `install-existing` wieder für den ursprünglichen Benutzer.

## Wichtiger TempRoot-Hinweis

- Deaktivierte Paketstatus können nach einem Neustart oder nach Verlust von TempRoot aktiv bleiben.
- Ein gestoppter `update_engine`-Prozess ist nur für den aktuellen Boot gestoppt.
- Zum späteren Wiederherstellen brauchst du erneut einen Berechtigungsweg: Root, verbundenes ADB oder funktionierendes Shizuku.
- Lösche `~/.catcore-updateguard` nicht, solange Schutz aktiv ist; dort liegt der Status für die Wiederherstellung.

## Haftungsausschluss

Die Nutzung von CatCore UpdateGuard erfolgt auf eigene Gefahr. Es wird keine Haftung für fehlgeschlagene Updates, ausbleibende Sicherheitspatches, App-/Geräteinstabilität, Zugriffsverlust oder sonstige Schäden übernommen. Das Blockieren von Update-Komponenten über ADB ist normalerweise eine vergleichsweise sichere und umkehrbare Methode auf Benutzerebene, aber nicht völlig risikofrei—und während Updates blockiert sind, werden wichtige Android-Sicherheitsupdates nicht automatisch installiert. Prüfe jedes ausgewählte Paket und hebe den Schutz vor einem beabsichtigten Update wieder auf.

## Release

Lade den aktuellen [`v1.0.0-Release`](https://github.com/ctrl-mietze/CatCore-UpdateGuard/releases/tag/v1.0.0) mit dem direkt ausführbaren Asset `CCUpdateGuard.sh` und den automatisch erzeugten GitHub-Source-Archiven herunter. Der neueste Source bleibt zusätzlich direkt im `main`-Branch verfügbar.

---

<p align="center">
  <strong>CatCore UpdateGuard</strong><br>
  Wähle deine Berechtigung. Kontrolliere deine Updates.
</p>
