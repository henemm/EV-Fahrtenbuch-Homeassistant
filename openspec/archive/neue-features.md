# Neue Features - Release Vorbereitung

## Übersicht

Folgende Features wurden implementiert und sind bereit für App Store Release:

**⚠️ UPDATE:** CarPlay wurde entfernt (keine Apple-Genehmigung ohne spezielle Kategorie). Stattdessen: **Home Screen Widget** implementiert!

---

## 1. Demo-Modus ✅

**Zweck:** App Store Review ohne echte Credentials

**Aktivierung:**
- Settings → "Testing" → "Demo-Modus" aktivieren

**Funktion:**
- Simuliert realistische Fahrzeugdaten
- Keine echten API-Calls
- Ideal für Screenshots/Präsentation

**Status:** Vollständig implementiert

---

## 2. Kurzbefehle-Integration ✅

**Zweck:** Automatischer Start/End bei Bluetooth-Verbindung

**URL Schemes:**
- `fahrtenbuch://start` - Startet Fahrt
- `fahrtenbuch://end` - Beendet Fahrt

**Setup:**
- Siehe: `DOCS/kurzbefehle-setup.md`
- Einmalige Einrichtung in Kurzbefehle-App
- Dann vollautomatisch

**Nutzen:**
- Kein manuelles Starten mehr nötig
- Funktioniert auch bei geschlossener App
- Zuverlässige Bluetooth-Erkennung

**Status:** Vollständig implementiert

---

## 3. Debug-Feature: API-Polling während Fahrt ✅

**Zweck:** Daten sammeln über Škoda Connect Update-Frequenz

**Aktivierung:**
- Settings → "Developer" → "API-Polling während Fahrt"

**Funktion:**
- Pollt API alle 30s während aktiver Fahrt
- Loggt jede Änderung mit Timestamp
- Exportiert CSV-Datei

**Nutzen:**
- Verstehen, wie oft sich API-Werte ändern
- Optimierung von CarPlay Update-Intervallen
- Debugging bei Problemen

**Export:**
```csv
Timestamp,Sekunden seit Start,Batterie %,Odometer km
2025-11-03 10:15:00,0,66.0,49230.0
2025-11-03 10:15:30,30,66.0,49230.0
2025-11-03 10:16:00,60,65.8,49232.5
...
```

**Status:** Vollständig implementiert

---

## 4. Home Screen Widget ✅

**Zweck:** Schnellzugriff und Status-Anzeige direkt vom Home Screen

### Features:

**Widget zeigt aktive Fahrt:**
```
┌──────────────┐
│ 🚗 Fahrt läuft│
├──────────────┤
│ ⏱️ 01:23:45   │
│ 🔋 66% Start  │
│ 🛣️ 49230 km  │
└──────────────┘
```

**Widget ohne Fahrt:**
```
┌──────────────┐
│              │
│   🚗         │
│ Fahrt        │
│ starten      │
│              │
└──────────────┘
```
(Tap → öffnet App)

**Auto-Update:**
- Widget aktualisiert sich alle 60 Sekunden
- Zeigt Live-Dauer während Fahrt
- Automatische Synchronisation mit App

**Nutzen:**
- Immer sichtbar auf Home Screen
- Kein App-Öffnen nötig für Status-Check
- Schneller Zugriff zum Starten

**Setup:**
- Siehe: `DOCS/widget-setup.md`
- Widget Extension in Xcode erstellen
- App Groups konfigurieren
- Widget auf Home Screen platzieren

**Status:** Vollständig implementiert (Code ready, Xcode-Setup nötig)

---

## Dateien hinzugefügt

**Neue Swift-Dateien (Haupt-App):**
1. `Services/DeepLinkHandler.swift` - URL Scheme Handler
2. `Services/TripDebugLogger.swift` - Debug Logging Service
3. `Services/WidgetDataService.swift` - Widget Data Sharing

**Neue Widget-Dateien:**
1. `FahrtenbuchWidget/FahrtenbuchWidget.swift` - Widget UI + Logic

**WICHTIG:**
- Haupt-App-Dateien müssen zu Xcode hinzugefügt werden
- Widget Extension muss in Xcode erstellt werden (siehe widget-setup.md)

**Anleitung:**
```
Xcode → Project Navigator (⌘+1)
→ Rechtsklick auf "Services" / "CarPlay" Ordner
→ "Add Files to HomeAssistentFahrtenbuch..."
→ Wähle entsprechende .swift Datei
→ ✓ Create groups (NICHT "Copy items")
→ Add
```

---

## Änderungen an bestehenden Dateien

**AppSettings.swift:**
- `demoMode: Bool` - Demo-Modus Toggle
- `debugLoggingEnabled: Bool` - Debug-Logging Toggle

**HomeAssistantService.swift:**
- `getDemoVehicleData()` - Simulierte Daten-Funktion

**TripsViewModel.swift:**
- Demo-Modus Support in `startTrip()` / `endTrip()`
- Debug-Logger Integration
- Widget-Update Integration

