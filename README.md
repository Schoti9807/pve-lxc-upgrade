# pve-lxc-upgrade

**Release-Upgrade** ist ein Bash-Skript für die **Proxmox-VE-Host-Shell**. Es prüft alle **LXC-Container** (Debian und Ubuntu) auf Updates und aktualisiert sie nach Bestätigung. Das gilt für normale Paket-Updates und für **Distributions-Upgrades** wie Debian 12 → 13 oder Ubuntu 22.04 → 24.04.

Alle Einstellungen setzt du in einem grafischen Menü (whiptail). Erst wenn du dort **Starten** wählst, passiert etwas.

```
┌──────────── Release-Upgrade 1.4.2 – proxmox ─────────────┐
│ 1  Modus ................... prüfen + aktualisieren      │
│ 2  Nur diese Container ..... alle                        │
│ 3  Container auslassen ..... keine                       │
│ 4  Kein Release-Upgrade .... keine                       │
│ 5  Gestoppte einbeziehen ... nein                        │
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
- **Immer aktuell:** Das Skript wird bei jedem Start direkt von GitHub geladen und ausgeführt, ein eigenes Update ist nicht nötig
- **Logdatei** für jeden Lauf unter `/var/log/release-upgrade/`

**Was das Skript bewusst nicht macht:** Backups erstellen, Docker-Images aktualisieren und VMs bearbeiten.

## Voraussetzungen

- Proxmox VE (getestet mit 9.x) und Ausführung als `root` auf dem Host
- LXC-Container mit Debian oder Ubuntu, andere Systeme werden übersprungen
- Internetzugang vom Host und von den Containern aus
- `whiptail`, `curl` usw. installiert das Skript bei Bedarf selbst

## Start

Das Skript wird immer direkt von GitHub geholt und ausgeführt. In der Shell des Proxmox-Hosts:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Schoti9807/pve-lxc-upgrade/main/Release-Upgrade)"
```

Das ist der einzige Weg, das Skript zu starten. Es wird nichts lokal installiert, du arbeitest also immer mit dem neuesten Stand. Ohne Internetverbindung startet das Skript nicht.

### Umstieg von Version 1.4.0 oder älter

Liegt unter `/usr/local/sbin/Release-Upgrade` noch ein Starter oder eine Kopie des Skripts, weist das Skript beim Start darauf hin. Die Datei wird nicht mehr gebraucht und lässt sich so entfernen:

```bash
rm /usr/local/sbin/Release-Upgrade
```

## Wichtige Hinweise

> ⚠️ **Ein Release-Upgrade lässt sich nicht einfach rückgängig machen.** Mach vorher ein Backup der Container, zum Beispiel mit dem Proxmox Backup Server oder `vzdump`.

- **Starte das Skript in `tmux` oder `screen`,** wenn du per SSH verbunden bist. Wird ein VPN- oder Reverse-Proxy-Container aktualisiert, über den deine Verbindung läuft, kann die Sitzung abbrechen. Ein laufendes Upgrade würde dann mittendrin abbrechen.
- **Container mit Herstellersoftware,** die nur bestimmte Releases unterstützt (z. B. UniFi OS Server), solltest du unter **„Kein Release-Upgrade“** anhaken. Paket-Updates bekommen sie trotzdem.
- **Nach einem Ubuntu-Release-Upgrade** deaktiviert `do-release-upgrade` Fremdquellen wie das Docker-Repo. Das Skript zeigt sie an, wieder aktivieren musst du sie selbst.
- **Der Proxmox-Host muss das neue Release unterstützen.** Neue Debian- oder Ubuntu-Versionen brauchen in LXC eine ausreichend aktuelle Proxmox-Version.

## Einstellungen

Alle Einstellungen setzt du bei jedem Start im Menü. Eine Konfigurationsdatei gibt es nicht. Eine `/etc/release-upgrade.conf` aus Version 1.4.0 oder 1.4.1 wird nicht mehr gelesen. Das Skript weist beim Start darauf hin, und du kannst sie mit `rm /etc/release-upgrade.conf` entfernen.

## Deinstallation

Da nichts installiert wird, bleiben nur die Logs:

```bash
rm -r /var/log/release-upgrade   # optional: Logs löschen
```

## Haftungsausschluss

Die Nutzung erfolgt auf eigene Verantwortung. Das Skript wurde sorgfältig erstellt, kann aber nicht jede Konstellation abdecken. Mach vor Release-Upgrades immer ein Backup.

## Lizenz

[MIT](LICENSE) © Schoti9807
