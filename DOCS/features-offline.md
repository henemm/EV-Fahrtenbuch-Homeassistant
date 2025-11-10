# Feature: Offline-Modus - Nur Batterie% erforderlich

**Status:** Geplant
**Version:** 1.0.6
**Erstellt:** 2025-11-10

---

## Problem

**Aktuell:**
- Start/Ende-Fahrt schlägt fehl wenn kein Netz vorhanden (API-Call zu Home Assistant nicht möglich)
- Manuelle Fahrt-Erstellung verlangt km-Stand als Pflichtfeld
- User kann Fahrt verlieren wenn in Tiefgarage ohne Empfang gestartet/beendet

**User Story:**
> Als User möchte ich eine Fahrt auch ohne Internetverbindung starten/beenden können, indem ich nur den Batteriestand manuell eingebe, damit ich keine Fahrten verliere wenn ich in einer Tiefgarage ohne Empfang bin.

---

## Lösung

### Konzept

**Offline-Erkennung:** Automatisch wenn API-Call fehlschlägt

**Fallback-Strategie:**
1. API-Call schlägt fehl → Alert für manuelle Eingabe
2. User gibt nur Batterie% ein (0-100)
3. km-Stand wird als 0 gespeichert
4. **Keine Sync-Versuche** - User-Eingabe ist final
5. **Keine Störung** während der Fahrt

**Konsequenzen bei km=0:**
- `Trip.distance` = 0 (bereits safe implementiert)
- `Trip.averageConsumption` = 0 (guard in place)
- `Trip.cost()` funktioniert normal (nur Batterie% nötig)

---

## Implementierung

### 1. EditTripView.swift - km-Stand optional

**File:** `HomeAssistentFahrtenbuch/Views/EditTripView.swift`

#### Änderung 1: `isValid` Validation (Zeilen ~187-206)

**Vorher:**
```swift
private var isValid: Bool {
    guard let startBattery = Double(startBatteryPercent),
          let endBattery = Double(endBatteryPercent),
          let startKm = Double(startOdometer),
          let endKm = Double(endOdometer) else {
        return false
    }

    guard endDate > startDate else { return false }
    guard startBattery >= 0 && startBattery <= 100 else { return false }
    guard endBattery >= 0 && endBattery <= 100 else { return false }
    guard startKm > 0 && endKm > startKm else { return false }

    return true
}
```

**Nachher:**
```swift
private var isValid: Bool {
    // Batterie ist PFLICHT
    guard let startBattery = Double(startBatteryPercent),
          let endBattery = Double(endBatteryPercent) else {
        return false
    }

    // Datum-Validierung
    guard endDate > startDate else { return false }

    // Batterie-Validierung
    guard startBattery >= 0 && startBattery <= 100 else { return false }
    guard endBattery >= 0 && endBattery <= 100 else { return false }

    // Odometer-Validierung (OPTIONAL - nur wenn beide angegeben)
    if !startOdometer.isEmpty && !endOdometer.isEmpty {
        guard let startKm = Double(startOdometer),
              let endKm = Double(endOdometer),
              startKm >= 0,
              endKm > startKm else {
            return false
        }
    }

    return true
}
```

#### Änderung 2: `calculatePreview()` Funktion (Zeilen ~217-236)

```swift
private func calculatePreview() -> PreviewData? {
    guard let startBattery = Double(startBatteryPercent),
          let endBattery = Double(endBatteryPercent) else {
        return nil
    }

    guard isValid else { return nil }

    // Dauer
    let duration = endDate.timeIntervalSince(startDate)
    let hours = Int(duration / 3600)
    let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
    let durationString = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"

    // Strecke (OPTIONAL - nur wenn angegeben)
    let distance: Double
    if let startKm = Double(startOdometer),
       let endKm = Double(endOdometer) {
        distance = endKm - startKm
    } else {
        distance = 0
    }

    // Batterie
    let batteryUsed = startBattery - endBattery

    // Kosten
    let month = Calendar.current.component(.month, from: startDate)
    let costPerPercent = (month < 4 || month > 10)
        ? settings.costPerPercentWinter
        : settings.costPerPercentSummer
    let cost = batteryUsed * costPerPercent

    return PreviewData(
        duration: durationString,
        distance: distance,
        batteryUsed: batteryUsed,
        cost: cost
    )
}
```

#### Änderung 3: Save-Funktion

```swift
private func saveTrip() {
    // ... Validation ...

    let startKm = Double(startOdometer) ?? 0.0  // Leer → 0
    let endKm = Double(endOdometer) ?? 0.0      // Leer → 0

    if let trip = trip {
        // Edit existing
        viewModel.updateTrip(
            trip,
            startDate: startDate,
            endDate: endDate,
            startBatteryPercent: startBattery,
            endBatteryPercent: endBattery,
            startOdometer: startKm,
            endOdometer: endKm
        )
    } else {
        // Create new
        viewModel.createManualTrip(
            startDate: startDate,
            endDate: endDate,
            startBatteryPercent: startBattery,
            endBatteryPercent: endBattery,
            startOdometer: startKm,
            endOdometer: endKm
        )
    }
}
```

---

### 2. TripsViewModel.swift - Offline-Fallback

**File:** `HomeAssistentFahrtenbuch/ViewModels/TripsViewModel.swift`

#### Neue Properties