**SettingsView.swift:**
- Demo-Modus UI
- Debug-Logging UI + Export

**Info.plist:**
- URL Scheme Registration (`fahrtenbuch://`)

**TripsListView.swift:**
- Deep Link Handler Integration
- Auto-Trigger bei URL-Aufruf

---

## App Store Review Vorbereitung

### ✅ Was fertig ist:

1. **Demo-Modus** → Reviewer kann App vollständig testen
2. **URL Schemes** → Deklariert in Info.plist
3. **Widget** → Code fertig, Extension muss in Xcode erstellt werden

### ⚠️ Was du tun musst:

**Xcode:**
1. Neue Dateien zum Projekt hinzufügen (siehe oben)
2. Widget Extension erstellen (siehe widget-setup.md)
3. App Groups konfigurieren
4. Build testen

**App Store Connect:**
1. **Demo-Modus in Screenshots verwenden:**
   - Settings → Demo-Modus aktivieren
   - Screenshots von Fahrten machen
   - Deaktivieren vor Produktion

2. **Review Notes schreiben:**
   ```
   Test-Anleitung:
   1. Öffne App
   2. Gehe zu Settings
   3. Aktiviere "Demo-Modus" (Toggle ganz oben)
   4. Zurück zu "Fahrten"
   5. "Fahrt starten" → App verwendet simulierte Daten
   6. "Fahrt beenden" → Fahrt wird gespeichert

   Demo-Modus ermöglicht vollständigen Test ohne
   Home Assistant Server oder Fahrzeug.
   ```

3. **Kurzbefehle-Integration erklären:**
   ```
   URL Schemes:
   - fahrtenbuch://start
   - fahrtenbuch://end

   Verwendung: Integration mit iOS Kurzbefehle-App
   für automatischen Trip-Start bei Bluetooth-Verbindung.

   Dokumentation: In-App verfügbar (Settings → Dokumentation)
   ```

4. **Widget:**
   ```
   Home Screen Widget:
   - Schnellzugriff auf Trip-Status
   - "Fahrt starten" Button direkt vom Home Screen
   - Live-Anzeige aktiver Fahrten

   Widget ist optional - App funktioniert auch ohne.
   ```

---

## Testing Checklist

### Basis-Funktionen:
- [ ] Build erfolgreich (alle Dateien hinzugefügt)
- [ ] Demo-Modus: Fahrt starten/beenden
- [ ] Export-Funktion (Monatsabrechnung)
- [ ] Settings: Alle Werte änderbar

### Kurzbefehle:
- [ ] URL `fahrtenbuch://start` öffnet App + startet Fahrt
- [ ] URL `fahrtenbuch://end` beendet aktive Fahrt
- [ ] Kurzbefehle-Automation erstellt (Bluetooth)
- [ ] Test mit echtem Auto

### Debug-Logging:
- [ ] Toggle aktivieren → Fahrt starten
- [ ] Log zeigt Einträge (alle 30s)
- [ ] Export funktioniert (CSV-Datei)

### Widget:
- [ ] Widget Extension erstellt
- [ ] App Groups konfiguriert
- [ ] Widget auf Home Screen platziert
- [ ] Widget zeigt "Fahrt starten" Button
- [ ] Fahrt starten → Widget zeigt aktive Fahrt
- [ ] Dauer aktualisiert sich automatisch (alle 60s)
- [ ] Fahrt beenden → Widget zeigt wieder "starten"

---

## Bekannte Einschränkungen

### Widget Setup-Komplexität:
Widget Extension muss manuell in Xcode erstellt werden - kann nicht per Code generiert werden.

**Lösung:**
- Ausführliche Schritt-für-Schritt Anleitung in `DOCS/widget-setup.md`
- Widget ist optional - App funktioniert auch ohne

### App Groups Requirement:
Widget benötigt App Groups für Datenaustausch mit Haupt-App.

**Lösung:**
- App Groups werden in Signing & Capabilities aktiviert
- Automatisch im Provisioning Profile enthalten

---

## Nächste Schritte

1. **Heute:**
   - [ ] Dateien zu Xcode hinzufügen (DeepLinkHandler, TripDebugLogger, WidgetDataService)
   - [ ] Widget Extension erstellen (siehe widget-setup.md)
   - [ ] App Groups konfigurieren
   - [ ] Build testen
   - [ ] Kurzbefehle-Automation erstellen (eigenes iPhone)

2. **Diese Woche:**
   - [ ] Mit echtem Auto testen (Bluetooth-Automation)
   - [ ] Debug-Log einer echten Fahrt sammeln (API-Update-Frequenz messen)
   - [ ] Widget auf Home Screen testen

3. **Vor Release:**
   - [ ] Screenshots mit Demo-Modus machen
   - [ ] Widget-Screenshots für App Store
   - [ ] App Store Beschreibung schreiben
   - [ ] Review-Notes vorbereiten (mit Widget-Hinweis)

---

**Fragen? Siehe Dokumentation in DOCS/ oder öffne GitHub Issue.**
