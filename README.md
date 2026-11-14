# pve-lxc-upgrade

**Release-Upgrade** ist ein Bash-Skript für die **Proxmox-VE-Host-Shell**. Es prüft alle **LXC-Container** (Debian und Ubuntu) auf Updates und aktualisiert sie nach Bestätigung. Das gilt für normale Paket-Updates und für **Distributions-Upgrades** wie Debian 12 → 13 oder Ubuntu 22.04 → 24.04.

Alle Einstellungen setzt du in einem grafischen Menü (whiptail). Erst wenn du dort **Starten** wählst, passiert etwas.

```
┌──────────── Release-Upgrade 1.5.0 – proxmox ─────────────┐
│ 1  Modus ................... prüfen + aktualisieren      │
│ 2  Nur diese Container ..... alle                        │
│ 3  Container auslassen ..... keine                       │
│ 4  Kein Release-Upgrade .... keine                       │
│ 5  Gestoppte einbeziehen ... nein                        │
│ 6  Docker-Images ........... nein                        │
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
- **Docker-Images (optional, Menüpunkt 6):** Das Skript prüft die laufenden Docker-Container in jedem LXC auf neue Images. Gibt es welche, fragt es je LXC nach, erstellt die betroffenen Dienste mit `docker compose up -d` neu und räumt danach mit `docker image prune -f` alte Images auf. Details unten.
- **Dienst-Prüfung vorher/nachher:** laufende systemd-Dienste, Docker-Container und offene TCP-Ports werden verglichen. Fehlende Dienste oder Container kannst du direkt neu starten lassen.
- **Konfigurationsdateien:** Abfragen wie „deine Version behalten oder ersetzen?“ beantwortet das Skript automatisch mit „behalten“. Die neue Paketversion liegt dann als `*.dpkg-dist` daneben.
- **Proxmox Backup Server im Container:** Das Skript erkennt ihn, warnt extra, führt `pbs3to4 --full` aus und will eine ausdrückliche Bestätigung
- **Letztes Backup** des Containers wird vor jedem Release-Upgrade angezeigt
- **Immer aktuell:** Das Skript wird bei jedem Start direkt von GitHub geladen und ausgeführt, ein eigenes Update ist nicht nötig
- **Logdatei** für jeden Lauf unter `/var/log/release-upgrade/`

**Was das Skript bewusst nicht macht:** Backups erstellen, Docker-Container ohne Compose aktualisieren und VMs bearbeiten.

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

## Docker-Images

Ist **6 – Docker-Images** auf „ja“ gestellt, kommt nach den Paket- und Release-Updates ein eigener Abschnitt. Für jeden LXC mit laufenden Docker-Containern gilt:

1. Das Skript lädt für jeden laufenden Container das Image neu (`docker pull`) und vergleicht es mit dem Image, mit dem der Container läuft.
2. Es zeigt pro Container an, ob es ein neues Image gibt.
3. Gibt es neue Images, fragt es einmal für diesen LXC nach.
4. Nach deiner Bestätigung erstellt es nur die betroffenen Compose-Dienste mit `docker compose up -d <dienst>` neu. Danach räumt es mit `docker image prune -f` alte, nicht mehr benutzte Images auf.
5. Die Dienst-Prüfung vorher/nachher läuft wie bei den Paket-Updates mit.

Gut zu wissen:

- **Nur Compose:** Container, die mit `docker run` gestartet wurden, meldet das Skript nur („neues Image – bitte manuell aktualisieren“). Es ändert sie nicht.
- **Feste Tags:** Ein Image wie `postgres:16` bekommt nur Updates innerhalb von 16, nie einen Sprung auf 17. Das Skript weist bei jedem Lauf darauf hin, welche Container einen festen Tag nutzen. Für eine neue Hauptversion musst du den Tag selbst ändern.
- **Gepinnte Images** (`image@sha256:…`) werden übersprungen.
- **Lokal gebaute Images** lassen sich nicht aus einer Registry laden und werden nur gemeldet.
- Die Prüfung lädt neue Images bereits herunter. Im Modus **nur prüfen** werden Docker-Images deshalb nicht geprüft.

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
