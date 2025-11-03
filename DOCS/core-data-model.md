# Core Data Model - Trip Entity

## Entity: Trip

### Attributes

| Attribute | Type | Optional | Default | Beschreibung |
|-----------|------|----------|---------|--------------|
| `id` | UUID | NO | - | Eindeutige ID |
| `startDate` | Date | NO | - | Fahrt-Start (Datum + Uhrzeit) |
| `endDate` | Date | YES | nil | Fahrt-Ende (nil = läuft noch) |
| `startBatteryPercent` | Double | NO | - | Batteriestand Start (0-100) |
| `endBatteryPercent` | Double | YES | nil | Batteriestand Ende |
| `startOdometer` | Double | NO | - | Kilometerstand Start |
| `endOdometer` | Double | YES | nil | Kilometerstand Ende |

### Constraints

- **Unique Constraint:** `id` (verhindert Duplikate)

### Indexes

- Index auf `startDate` (für schnelles Sortieren/Gruppieren)
- Index auf `endDate` (für Filterung abgeschlossener Fahrten)

---

## Setup in Xcode

### 1. Core Data Model öffnen

`Fahrtenbuch.xcdatamodeld` in Xcode öffnen (sollte automatisch erstellt sein)

### 2. Entity "Trip" erstellen

**Unten links:** **Add Entity** Button
- Name: `Trip`

### 3. Attributes hinzufügen

Für jedes Attribute oben:
1. **Add Attribute** Button
2. Name eingeben
3. Type auswählen
4. Optional-Checkbox setzen (falls YES)

**Wichtig:**
- `id`: Type = **UUID**, Optional = **NO**
- Alle `Date` Typen: Type = **Date**
- Alle `Double` Typen: Type = **Double**

### 4. Constraints setzen

1. Entity "Trip" selektieren
2. **Data Model Inspector** (rechts oben) → **Constraints**
3. **+** Button → `id` hinzufügen

### 5. Codegen-Einstellung

Entity "Trip" selektieren → **Data Model Inspector**:
- **Codegen:** Manual/None

**Warum:**
- Wir erstellen die Swift-Klassen manuell (für Extensions und computed properties)
- Xcode generiert sonst automatisch, was wir überschreiben möchten

---

## Computed Properties (in Swift)

Diese Eigenschaften werden in `Trip+CoreDataClass.swift` berechnet:

```swift
extension Trip {
    // Ist die Fahrt aktiv?
    var isActive: Bool {
        endDate == nil
    }

    // Gefahrene Strecke in km
    var distance: Double {
        guard let end = endOdometer else { return 0 }
        return end - startOdometer
    }

    // Batterieverbrauch in %
    var batteryUsed: Double {
        guard let end = endBatteryPercent else { return 0 }
        return startBatteryPercent - end
    }

    // Verbrauch in kWh (basierend auf 77 kWh Batterie)
    func kwhUsed(batteryCapacity: Double = 77.0) -> Double {
        (batteryUsed / 100.0) * batteryCapacity
    }

    // Kosten in €
    func cost(costPerKwh: Double, batteryCapacity: Double = 77.0) -> Double {
        kwhUsed(batteryCapacity: batteryCapacity) * costPerKwh
    }

    // Durchschnittsverbrauch in kWh/100km
    var averageConsumption: Double {
        guard distance > 0 else { return 0 }
        return (kwhUsed() / distance) * 100
    }

    // Dauer der Fahrt in Minuten
    var durationMinutes: Int {
        guard let end = endDate else {
            return Int(Date().timeIntervalSince(startDate) / 60)
        }
        return Int(end.timeIntervalSince(startDate) / 60)
    }
}
```

---

## Fetch Requests (Beispiele)

### Alle abgeschlossenen Fahrten (neueste zuerst)

```swift
let request = Trip.fetchRequest()
request.predicate = NSPredicate(format: "endDate != nil")
request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)]
```

### Aktive Fahrt (läuft gerade)

```swift
let request = Trip.fetchRequest()
request.predicate = NSPredicate(format: "endDate == nil")
request.fetchLimit = 1
```

### Fahrten eines Monats

```swift
let calendar = Calendar.current
let startOfMonth = calendar.date(from: DateComponents(year: 2025, month: 11, day: 1))!
let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

let request = Trip.fetchRequest()
request.predicate = NSPredicate(
    format: "startDate >= %@ AND startDate < %@",
    startOfMonth as NSDate,
    endOfMonth as NSDate
)
request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)]
```

---

## Migration (für zukünftige Schema-Änderungen)

**Wenn neue Attributes hinzugefügt werden:**
1. Xcode → **Editor** → **Add Model Version**
2. Neue Attributes hinzufügen
3. **Current Model Version** setzen (Model Inspector)
4. Core Data migriert automatisch (lightweight migration)

**Wichtig:**
- Niemals existierende Attributes löschen/umbenennen ohne Migration-Code
- Immer nur additive Änderungen (neue Attributes hinzufügen)
- Bei Breaking Changes: Custom Migration schreiben
