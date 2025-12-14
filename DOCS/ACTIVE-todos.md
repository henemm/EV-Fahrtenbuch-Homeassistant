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

**Bug 2: Edit Trip erzeugt neuen Eintrag statt zu aktualisieren**
- Location: TripsListView.swift:141-143, 356-358
- Problem: Tap auf bestehenden Trip oeffnet "Fahrt erstellen" statt "Fahrt bearbeiten"
- Expected: Bestehender Trip wird editiert, nicht neu erstellt
- Root Cause: `.sheet(isPresented:)` captured `tripToEdit` bevor State-Update propagiert
- Fix: Umstellen auf `.sheet(item:)` fuer korrektes Item-Binding
- Unit Test: EditTripViewTests.swift (4 Tests geschrieben)
- Status: TESTS GESCHRIEBEN - wartet auf Fix

### UI Test Checkliste (manuell)

**Vor dem Fix (Bug reproduzieren):**
- [ ] App starten
- [ ] Bestehenden Trip in Liste antippen
- [ ] **BUG:** Titel zeigt "Fahrt erstellen" statt "Fahrt bearbeiten"
- [ ] **BUG:** Formular zeigt Default-Werte statt Trip-Werte

**Nach dem Fix (verifizieren):**
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

**v1.0.5:** Picker Wheel fuer Offline-Batterie-Eingabe mit intelligentem Default
**v1.0.4:** Core Data Reactivity Fix, ForEach Identity Fix, Swift 6 Concurrency