```swift
@Published var showManualInputAlert = false
@Published var manualInputContext: ManualInputContext?

enum ManualInputContext {
    case startTrip
    case endTrip
}
```

#### startTrip() erweitern

```swift
func startTrip() async {
    // ... existing code ...

    do {
        // ... existing API call ...
    } catch {
        // Offline oder API-Fehler → Manuelle Eingabe
        errorMessage = nil  // Kein Fehler anzeigen
        manualInputContext = .startTrip
        showManualInputAlert = true
    }

    isLoading = false
}
```

#### Neue Funktion: startTripManually

```swift
func startTripManually(batteryPercent: Double) {
    let trip = Trip(context: viewContext)
    trip.id = UUID()
    trip.startDate = Date()
    trip.startBatteryPercent = batteryPercent
    trip.startOdometer = 0  // Kein km-Stand bei Offline
    trip.endDate = nil
    trip.endBatteryPercent = 0
    trip.endOdometer = 0

    do {
        try viewContext.save()
        activeTrip = trip

        // Widget aktualisieren
        widgetService.updateWidget(with: trip)

        // LiveActivity starten (iOS 16.1+)
        if #available(iOS 16.1, *),
           let manager = liveActivityManager as? LiveActivityManager {
            manager.startActivity(for: trip)
        }
    } catch {
        errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
    }
}
```

#### endTrip() erweitern

```swift
func endTrip() async {
    // ... existing code ...

    do {
        // ... existing API call ...
    } catch {
        // Offline oder API-Fehler → Manuelle Eingabe
        errorMessage = nil
        manualInputContext = .endTrip
        showManualInputAlert = true
    }

    isLoading = false
}
```

#### Neue Funktion: endTripManually

```swift
func endTripManually(batteryPercent: Double) {
    guard let trip = activeTrip else { return }

    trip.endDate = Date()
    trip.endBatteryPercent = batteryPercent
    trip.endOdometer = trip.startOdometer  // Kein Delta bei Offline

    do {
        try viewContext.save()
        activeTrip = nil

        // Widget aktualisieren
        widgetService.updateWidget(with: nil)

        // LiveActivity beenden (iOS 16.1+)
        if #available(iOS 16.1, *),
           let manager = liveActivityManager as? LiveActivityManager {
            manager.endActivity()
        }
    } catch {
        errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
    }
}
```

---

### 3. TripsListView.swift - Manual Input Alert

**File:** `HomeAssistentFahrtenbuch/Views/TripsListView.swift`

#### Neue State

```swift
@State private var manualBatteryInput = ""
```

#### Alert Modifier

```swift
.alert("Keine Verbindung", isPresented: $viewModel.showManualInputAlert) {
    TextField("Batterie %", text: $manualBatteryInput)
        .keyboardType(.decimalPad)

    Button("Abbrechen", role: .cancel) {
        manualBatteryInput = ""
    }

    Button(viewModel.manualInputContext == .startTrip ? "Fahrt starten" : "Fahrt beenden") {
        guard let battery = Double(manualBatteryInput),
              battery >= 0 && battery <= 100 else {
            // Validation fehlgeschlagen
            viewModel.errorMessage = "Batterie muss zwischen 0 und 100% sein"
            manualBatteryInput = ""
            return
        }

        if viewModel.manualInputContext == .startTrip {
            viewModel.startTripManually(batteryPercent: battery)
        } else {
            viewModel.endTripManually(batteryPercent: battery)
        }

        manualBatteryInput = ""
    }
    .disabled(manualBatteryInput.isEmpty)
} message: {
    Text("Bitte gib den aktuellen Batteriestand ein:")
}
```

---

## Testing

### Manuelle Tests

1. **Offline Start-Trip:**
   - Flugmodus aktivieren
   - "Fahrt starten" drücken
   - Alert erscheint → Batterie% eingeben (z.B. 80)
   - Trip wird erstellt mit odometer=0

2. **Offline End-Trip:**
   - Flugmodus aktivieren
   - "Fahrt beenden" drücken
   - Alert erscheint → Batterie% eingeben (z.B. 60)
   - Trip wird beendet mit odometer=startOdometer

3. **Validation:**
   - Batterie > 100 → Fehlermeldung
   - Batterie < 0 → Fehlermeldung
   - Leeres Feld → Button disabled

4. **km-Stand optional in EditTripView:**
   - "Fahrt erstellen" öffnen
   - Nur Batterie-Werte eingeben, km-Felder leer lassen
   - Speichern muss funktionieren
   - Trip hat distance=0, averageConsumption=0

---

## Edge Cases

### Was passiert bei distance=0?

**TripRowView / TripsListView:**
- Zeigt "0 km" an (kein Problem)
- Zeigt "0.0 kWh/100km" Verbrauch (bereits safe)

**MonthlySummary:**
- totalDistance = 0 für diesen Trip
- averageConsumption wird korrekt berechnet (nur Trips mit distance>0)

**Export / Abrechnung:**
- cost() funktioniert normal (nur Batterie% nötig)
- distance kann 0 sein (kein Problem für Abrechnung)

### Was ist mit bestehenden Trips?

Alle bestehenden Trips haben odometer > 0, da sie via API erstellt wurden. Keine Migration nötig.

---

## Open Questions

**Keine** - Feature ist vollständig spezifiziert.

---

## Changelog

**2025-11-10:** Initial spec erstellt
