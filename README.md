# EV Fahrtenbuch Home Assistant

iOS App für Tracking von Škoda Enyaq Fahrten mit Home Assistant Integration.

## Features

- **Home Assistant Integration**: Automatisches Abrufen von Fahrzeugdaten (Batterie, Odometer, Ladestand)
- **LiveActivity**: Live-Anzeige laufender Fahrten auf dem Lock Screen (iOS 16.1+)
- **Widgets**: Home Screen Widget mit aktuellem Fahrtenstatus
- **Shortcuts Integration**: URL Schemes für Automation mit der Kurzbefehle-App
- **Abrechnungssystem**: Unterscheidung zwischen geschäftlichen und privaten Fahrten
- **Export-Funktion**: CSV-Export für Buchhaltung
- **Demo Mode**: Testen ohne Home Assistant Verbindung
- **Core Data**: Lokale Persistierung aller Fahrten

## Voraussetzungen

- iOS 16.1 oder höher
- Xcode 15.0+
- Home Assistant mit Škoda Connect Integration
- Nabu Casa Cloud Subscription (für externe API-Zugriffe)

## Installation

1. Repository klonen:
```bash
git clone https://github.com/henemm/EV-Fahrtenbuch-Homeassistant.git
cd EV-Fahrtenbuch-Homeassistant
```

2. Xcode Projekt öffnen:
```bash
open ios/HomeAssistentFahrtenbuch.xcodeproj
```

3. Team & Bundle Identifier anpassen:
   - Öffne Project Settings
   - Wähle dein Apple Developer Team
   - Passe den Bundle Identifier an

4. Home Assistant konfigurieren:
   - In der App: Einstellungen → Home Assistant URL & Token eingeben
   - Alternativ: Demo Mode für Tests aktivieren

## Verwendung

### Fahrt starten

1. **Manuell**: "Fahrt starten" Button in der App
2. **Shortcuts**: URL Scheme `fahrtenbuch://start`
3. **Automation**: Bluetooth-basierte Trigger in der Kurzbefehle-App

### Fahrt beenden

1. **Manuell**: "Fahrt beenden" Button
2. **Shortcuts**: URL Scheme `fahrtenbuch://stop`

### LiveActivity

Nach dem Start einer Fahrt erscheint automatisch eine LiveActivity auf dem Lock Screen mit:
- Fahrtdauer (aktualisiert alle 30 Sekunden)
- Batterie-Stand beim Start
- Odometer beim Start

## Projektstruktur

```
ios/
├── HomeAssistentFahrtenbuch/          # Haupt-App
│   ├── Models/                         # Core Data Models, AppSettings
│   ├── Services/                       # HomeAssistant API, LiveActivity, Keychain
│   ├── ViewModels/                     # Business Logic
│   └── Views/                          # SwiftUI Views
├── FahrtenbuchWidget/                  # Widget Extension
│   ├── Models/                         # TripActivityAttributes (LiveActivity)
│   ├── Providers/                      # Timeline Provider
│   └── Views/                          # Widget & LiveActivity Views
└── HomeAssistentFahrtenbuchTests/      # Unit Tests
```

## Konfiguration

### Home Assistant Setup

Siehe [DOCS/home-assistant-setup.md](DOCS/home-assistant-setup.md)

### Shortcuts Integration

Siehe [DOCS/kurzbefehle-setup.md](DOCS/kurzbefehle-setup.md)

## Entwicklung

### Build

```bash
cd ios
xcodebuild -scheme HomeAssistentFahrtenbuch -destination 'generic/platform=iOS' build
```

### Tests

```bash
xcodebuild -scheme HomeAssistentFahrtenbuch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

### LiveActivity Validierung

```bash
./validate_liveactivity_setup.sh
```

## Technologie-Stack

- **SwiftUI**: Moderne, deklarative UI (iOS 18 "Liquid Glass" Design)
- **Core Data**: Lokale Datenpersistierung
- **ActivityKit**: LiveActivity Support (iOS 16.1+)
- **WidgetKit**: Home Screen Widgets
- **Combine**: Reactive Programming
- **Swift 6**: Neueste Swift-Version mit Concurrency-Features

## Roadmap

Siehe [DOCS/next-steps.md](DOCS/next-steps.md) für geplante Features.

## Version

**v0.1** (Initial Release)

## Lizenz

MIT License - Siehe [LICENSE](LICENSE) für Details.

## Danksagung

Entwickelt mit [Claude Code](https://claude.com/claude-code)

## Support

Issues und Feature Requests bitte über [GitHub Issues](https://github.com/henemm/EV-Fahrtenbuch-Homeassistant/issues).
