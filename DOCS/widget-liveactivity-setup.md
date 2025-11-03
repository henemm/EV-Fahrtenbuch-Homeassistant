# Widget + LiveActivity Setup

**iOS 18 | Swift 6 | Liquid Glass Design**

---

## Übersicht

Die App bietet **BEIDE** Features:
1. **Home Screen Widget** - Schnellzugriff zum Starten
2. **LiveActivity** - Immer sichtbar während Fahrt (Lock Screen + Dynamic Island)

**Keine Code-Duplikation:** Beide nutzen Shared Models.

---

## Features

### Widget (Home Screen)

**Ohne aktive Fahrt:**
```
┌──────────────┐
│      🚗      │
│   Fahrt      │
│  starten     │
└──────────────┘
```

**Mit aktiver Fahrt:**
```
┌──────────────┐
│ 🚗 Fahrt läuft│
├──────────────┤
│ ⏱️ 01:23:45   │
│ 🔋 66% Start  │
│ 🛣️ 49230 km  │
└──────────────┘
```

---

### LiveActivity (Lock Screen)

**Automatisch während Fahrt:**
```
┌─────────────────────────────┐
│ 🚗 Fahrt läuft              │
│                             │
│ ⏱️ 01:23:45  🔋 66%         │
│ 🛣️ 49230 km                │
└─────────────────────────────┘
```

**Dynamic Island (iPhone 14 Pro+):**
```
Kompakt:  🚗 1h 23m
Minimal:  🚗
Erweitert: Volle Statistiken
```

---

## Architektur (Wartbar!)

### Shared Code (KEINE Duplikation!)

**Gemeinsame Models:**
```
FahrtenbuchWidget/
├── Models/
│   └── TripActivityAttributes.swift
│       ├── TripActivityAttributes (LiveActivity)
│       ├── TripInfo (Shared Data)
│       └── TripDataProvider (Shared Logic)
```

**Beide nutzen gleichen Code:**
- Widget → `TripDataProvider.loadActiveTripInfo()`
- LiveActivity → `TripActivityAttributes`

**Vorteil:**
- Änderung nur an EINER Stelle
- Konsistente Daten
- Weniger Code

---

## Setup in Xcode

### Schritt 1: Widget Extension erstellen

**File → New → Target → Widget Extension**

**Konfiguration:**
- Name: `FahrtenbuchWidget`
- **Include Configuration Intent:** ❌ NEIN
- **Activate:** Ja

**Xcode erstellt:**
- `FahrtenbuchWidget/` Ordner
- Generierter Code (den wir ersetzen)

---

### Schritt 2: Code-Dateien ersetzen

**Lösche generierte Dateien:**
- `FahrtenbuchWidget.swift` → BEHALTEN, aber Inhalt ersetzen
- `AppIntent.swift` → LÖSCHEN
- `Assets.xcassets` → BEHALTEN

**Füge NEUE Dateien hinzu:**

```
FahrtenbuchWidget/
├── FahrtenbuchWidget.swift (bereits vorhanden, Code ersetzen)
├── Models/
│   └── TripActivityAttributes.swift (NEU)
├── Views/
│   ├── TripWidgetView.swift (NEU)
│   └── TripLiveActivityView.swift (NEU)
└── Providers/
    └── TripWidgetProvider.swift (NEU)
```

**Alle neuen Dateien sind bereits erstellt:**
- Pfad: `ios/FahrtenbuchWidget/...`
- Musst du nur zu Xcode-Projekt hinzufügen!

---

### Schritt 3: App Groups konfigurieren

**BEIDE Targets brauchen gleichen App Group!**

#### A) Haupt-App

1. Target: **HomeAssistentFahrtenbuch**
2. **Signing & Capabilities**
3. **+ Capability** → **App Groups**
4. **+** → `group.henemm.fahrtenbuch`
5. ✅ Aktivieren

#### B) Widget Extension

1. Target: **FahrtenbuchWidget**
2. **Signing & Capabilities**
3. **+ Capability** → **App Groups**
4. ✅ `group.henemm.fahrtenbuch` aktivieren

**WICHTIG:** Exakt gleicher Name in beiden!

---

### Schritt 4: Neue Haupt-App Services hinzufügen

**Dateien zu Haupt-App (Target: HomeAssistentFahrtenbuch):**

```
Services/
├── DeepLinkHandler.swift (bereits erstellt)
├── TripDebugLogger.swift (bereits erstellt)
├── WidgetDataService.swift (bereits erstellt, UPDATE!)
└── LiveActivityManager.swift (NEU)
```

**Alle Dateien hinzufügen:**
1. Project Navigator
2. Rechtsklick auf "Services"
3. "Add Files..."
4. **Target Membership:** ✅ HomeAssistentFahrtenbuch

---

## Technische Details

### Moderne APIs (iOS 18 / Swift 6)

**Keine deprecated APIs:**
- ✅ `ActivityKit` (LiveActivity) - Aktuell
- ✅ `WidgetKit` - Aktuell
- ✅ `@available(iOS 18.0, *)` - Version Checks
- ✅ `.containerBackground` - Modern
- ✅ `.ultraThinMaterial` - Liquid Glass

**Liquid Glass Design:**
```swift
.containerBackground(for: .widget) {
    ZStack {
        LinearGradient(
            colors: [.green.opacity(0.05), .green.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(.ultraThinMaterial)
    }
}
```

---

### Auto-Update Strategie

**LiveActivity:**
- Update alle 60 Sekunden (Timer in Haupt-App)
- Dauer wird live berechnet
- Automatisch bei Fahrt-Start/-Ende

**Widget:**
- Update alle 60s während Fahrt
- Alle 15 Min ohne Fahrt
- Timeline-basiert (effizient)

---

## Testing

### Widget testen:

1. Schema: **HomeAssistentFahrtenbuch**
2. Run (⌘+R)
3. Home Screen → Langes Drücken
4. **+** → "Fahrtenbuch" suchen
5. Widget hinzufügen (Small oder Medium)

**Test:**
- Widget zeigt "Fahrt starten"
- Tap → App öffnet sich
- Fahrt starten in App
- Widget aktualisiert sich (zeigt Dauer)

---

### LiveActivity testen:

**Voraussetzung:**
- iPhone mit iOS 18+
- Physisches Gerät (Simulator unterstützt LiveActivity nur eingeschränkt)

**Test:**
1. App starten
2. Fahrt starten
3. → LiveActivity erscheint auf Lock Screen
4. → Dauer aktualisiert sich jede Minute
5. Fahrt beenden
6. → LiveActivity verschwindet

**Dynamic Island (iPhone 14 Pro+):**
- Automatisch in Dynamic Island
- Tap → App öffnet sich

---

## Troubleshooting

### Widget zeigt "Unable to Load"

**Ursache:** App Groups nicht korrekt

**Lösung:**
1. Prüfe: BEIDE Targets haben **exakt gleichen** App Group Namen
2. Prüfe: App Group ist **aktiviert** (✅) in beiden
3. Clean Build (⌘+Shift+K)
4. Rebuild

---

### LiveActivity erscheint nicht

**Ursache 1:** iOS-Version < 18.0

**Lösung:** App erfordert iOS 18.0+ für LiveActivity (Widget funktioniert trotzdem)

**Ursache 2:** `NSSupportsLiveActivities` fehlt

**Lösung:** Prüfe Info.plist enthält:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

**Ursache 3:** Nur Simulator

**Lösung:** Teste auf echtem Gerät (Simulator-Support ist eingeschränkt)

---

### Widget zeigt alte Daten

**Ursache:** Timeline nicht aktualisiert

**Lösung:**
1. Force Quit App
2. Widget entfernen
3. App neu starten
4. Widget neu hinzufügen

---

### Compile-Fehler: "Cannot find TripActivityAttributes"

**Ursache:** Shared Models nicht im Widget Extension Target

**Lösung:**
1. Prüfe: `TripActivityAttributes.swift` ist in **FahrtenbuchWidget/** Ordner
2. Prüfe: Datei ist im **FahrtenbuchWidget** Target (nicht im Haupt-App Target!)
3. Clean Build

---

## Code-Struktur Übersicht

### Haupt-App (HomeAssistentFahrtenbuch)

```swift
// LiveActivityManager.swift
@available(iOS 18.0, *)
final class LiveActivityManager {
    func startActivity(for trip: Trip)
    func endActivity()
    func updateActivity()
}

// WidgetDataService.swift
final class WidgetDataService {
    func updateWidget(with trip: Trip?)
}

// TripsViewModel.swift
class TripsViewModel {
    private var liveActivityManager: LiveActivityManager?

    func startTrip() {
        // ... create trip ...
        liveActivityManager?.startActivity(for: trip)
        widgetService.updateWidget(with: trip)
    }

    func endTrip() {
        // ... end trip ...
        liveActivityManager?.endActivity()
        widgetService.updateWidget(with: nil)
    }
}
```

---

### Widget Extension (FahrtenbuchWidget)

```swift
// Shared Models (KEINE Duplikation!)
struct TripInfo {
    let tripId: UUID
    let startDate: Date
    // ... Computed Properties ...
}

final class TripDataProvider {
    func loadActiveTripInfo() -> TripInfo?
}

// Widget
struct FahrtenbuchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: TripWidgetProvider()
        ) { entry in
            TripWidgetEntryView(entry: entry)
        }
    }
}

// LiveActivity
struct TripLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) {
            TripLiveActivityView(context: $0)
        } dynamicIsland: {
            // Dynamic Island Views
        }
    }
}
```

---

## Zusammenfassung neue Dateien

### Widget Extension (FahrtenbuchWidget Target):

| Datei | Zweck | Status |
|-------|-------|--------|
| `FahrtenbuchWidget.swift` | Bundle + Widgets | ✅ Ersetzt |
| `Models/TripActivityAttributes.swift` | Shared Data | ✅ Neu |
| `Views/TripWidgetView.swift` | Widget UI | ✅ Neu |
| `Views/TripLiveActivityView.swift` | LiveActivity UI | ✅ Neu |
| `Providers/TripWidgetProvider.swift` | Timeline Logic | ✅ Neu |

### Haupt-App (HomeAssistentFahrtenbuch Target):

| Datei | Zweck | Status |
|-------|-------|--------|
| `Services/LiveActivityManager.swift` | LiveActivity Management | ✅ Neu |
| `Services/WidgetDataService.swift` | Widget Data Sharing | ✅ Aktualisiert |
| `Services/DeepLinkHandler.swift` | URL Schemes | ✅ Neu |
| `Services/TripDebugLogger.swift` | Debug Logging | ✅ Neu |
| `ViewModels/TripsViewModel.swift` | Integration | ✅ Aktualisiert |
| `Info.plist` | LiveActivity Support | ✅ Aktualisiert |

---

## App Store Submission

**LiveActivity ist App Store konform!**

**Keine speziellen Genehmigungen nötig:**
- LiveActivities sind für alle Apps verfügbar
- Keine Einschränkungen wie bei CarPlay
- Widget ist Standard-Feature

**Review Notes (optional):**
```
LiveActivity Features:
- Automatische Anzeige während aktiver Fahrt
- Lock Screen + Dynamic Island (iPhone 14 Pro+)
- Kein manuelles Setup nötig

Widget ist optional - App funktioniert vollständig ohne.
```

---

**Bei Problemen:** Siehe GitHub Issues oder öffne Ticket!
