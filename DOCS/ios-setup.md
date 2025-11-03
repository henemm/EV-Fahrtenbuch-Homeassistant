# iOS App Setup - HomeAssistent Fahrtenbuch

## Xcode-Projekt erstellen

### 1. Neues Projekt in Xcode anlegen

1. Öffne Xcode → **File** → **New** → **Project**
2. Wähle **iOS** → **App**
3. Einstellungen:
   - **Product Name:** HomeAssistent Fahrtenbuch
   - **Team:** Dein Apple Developer Team
   - **Organization Identifier:** henemm.fahrtenbuch
   - **Bundle Identifier:** henemm.fahrtenbuch.dev
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** Core Data ✓ (wichtig!)
   - **Include Tests:** ✓ (optional, aber empfohlen)
4. Speicherort: `Fahrtenbuch-Enyaq-HomeAssistant/ios/`

### 2. Projekt-Einstellungen

**General Tab:**
- **Deployment Target:** iOS 18.0
- **Supported Destinations:** iPhone only
- **Supports multiple windows:** ❌ (aus)

**Info Tab / Info.plist:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>ui.nabu.casa</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```
→ Erlaubt HTTPS-Verbindungen zu Home Assistant Cloud

**Signing & Capabilities:**
- ✅ Automatic manage signing
- ✅ Add Capability: **Keychain Sharing** (für sicheren Token-Speicher)

### 3. Code-Dateien einbinden

Die fertigen Swift-Dateien liegen in `ios/HomeAssistentFahrtenbuch/`.

**In Xcode:**
1. Rechtsklick auf Projekt-Root → **Add Files to "HomeAssistent Fahrtenbuch"...**
2. Wähle alle Dateien aus `ios/HomeAssistentFahrtenbuch/` aus
3. ✅ **Copy items if needed**
4. ✅ **Create groups** (nicht folder references)
5. Target: HomeAssistent Fahrtenbuch

### 4. Core Data Model prüfen

Xcode sollte automatisch eine `.xcdatamodeld`-Datei erstellt haben.

**Falls nicht vorhanden:**
1. **File** → **New** → **File** → **Data Model**
2. Name: `Fahrtenbuch.xcdatamodeld`
3. Siehe [core-data-model.md](core-data-model.md) für Entity-Definition

### 5. Erste Build

```bash
cmd + B
```

**Bei Fehlern:**
- Core Data Model fehlt? → Siehe Schritt 4
- Signing-Fehler? → Team in Signing & Capabilities auswählen

---

## App-Struktur

```
HomeAssistent Fahrtenbuch/
├── Models/
│   ├── Trip+CoreDataClass.swift
│   ├── Trip+CoreDataProperties.swift
│   └── AppSettings.swift
├── Services/
│   ├── HomeAssistantService.swift
│   ├── KeychainService.swift
│   └── PersistenceController.swift
├── ViewModels/
│   ├── TripsViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── TripsListView.swift
│   ├── ActiveTripView.swift
│   ├── SettingsView.swift
│   └── Components/
│       ├── TripRowView.swift
│       └── MonthSectionHeader.swift
├── Resources/
│   └── Assets.xcassets
├── Fahrtenbuch.xcdatamodeld
└── HomeAssistentFahrtenbuchApp.swift
```

---

## Erste Schritte nach Installation

### 1. App starten

→ Settings öffnen (Tab-Bar)

### 2. Home Assistant konfigurieren

**Erforderlich:**
- Home Assistant URL (z.B. `https://xyz.ui.nabu.casa`)
- Langlebiger Token (siehe [home-assistant-setup.md](home-assistant-setup.md))
- Entity-ID Batterie (z.B. `sensor.enyaq_battery_level`)
- Entity-ID Kilometerstand (z.B. `sensor.enyaq_odometer`)

**Optional:**
- Strompreis (Standard: 0,30 €/kWh)
- Batteriekapazität (Standard: 77 kWh für Enyaq iV 80)

### 3. Verbindung testen

Settings → **"Verbindung testen"** Button

→ Sollte aktuelle Batterie% und km-Stand anzeigen

### 4. Erste Fahrt tracken

→ Zurück zur Fahrten-Liste
→ **"Fahrt starten"** Button
→ Nach Fahrt: **"Fahrt beenden"**

---

## Troubleshooting

### "Keine Verbindung zu Home Assistant"

**Prüfe:**
1. URL korrekt? (mit `https://`, ohne `/api` am Ende)
2. Token gültig? (in Home Assistant: Sicherheit → Tokens)
3. Internet-Verbindung vorhanden?
4. Firewall/VPN blockiert Zugriff?

### "Entity nicht gefunden"

**Prüfe:**
1. Entity-IDs in Home Assistant prüfen: **Developer Tools** → **Zustände**
2. Exakte Schreibweise (inkl. Unterstriche, keine Leerzeichen)
3. Integration aktiv? (Einstellungen → Geräte & Dienste)

### Core Data Fehler

**Reset (ACHTUNG: Löscht alle Fahrten!):**
1. App deinstallieren
2. Neu installieren
3. Settings erneut konfigurieren

---

## Nächste Schritte

- [ ] Xcode-Projekt erstellt und kompiliert
- [ ] Home Assistant Credentials eingetragen
- [ ] Verbindungstest erfolgreich
- [ ] Erste Test-Fahrt erfolgreich getrackt

→ Feedback geben für Verbesserungen und weitere Features!
