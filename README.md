# pve-lxc-upgrade

**Release-Upgrade** ist ein Bash-Skript für die **Proxmox-VE-Host-Shell**. Es prüft alle **LXC-Container** (Debian und Ubuntu) auf Updates und aktualisiert sie nach Bestätigung. Das gilt für normale Paket-Updates und für **Distributions-Upgrades** wie Debian 12 → 13 oder Ubuntu 22.04 → 24.04.

Alle Einstellungen setzt du in einem grafischen Menü (whiptail). Erst wenn du dort **Starten** wählst, passiert etwas.

```
┌──────────── Release-Upgrade 1.3.0 – proxmox ─────────────┐
│ 1  Modus ................... prüfen + aktualisieren      │
│ 2  Nur diese Container ..... alle                        │
│ 3  Container auslassen ..... keine                       │
│ 4  Kein Release-Upgrade .... keine                       │
│ 5  Gestoppte einbeziehen ... nein                        │
│ U  Skript aktualisieren (installiert: 1.3.0)             │
│ H  Hilfe zu den Einstellungen                            │
│ S  >>> Starten <<<                                       │
│          <Auswählen>              <Abbrechen>            │
└──────────────────────────────────────────────────────────┘
```

## Funktionen

- **Übersicht** aller Container: installierte Version, Zahl der verfügbaren Paket-Updates, verfügbares neues Release
- **Paket-Updates** (`apt full-upgrade`) für alle Container oder eine Auswahl
- **Release-Upgrades**, für jeden Container einzeln bestätigt:
  - **Debian:** immer nur eine Stufe pro Lauf, z. B. 12 → 13. Vor dem Umstellen sichert das Skript die Paketquellen. Bietet eine Fremdquelle (z. B. das Docker-Repo) das neue Release noch nicht an, setzt es die Quellen automatisch zurück, und am Container ändert sich nichts.
  - **Ubuntu:** über das offizielle `do-release-upgrade`, entsprechend der Einstellung `Prompt=` im Container (LTS oder normal)
  - Danach startet der Container neu, und das Skript prüft, ob die neue Version läuft
- **Dienst-Prüfung vorher/nachher:** laufende systemd-Dienste, Docker-Container und offene TCP-Ports werden verglichen. Fehlende Dienste oder Container kannst du direkt neu starten lassen.
- **Konfigurationsdateien:** Abfragen wie „deine Version behalten oder ersetzen?“ beantwortet das Skript automatisch mit „behalten“. Die neue Paketversion liegt dann als `*.dpkg-dist` daneben.
- **Proxmox Backup Server im Container:** Das Skript erkennt ihn, warnt extra, führt `pbs3to4 --full` aus und will eine ausdrückliche Bestätigung
- **Letztes Backup** des Containers wird vor jedem Release-Upgrade angezeigt
- **Selbstinstallation** beim ersten Start und **„Skript aktualisieren“** im Menü, mit Anzeige von Changelog und Änderungen
- **Logdatei** für jeden Lauf unter `/var/log/release-upgrade/`

**Was das Skript bewusst nicht macht:** Backups erstellen, Docker-Images aktualisieren und VMs bearbeiten.

## Voraussetzungen

- Proxmox VE (getestet mit 9.x) und Ausführung als `root` auf dem Host
- LXC-Container mit Debian oder Ubuntu, andere Systeme werden übersprungen
- Internetzugang vom Host und von den Containern aus
- `whiptail`, `curl`, `diff` usw. installiert das Skript bei Bedarf selbst

## Installation

In der Shell des Proxmox-Hosts:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Schoti9807/pve-lxc-upgrade/main/Release-Upgrade)"
```

Das Skript fragt, ob es sich nach `/usr/local/sbin/Release-Upgrade` installieren soll. Danach startest du es jederzeit mit:

```bash
Release-Upgrade
```

## Aktualisieren

Im Menü **U – Skript aktualisieren** wählen. Das Skript lädt die neueste Version, prüft sie, zeigt den Changelog und die Änderungen an und installiert sie nach deiner Bestätigung. Danach startet das Menü mit der neuen Version neu.

Alternativ kannst du den Installationsbefehl oben einfach noch einmal ausführen.

## Wichtige Hinweise

> ⚠️ **Ein Release-Upgrade lässt sich nicht einfach rückgängig machen.** Mach vorher ein Backup der Container, zum Beispiel mit dem Proxmox Backup Server oder `vzdump`.

- **Starte das Skript in `tmux` oder `screen`,** wenn du per SSH verbunden bist. Wird ein VPN- oder Reverse-Proxy-Container aktualisiert, über den deine Verbindung läuft, kann die Sitzung abbrechen. Ein laufendes Upgrade würde dann mittendrin abbrechen.
- **Container mit Herstellersoftware,** die nur bestimmte Releases unterstützt (z. B. UniFi OS Server), solltest du unter **„Kein Release-Upgrade“** anhaken. Paket-Updates bekommen sie trotzdem. Alternativ trägst du sie dauerhaft oben im Skript bei `RELEASE_EXCLUDE="…"` ein.
- **Nach einem Ubuntu-Release-Upgrade** deaktiviert `do-release-upgrade` Fremdquellen wie das Docker-Repo. Das Skript zeigt sie an, wieder aktivieren musst du sie selbst.
- **Der Proxmox-Host muss das neue Release unterstützen.** Neue Debian- oder Ubuntu-Versionen brauchen in LXC eine ausreichend aktuelle Proxmox-Version.

## Einstellungen im Skript

Oben im Skript lassen sich feste Vorgaben setzen, die im Menü vorbelegt sind:

| Variable | Bedeutung | Standard |
|---|---|---|
| `EXCLUDE` | Container immer auslassen, z. B. `"106"` | leer |
| `RELEASE_EXCLUDE` | Container nur mit Paket-Updates, ohne Release-Upgrade | leer |
| `BOOT_TIMEOUT` | Sekunden, die nach einem Neustart auf den Container gewartet wird | 180 |
| `SERVICE_WAIT` | Sekunden, die nach einem Update auf fehlende Dienste gewartet wird | 90 |
| `SERVICE_IGNORE` | kurzlebige Dienste, die beim Vergleich ignoriert werden (Regex) | apt-daily, man-db, … |

Hinweis: „Skript aktualisieren“ überschreibt diese Werte mit der neuen Version. Notiere dir deine Anpassungen also vorher.

## Deinstallation

```bash
rm /usr/local/sbin/Release-Upgrade
rm -r /var/log/release-upgrade   # optional: Logs löschen
```

## Haftungsausschluss

Die Nutzung erfolgt auf eigene Verantwortung. Das Skript wurde sorgfältig erstellt, kann aber nicht jede Konstellation abdecken. Mach vor Release-Upgrades immer ein Backup.

## Lizenz

[MIT](LICENSE) © Schoti9807
