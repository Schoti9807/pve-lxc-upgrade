# Changelog

Alle wichtigen Änderungen an Release-Upgrade. Neueste Version oben.
Versionsschema: VERSION.MAJOR.MINOR (z. B. 1.3.0).

- **VERSION:** wird nur erhöht, wenn der Autor das ausdrücklich entscheidet.
- **MAJOR:** wird bei jeder Änderung um 1 erhöht, außer es handelt sich um einen Hotfix.
- **MINOR:** wird bei Hot- und Bugfixes um 1 erhöht.

## 1.3.0 – 2026-11-14

Erste veröffentlichte Version.

- Grafisches Startmenü (whiptail) mit Modus, Container-Auswahl, Ausschlüssen, „Kein Release-Upgrade“ und „Gestoppte einbeziehen“
- Paket-Updates (`apt full-upgrade`) für alle oder ausgewählte Container
- Release-Upgrades für Debian (eine Stufe pro Lauf, Quellen-Sicherung mit automatischem Zurücksetzen) und Ubuntu (`do-release-upgrade`)
- Konfigurationsdatei-Abfragen werden automatisch mit „eigene Version behalten“ beantwortet
- Dienst-Prüfung vorher/nachher (systemd-Dienste, Docker-Container, TCP-Ports) mit Neustart-Angebot
- Sonderbehandlung für den Proxmox Backup Server (`pbs3to4 --full`, Bestätigung mit „JA“)
- Anzeige des letzten Backups vor Release-Upgrades
- Automatische Installation fehlender Abhängigkeiten auf dem Host
- Selbstinstallation nach `/usr/local/sbin/Release-Upgrade`
- Menüpunkt „Skript aktualisieren“ mit Anzeige von Changelog und Änderungen
- Logdatei für jeden Lauf unter `/var/log/release-upgrade/`
