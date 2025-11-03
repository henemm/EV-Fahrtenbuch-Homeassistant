# Nächste Schritte - iOS App fertigstellen

## Status

**Phase 1 (Prototyp):** ✅ Abgeschlossen
- Python-Prototyp funktioniert
- Home Assistant API validiert
- Daten erfolgreich abgerufen (66% Batterie, 49230 km)

**Phase 2 (iOS App):** 📝 Bereit für Xcode-Setup
- Alle Swift-Dateien implementiert
- Dokumentation vollständig
- Bereit zum Bauen

---

## Checkliste - Xcode Setup

### 1. Xcode-Projekt erstellen

- [ ] Xcode öffnen → New Project → iOS App
- [ ] Settings:
  - Product Name: **HomeAssistent Fahrtenbuch**
  - Bundle Identifier: **henemm.fahrtenbuch.dev**
  - Interface: **SwiftUI**
  - Storage: **Core Data** ✓
  - Deployment Target: **iOS 18.0**
- [ ] Speicherort: `Fahrtenbuch-Enyaq-HomeAssistant/ios/`

**Anleitung:** [DOCS/ios-setup.md](ios-setup.md)

### 2. Code-Dateien einbinden

- [ ] In Xcode: **Add Files to Project**
- [ ] Wähle alle Dateien aus `ios/HomeAssistentFahrtenbuch/`
- [ ] ✓ Copy items if needed
- [ ] ✓ Create groups

### 3. Core Data Model erstellen

- [ ] `Fahrtenbuch.xcdatamodeld` in Xcode öffnen
- [ ] Entity "Trip" erstellen mit Attributes:
  - `id` (UUID, required)
  - `startDate` (Date, required)
  - `endDate` (Date, optional)
  - `startBatteryPercent` (Double, required)
  - `endBatteryPercent` (Double, optional)
  - `startOdometer` (Double, required)
  - `endOdometer` (Double, optional)
- [ ] Constraint auf `id` setzen
- [ ] Codegen: **Manual/None**

**Anleitung:** [DOCS/core-data-model.md](core-data-model.md)

### 4. Info.plist konfigurieren

- [ ] App Transport Security für Home Assistant Cloud:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>ui.nabu.casa</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 5. Signing & Capabilities

- [ ] Automatic manage signing aktivieren
- [ ] Team auswählen
- [ ] **Capability hinzufügen:** Keychain Sharing

### 6. Erster Build

- [ ] Build: `⌘ + B`
- [ ] Falls Fehler → siehe Troubleshooting in [ios-setup.md](ios-setup.md)

### 7. Auf Device/Simulator testen

- [ ] Run: `⌘ + R`
- [ ] App öffnet sich
- [ ] Settings konfigurieren:
  - Home Assistant URL
  - Token
  - Entity-IDs
- [ ] Verbindungstest durchführen
- [ ] Erste Fahrt starten/beenden

---

## Test-Plan

### Manuelle Tests (nach erstem Build)

**1. Settings-Flow:**
- [ ] Settings öffnen
- [ ] Home Assistant Credentials eingeben
- [ ] "Verbindung testen" → Sollte Batterie% und km-Stand anzeigen

**2. Fahrt-Tracking:**
- [ ] "Fahrt starten" → Sollte aktuelle Daten speichern
- [ ] Active Trip View anzeigen
- [ ] "Fahrt beenden" → Sollte End-Daten speichern
- [ ] Fahrt erscheint in Liste mit korrekten Werten

**3. Fahrten-Liste:**
- [ ] Mehrere Fahrten anlegen
- [ ] Gruppierung nach Monat prüfen
- [ ] Monats-Zusammenfassung (kWh + €) korrekt?
- [ ] Fahrt löschen via Context-Menu

**4. Error-Handling:**
- [ ] Fahrt starten ohne HA-Config → Fehler?
- [ ] Fahrt starten bei Netzwerk-Fehler → Fehler-Message?
- [ ] Ungültige Entity-IDs → Fehler-Message?

---

## Bekannte Einschränkungen (MVP)

**Nicht implementiert in v1.0:**
- ❌ CSV/PDF-Export
- ❌ Verbrauchsstatistiken (Charts)
- ❌ Mehrere Fahrzeuge
- ❌ iCloud-Sync
- ❌ Widgets
- ❌ GPS-Tracking der Route

**Geplant für v1.1+:**
- 📋 Export-Funktion (CSV für Excel)
- 📊 Verbrauchsdiagramme
- 🔔 Benachrichtigungen ("Fahrt beenden?")

---

## Offene Fragen

**1. App-Icon:**
- Soll ich ein App-Icon-Design vorschlagen?
- Farben: Škoda-Grün (`#4BA82E`) + Schwarz/Weiß?

**2. App-Name im Store:**
- "HomeAssistent Fahrtenbuch" oder kürzer?
- English: "Home Assistant Trip Logger"?

**3. Veröffentlichung:**
- TestFlight-Beta für Familie/Freunde?
- App Store Release geplant?
- Open Source (GitHub)?

---

## Nächste Feature-Ideen

**Aus User-Feedback sammeln:**
1. Welche Export-Formate werden gebraucht?
2. Sind Kategorien für Fahrten wichtig? (privat/geschäftlich)
3. Sollen Lade-Vorgänge auch getrackt werden?
4. Automatische Fahrt-Erkennung via Bluetooth-Auto?
5. Multi-User (Familie teilt Auto)?

---

## Support & Debugging

**Bei Problemen:**
1. Xcode Console-Log prüfen
2. Settings → Verbindungstest durchführen
3. Home Assistant Developer Tools → States prüfen
4. [DOCS/ios-setup.md](ios-setup.md) Troubleshooting-Sektion

**Log-Dateien:**
- Xcode → Window → Devices and Simulators → Device Logs

**Core Data Reset:**
- App deinstallieren → Neu installieren

---

## Timeline-Vorschlag

**Woche 1:**
- [ ] Xcode-Setup abschließen
- [ ] Erste Builds erfolgreich
- [ ] Manuelle Tests durchführen

**Woche 2:**
- [ ] Feedback sammeln (Hennings Sohn testet)
- [ ] Bugfixes & UX-Verbesserungen
- [ ] TestFlight-Beta vorbereiten

**Woche 3+:**
- [ ] Feature-Requests priorisieren
- [ ] v1.1 Features implementieren
- [ ] App Store Submission (falls gewünscht)

---

**Status:** Bereit für Xcode-Setup! 🚀
