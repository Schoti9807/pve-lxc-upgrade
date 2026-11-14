# Changelog

Alle wichtigen Änderungen an Release-Upgrade. Neueste Version oben.
Versionsschema: MAJOR.MINOR.PATCH. PATCH steht für Fehlerbehebungen, MINOR für neue Funktionen, MAJOR für größere Umbauten.

## 1.0.0 – 2026-11-14

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
