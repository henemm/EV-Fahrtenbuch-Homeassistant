# HomeAssistent Fahrtenbuch - iOS App

Fahrtenbuch-App für Škoda Enyaq mit Home Assistant Integration.

## Features

- 📱 **Einfaches Tracking:** Fahrt starten/beenden mit einem Button
- 🔋 **Automatische Daten:** Batterie% und Kilometerstand via Home Assistant
- 📊 **Monats-Auswertung:** Verbrauch (kWh) und Kosten (€) pro Monat
- ⚙️ **Konfigurierbar:** Strompreis und Batteriekapazität anpassbar
- 🎨 **Modern:** iOS 18 "Liquid Glass" Design

## Voraussetzungen

- iOS 18.0 oder neuer
- Xcode 16+ (für Development)
- Home Assistant mit Škoda Enyaq Integration
- Home Assistant Cloud oder lokaler Zugriff

## Setup

### 1. Xcode-Projekt erstellen

Siehe [DOCS/ios-setup.md](../DOCS/ios-setup.md) für detaillierte Anleitung.

**Kurzfassung:**
1. Xcode → New Project → iOS App
2. **Product Name:** HomeAssistent Fahrtenbuch
3. **Bundle Identifier:** henemm.fahrtenbuch.dev
4. **Interface:** SwiftUI
5. **Storage:** Core Data ✓
6. **Deployment Target:** iOS 18.0

### 2. Code-Dateien einbinden

Alle Swift-Dateien liegen in `HomeAssistentFahrtenbuch/`.

In Xcode:
- **Add Files to Project** → Wähle alle Dateien aus `HomeAssistentFahrtenbuch/`
- ✓ Copy items if needed
- ✓ Create groups

### 3. Core Data Model erstellen

Siehe [DOCS/core-data-model.md](../DOCS/core-data-model.md) für Entity-Definition.

**Entity "Trip" mit Attributes:**
- `id` (UUID, required)
- `startDate` (Date, required)
- `endDate` (Date, optional)
- `startBatteryPercent` (Double, required)
- `endBatteryPercent` (Double, optional)
- `startOdometer` (Double, required)
- `endOdometer` (Double, optional)

### 4. App-Icon erstellen (optional)

Erstelle ein App-Icon in `Assets.xcassets/AppIcon`.

**Empfohlenes Design:**
- Škoda-Grün (`#4BA82E`)
- Icon: Stilisiertes Auto mit Batterie-Symbol

### 5. Build & Run

```bash
⌘ + B  # Build
⌘ + R  # Run
```

## Erste Schritte

### 1. Home Assistant konfigurieren

**In der App:**
1. Öffne **Einstellungen** Tab
2. Trage ein:
   - Home Assistant URL (z.B. `https://xyz.ui.nabu.casa`)
   - Langlebiger Token (siehe [home-assistant-setup.md](../DOCS/home-assistant-setup.md))
   - Batterie Entity-ID (z.B. `sensor.enyaq_battery_level`)
   - Kilometerstand Entity-ID (z.B. `sensor.enyaq_odometer`)
3. Klicke **"Verbindung testen"**

### 2. Erste Fahrt tracken

1. Zurück zum **Fahrten** Tab
2. **"Fahrt starten"** → speichert aktuellen Batterie% und km-Stand
3. Nach Fahrt: **"Fahrt beenden"** → speichert End-Werte
4. Fahrt erscheint in der Liste mit Verbrauch und Kosten

## Architektur

```
HomeAssistent Fahrtenbuch/
├── Models/
│   ├── Trip+CoreDataClass.swift           # Core Data Entity
│   ├── Trip+CoreDataProperties.swift      # Properties
│   └── AppSettings.swift                  # App-Einstellungen
├── Services/
│   ├── HomeAssistantService.swift         # API-Client
│   ├── KeychainService.swift              # Token-Speicher
│   └── PersistenceController.swift        # Core Data Stack
├── ViewModels/
│   ├── TripsViewModel.swift               # Trips Business Logic
│   └── SettingsViewModel.swift            # Settings Logic
├── Views/
│   ├── ContentView.swift                  # Root mit Tab-Navigation
│   ├── TripsListView.swift                # Fahrten-Liste
│   ├── ActiveTripView.swift               # Laufende Fahrt
│   ├── SettingsView.swift                 # Einstellungen
│   └── Components/
│       ├── TripRowView.swift              # Einzelne Fahrt-Karte
│       └── MonthSectionHeader.swift       # Monats-Header
└── HomeAssistentFahrtenbuchApp.swift      # App Entry Point
```

## Troubleshooting

### "Keine Verbindung zu Home Assistant"

**Prüfe:**
- URL korrekt? (mit `https://`, ohne `/api`)
- Token gültig?
- Internet-Verbindung?

### "Entity nicht gefunden"

**Prüfe:**
- Entity-IDs in Home Assistant → Developer Tools → Zustände
- Exakte Schreibweise (inkl. Unterstriche)

### Build-Fehler

**Core Data Model fehlt?**
→ Siehe [core-data-model.md](../DOCS/core-data-model.md)

**Signing-Fehler?**
→ Wähle dein Team in **Signing & Capabilities**

## Entwicklung

### Tests ausführen

```bash
⌘ + U
```

### Previews nutzen

Alle Views haben SwiftUI Previews:
```swift
#Preview {
    TripsListView()
}
```

### Debug-Build

Standard-Build ist Debug. Für Release:
- **Product** → **Scheme** → **Edit Scheme** → **Build Configuration: Release**

## Nächste Features (geplant)

- [ ] CSV/PDF-Export für Fahrten
- [ ] Verbrauchsstatistiken (Charts)
- [ ] Mehrere Fahrzeuge unterstützen
- [ ] iCloud-Sync
- [ ] Widgets für Home Screen

## Lizenz

TBD

## Support

Bei Problemen siehe [DOCS/ios-setup.md](../DOCS/ios-setup.md) oder erstelle ein Issue.
