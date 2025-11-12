# Postmanagement Game

Ein prototypisches Management-Spiel rund um ein fiktives Post- und Paketzentrum. Das Projekt basiert auf Godot 4 und umfasst ein Hauptmenü zur Firmengründung, ein 3D-Logistikzentrum mit HUD sowie grundlegende Wirtschaftsmechaniken.

## Features

- **Hauptmenü** zum Anlegen deiner Firma inklusive Namenswahl, Logo-Farbe und Startkapital von 1.000.000 €.
- **Offene OpenEarth-Karte** mit frei platzierbaren Filialen, Depots und Sortierzentren zu realistischen Preisspannen.
- **Fuhrpark-Management**: Kaufe Transporter, LKWs und Sattelzüge und plane Routen zwischen eigenen Standorten.
- **Finanzzentrale** mit drei Kreditlinien, automatischer Ratenzahlung und Anzeige von Euro- sowie Dollar-Salden.
- **HUD** mit Firmenstatus, Tagesberichten, Marktangeboten und Netzwerkinformationen.
- **Sendungssimulation** von der Annahme bis zur Zustellung mit zufälligen Ereignissen wie Verzögerungen oder Verlusten.
- **Tagesablauf**: Automatischer oder manueller Tagesfortschritt (Taste `Enter`) inklusive Einnahmen-/Ausgabenberechnung.

## Projektstruktur

```
project.godot              # Godot-Projektdatei
scenes/
  MainMenu.tscn            # Hauptmenü mit Firmengründung
  Game.tscn                # Hauptspielszene mit 3D-Umgebung
  ui/HUD.tscn              # Benutzeroberfläche während des Spiels
scripts/
  MainMenu.gd              # Menülogik
  GameManager.gd           # Spielschleife & Tagesablauf
  CompanyData.gd           # Persistente Firmendaten, Märkte, Kredite & Netzwerklogik (Autoload)
  LogisticsNetwork.gd      # OpenEarth-Karte mit Standorten, Routen und Fahrzeuganimationen
  HUD.gd                   # Benutzeroberfläche für Finanzen, Assets und Routenplanung
```

## Nutzung

1. Öffne das Projekt in **Godot 4.x**.
2. Starte die Szene `MainMenu.tscn` oder drücke **Play**, um das Hauptmenü zu laden.
3. Vergib einen Firmennamen, wähle eine Logofarbe und klicke auf **Spiel Starten**.
4. Kaufe Standorte oder Fahrzeuge über die Tabs **Immobilien** und **Flotte** im HUD und plane anschließend Routen zwischen deinen eigenen Gebäuden.
5. Nutze den Tab **Finanzen**, um Kredite aufzunehmen oder zu tilgen und behalte Euro- sowie Dollar-Salden im Blick.
6. Beobachte Sendungen im Netzwerk und beschleunige den Tagesfortschritt bei Bedarf mit der Taste **Enter**.

## Windows-Installer erstellen

Eine automatisierte Pipeline erzeugt eine `Setup.exe`, mit der sich der aktuelle Prototyp auf Windows 10/11 installieren und testen lässt.

1. Installiere **Godot 4.x (Standard Edition)** und stelle sicher, dass der Befehl `godot` im Terminal verfügbar ist.
2. Installiere die **Godot Export Templates** sowie den **Inno Setup Compiler 6** (inklusive CLI `iscc`).
3. Klone dieses Repository und öffne ein Terminal im Projektwurzelverzeichnis.
4. Führe das Skript `tools/build_setup.sh` aus:

   ```bash
   ./tools/build_setup.sh
   ```

5. Nach erfolgreicher Ausführung findest du die Datei `PostManagementGameSetup.exe` im Projektwurzelverzeichnis. Diese kann auf einem Windows-System gestartet werden und installiert das Spiel samt Desktop- und Startmenü-Verknüpfung.

Während des Exports werden die Dateien im Ordner `build/windows/` aktualisiert. Der Installer legt das Spiel standardmäßig im Benutzerprogrammverzeichnis (`%ProgramFiles%`) ab und bietet optional die Erstellung einer Desktop-Verknüpfung an.

## Wirtschaft & Netzwerk

- **Immobilienmarkt**: Jede Stadt auf der OpenEarth-Karte besitzt realistische Kaufpreise sowie Upgrade-Stufen, die Kapazität und Netzwerkstärke erhöhen.
- **Fuhrpark**: Drei Fahrzeugklassen decken den Bereich von Stadtlieferungen bis Fernverkehr ab. Weise den Wagen feste Routen zwischen eigenen Gebäuden zu.
- **Kredite**: Drei Kreditpakete mit Laufzeiten zwischen 24 und 72 Monaten stehen bereit. Raten werden automatisch monatlich belastet.
- **Währungen**: Das HUD zeigt Kontostand in Euro sowie den umgerechneten Dollarwert (Fixkurs 1 € = 1,08 $) für internationale Vergleiche.

## Weiterentwicklung

- Ausbau der 3D-Umgebung mit detaillierten Assets und Animationen.
- Implementierung eines komplexeren Liefernetzwerks (z. B. Filialen, Flug- und Bahnverbindungen).
- Einführung von Mitarbeitermanagement, Forschung & Entwicklung sowie Kundenaufträgen.
- Speichern/Laden des Spielstands und UI-Optionen für verschiedene Auflösungen.
