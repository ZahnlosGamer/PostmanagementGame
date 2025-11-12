# Postmanagement Game

Ein prototypisches Management-Spiel rund um ein fiktives Post- und Paketzentrum. Das Projekt basiert auf Godot 4 und umfasst ein Hauptmenü zur Firmengründung, ein 3D-Logistikzentrum mit HUD sowie grundlegende Wirtschaftsmechaniken.

## Features

- **Hauptmenü** zum Anlegen deiner Firma inklusive Namenswahl und frei wählbarer Logofarbe.
- **3D-Spielszene** mit Paketzentrum, Sortieranlage und Lieferfahrzeug.
- **HUD** mit Firmenstatus, Finanzübersicht, Reputation und Tagesbericht.
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
  CompanyData.gd           # Persistente Firmendaten & Wirtschaftssystem (Autoload)
  LogisticsNetwork.gd      # Einfache 3D-Visualisierung des Paketzentrums
  HUD.gd                   # Aktualisierung der HUD-Anzeigen
```

## Nutzung

1. Öffne das Projekt in **Godot 4.x**.
2. Starte die Szene `MainMenu.tscn` oder drücke **Play**, um das Hauptmenü zu laden.
3. Vergib einen Firmennamen, wähle eine Logofarbe und klicke auf **Spiel Starten**.
4. Beobachte Sendungen im Paketzentrum, verfolge Finanzen und Reputation im HUD.
5. Beschleunige den Tagesfortschritt bei Bedarf mit der Taste **Enter**.

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

## Weiterentwicklung

- Ausbau der 3D-Umgebung mit detaillierten Assets und Animationen.
- Implementierung eines komplexeren Liefernetzwerks (z. B. Filialen, Flug- und Bahnverbindungen).
- Einführung von Mitarbeitermanagement, Forschung & Entwicklung sowie Kundenaufträgen.
- Speichern/Laden des Spielstands und UI-Optionen für verschiedene Auflösungen.
