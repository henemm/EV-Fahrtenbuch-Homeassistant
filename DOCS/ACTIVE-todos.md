# Active Todos

> Zentraler Einstiegspunkt fuer alle aktiven Bugs und Tasks.
>
> **Regel:** Nach JEDEM Fix hier aktualisieren!

---

## Offene Bugs

**Bug 1: Lock Screen LiveActivity Timer zeigt statischen Wert**
- Location: FahrtenbuchWidget/FahrtenbuchWidget.swift:89-147
- Problem: Timer auf Lock Screen aktualisiert sich nicht (zeigt nur initialen Wert)
- Expected: Timer sollte wie im Dynamic Island hochzaehlen
- Root Cause: UNBEKANNT - identischer Code funktioniert im Dynamic Island
- Test: Fahrt starten, Lock Screen beobachten
- Status: OFFEN (seit v1.0.3, mehrere Loesungsversuche fehlgeschlagen)

_Keine offenen Bugs (ausser Bug 1 - Lock Screen Timer)_

### UI Test Checkliste - Bug 2 Fix verifizieren (manuell)

**Bitte testen:**
- [ ] App starten
- [ ] Bestehenden Trip in Liste antippen
- [ ] Titel zeigt "Fahrt bearbeiten"
- [ ] Formular zeigt die Werte des angeklickten Trips
- [ ] Wert aendern und speichern
- [ ] Trip in Liste zeigt aktualisierte Werte
- [ ] Kein neuer Trip wurde erstellt
- [ ] "+" Button oben rechts oeffnet "Fahrt erstellen" (Create-Modus funktioniert noch)

---

## Offene Tasks

_Keine offenen Tasks_

---

## Zuletzt erledigt

**Bug 2 Fix:** Edit Trip verwendet jetzt `.sheet(item:)` statt `.sheet(isPresented:)`
- Root Cause: State timing issue - tripToEdit wurde gesetzt aber sheet content wurde vor Propagierung evaluiert
- Fix: Separate Sheets fuer Create (isPresented) und Edit (item:)
- Unit Tests: 4 Tests in EditTripViewTests.swift (alle gruen)

**v1.0.5:** Picker Wheel fuer Offline-Batterie-Eingabe mit intelligentem Default
**v1.0.4:** Core Data Reactivity Fix, ForEach Identity Fix, Swift 6 Concurrency
