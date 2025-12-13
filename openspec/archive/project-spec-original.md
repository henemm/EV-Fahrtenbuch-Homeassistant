# Projekt-Spezifikation: Enyaq Fahrtenbuch App

## Vision

Einfache iOS-App für Škoda Enyaq-Fahrer, die Fahrten automatisch trackt und monatliche Kosten berechnet.

**Primärer Nutzer:** Hennings Sohn (privater Enyaq-Nutzer)
**Sekundäres Ziel:** App für andere Enyaq/Elektroauto-Besitzer nutzbar machen

---

## Core Use Case

**Ablauf einer Fahrt:**

1. **Fahrt Start:**
   - Nutzer öffnet App
   - Button "Fahrt starten" → speichert:
     - Batteriestand (%)
     - Kilometerstand
     - Datum + Uhrzeit

2. **Fahrt Ende:**
   - Button "Fahrt beenden" → speichert:
     - Batteriestand (%)
     - Kilometerstand
     - Datum + Uhrzeit

3. **Monats-Auswertung:**
   - Liste aller Fahrten des Monats
   - Gesamt-Verbrauch (kWh)
   - Gesamt-Kosten (€)
   - Export-Funktion (für Überweisung/Abrechnung)

---

## Technische Architektur

### Phase 1: Prototyp (aktuell)
- **Ziel:** Home Assistant API validieren
- **Technologie:** Python
- **Output:** Dokumentation der API-Struktur für iOS-Implementierung

### Phase 2: iOS App
- **Framework:** SwiftUI (iOS 17+)
- **Datenspeicherung:** Core Data (lokal)
- **Backend:** Home Assistant REST API (direkt aus Swift)
- **Design:** iOS 18 "Liquid Glass" Design Language

---

## Features (MVP)

### Must-Have (Version 1.0)
- ✅ Fahrt starten/beenden (2-Button-Interface)
- ✅ Automatisches Auslesen von Batterie% und km-Stand via Home Assistant
- ✅ Liste aller Fahrten (gruppiert nach Monat)
- ✅ Monats-Auswertung: Verbrauch + Kosten
- ✅ Einstellungen: Strompreis/kWh konfigurierbar

### Nice-to-Have (Version 1.x)
- 📋 Export als CSV/PDF
- 📊 Verbrauchsstatistiken (Ø pro Fahrt, Trends)
- 🚗 Mehrere Fahrzeuge unterstützen
- 🔔 Erinnerung "Fahrt beenden" bei längerem Tracking

### Future (Version 2.0+)
- ☁️ iCloud-Sync (mehrere Geräte)
- 📍 GPS-Tracking für Fahrtroute
- 🤝 Multi-User (Familie teilt Auto)
- 🔌 Integration mit Ladesäulen-Daten

---

## Datenmodell

### Trip (Fahrt)
```swift
struct Trip {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let startBattery: Double      // in %
    let endBattery: Double        // in %
    let startOdometer: Double     // in km
    let endOdometer: Double       // in km

    // Berechnete Werte
    var distance: Double {        // Strecke in km
        endOdometer - startOdometer
    }
    var batteryUsed: Double {     // Verbrauch in %
        startBattery - endBattery
    }
    var kwhUsed: Double {         // Verbrauch in kWh (77 kWh Batterie)
        (batteryUsed / 100) * 77
    }
    var cost: Double {            // Kosten in € (basierend auf Settings)
        kwhUsed * Settings.shared.costPerKwh
    }
}
```

### Settings
```swift
struct Settings {
    var costPerKwh: Double = 0.30         // Standard: 30 Cent/kWh
    var batteryCapacity: Double = 77.0    // Enyaq iV 80: 77 kWh
    var vehicleName: String = "Enyaq"

    // Home Assistant
    var haUrl: String
    var haToken: String
    var batteryEntityId: String
    var odometerEntityId: String
}
```

---

## Home Assistant Integration

### Benötigte Entities
- `sensor.enyaq_battery_level` (in %)
- `sensor.enyaq_odometer` (in km)

### API-Endpunkt
```
GET https://INSTANCE.ui.nabu.casa/api/states/{entity_id}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "state": "87",
  "attributes": {
    "unit_of_measurement": "%",
    "friendly_name": "Enyaq Battery Level"
  },
  "last_updated": "2025-11-02T10:30:00"
}
```

---

## UI-Flow (iOS App)

### Haupt-Screen: "Fahrten"
```
┌─────────────────────────┐
│  🚗 Enyaq Fahrtenbuch   │
│                         │
│  [Fahrt starten]        │  ← Großer Button
│                         │
│  📅 November 2025       │
│  ─────────────────      │
│  🔋 87% → 65% | 45 km   │  ← Fahrt-Karte
│     2.11. 10:30-11:15   │
│     3,8 kWh | 1,14 €    │
│                         │
│  🔋 78% → 52% | 120 km  │
│     1.11. 08:00-10:30   │
│     9,2 kWh | 2,76 €    │
│                         │
│  ════════════════════   │
│  Gesamt: 13,0 kWh       │
│  Kosten: 3,90 €         │
└─────────────────────────┘
```

### Screen: "Fahrt läuft"
```
┌─────────────────────────┐
│  🚗 Fahrt läuft...      │
│                         │
│  Start: 10:30           │
│  🔋 87%                 │
│  📍 12.543 km           │
│                         │
│  [Fahrt beenden]        │  ← Großer roter Button
└─────────────────────────┘
```

### Screen: "Einstellungen"
```
┌─────────────────────────┐
│  ⚙️ Einstellungen        │
│                         │
│  💶 Strompreis          │
│  0,30 € / kWh           │
│                         │
│  🔋 Batteriekapazität   │
│  77 kWh                 │
│                         │
│  🏠 Home Assistant      │
│  Verbunden ✓            │
│                         │
│  📤 Daten exportieren   │
└─────────────────────────┘
```

---

## Erfolgs-Kriterien

**Phase 1 (Prototyp) - Fertig, wenn:**
- ✅ Python-Script kann Batterie% und km-Stand abrufen
- ✅ Fahrt-Simulation funktioniert (Start → Ende → Kosten berechnet)
- ✅ API-Dokumentation für iOS-Implementierung vorhanden

**Phase 2 (MVP) - Fertig, wenn:**
- [ ] App auf iPhone installierbar
- [ ] Fahrt starten/beenden funktioniert mit echten Home Assistant Daten
- [ ] Fahrten werden gespeichert und korrekt angezeigt
- [ ] Monats-Auswertung rechnet korrekt
- [ ] Hennings Sohn kann die App nutzen und Fahrten tracken

---

## Offene Fragen / Diskussionspunkte

1. **Automatisches Tracking:** Soll die App automatisch erkennen, wann eine Fahrt startet (z.B. via Bluetooth-Verbindung zum Auto)?
2. **Fahrt-Kategorien:** Sollen Fahrten kategorisiert werden (privat/geschäftlich)?
3. **Steuer-Funktion:** Soll die App steuerrelevante Daten (Fahrtgrund, Route) speichern?
4. **Lade-Events:** Sollen auch Ladevorgänge getracked werden?

---

## Nächste Schritte

1. ✅ Prototyp fertigstellen
2. 🔲 Token + Entity-IDs von Henning erhalten
3. 🔲 Prototyp testen mit echten Daten
4. 🔲 iOS-Projekt aufsetzen (SwiftUI, Core Data)
5. 🔲 Home Assistant Client in Swift implementieren
6. 🔲 UI bauen
7. 🔲 TestFlight-Beta mit Henning & Sohn
