# Fahrtenbuch - OpenSpec Project

## App Vision

Fahrtenbuch-App für Škoda Enyaq (Elektroauto) mit automatischem Tracking via Home Assistant für monatliche Kostenabrechnung.

**Primärer Nutzer:** Hennings Sohn (privater Enyaq-Nutzer)

## Target Platforms

- iOS 17.0+
- Widget Extension (WidgetKit)
- Live Activity (Dynamic Island)

## Core Features

### Primary Features
- **Trip Tracking:** Start/Stop via Button, erfasst Batterie% + km-Stand
- **Cost Calculation:** Automatische Berechnung von kWh-Verbrauch und Kosten

### Support Features
- **Live Activity:** Timer im Dynamic Island während aktiver Fahrt
- **Siri Shortcuts:** "Fahrt starten" / "Fahrt beenden" via Sprachbefehl
- **Offline Mode:** Manuelle Batterie%-Eingabe bei fehlendem Netzwerk

### Passive Features
- **Monthly Statistics:** Übersicht über Verbrauch und Kosten
- **Export:** Daten für Abrechnung exportieren

## Technical Stack

- **Language:** Swift 6
- **UI Framework:** SwiftUI
- **Data:** Core Data (lokal)
- **API:** Home Assistant REST API
- **Dependencies:** Keine externen (pure Apple frameworks)

## Key Constraints

**Data Latency:** Škoda Connect aktualisiert Daten nur alle 5-10 Minuten.
- Konsequenz: Start/Stop Button Konzept ist optimal
- Kein kontinuierliches Polling sinnvoll
- LiveActivity verwendet System-Timer, keine API-Calls

## Feature Categories

| Feature | Category | Status |
|---------|----------|--------|
| Trip Start/End | Primary | Implemented |
| Cost Calculation | Primary | Implemented |
| Live Activity | Support | Implemented (Lock Screen timer broken) |
| Siri Shortcuts | Support | Implemented |
| Offline Mode | Support | Implemented |
| Monthly Stats | Passive | Implemented |
| Export | Passive | Basic |

## Spec Index

All feature specifications are in `specs/`:

- `features/` - Feature specifications
- `integrations/` - Home Assistant integration spec
