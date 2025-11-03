# Kurzbefehle-Integration Setup

## Übersicht

Die Fahrtenbuch-App unterstützt URL Schemes (`fahrtenbuch://start` und `fahrtenbuch://end`), die du mit der **Kurzbefehle-App** kombinieren kannst, um automatisch Fahrten zu starten/beenden, wenn das iPhone sich mit dem Auto verbindet/trennt.

---

## Vorteile

✅ **Automatisch:** Keine manuelle Aktion nötig - iPhone erkennt Bluetooth-Verbindung
✅ **Zuverlässig:** Funktioniert auch wenn App geschlossen ist
✅ **Einfach:** Einmalige Einrichtung, dann vergessen

---

## Setup: Automatische Fahrt-Erkennung

### 1. Bluetooth-Gerät des Autos identifizieren

**So findest du den Namen:**
1. Öffne **Einstellungen** → **Bluetooth**
2. Fahre ins Auto und verbinde dein iPhone
3. Notiere den Namen (z.B. "Enyaq iV", "SKODA Enyaq", etc.)

---

### 2. Automation für "Fahrt starten" erstellen

**In der Kurzbefehle-App:**

1. **Automation** Tab öffnen (unten rechts)
2. **+** (oben rechts) → **Persönliche Automation erstellen**
3. **Bluetooth** auswählen

**Konfiguration:**
- **Gerät:** [Dein Auto] (aus Liste wählen)
- **Verbindung:** ✅ "Beim Verbinden"
- **Weiter**

**Aktion hinzufügen:**
- Suche: "URL öffnen"
- URL: `fahrtenbuch://start`

**Einstellungen:**
- ✅ "Vor Ausführen nicht fragen" aktivieren
- **Fertig**

---

### 3. Automation für "Fahrt beenden" erstellen

**Gleicher Prozess:**

1. **+** → **Persönliche Automation erstellen**
2. **Bluetooth** auswählen

**Konfiguration:**
- **Gerät:** [Dein Auto]
- **Verbindung:** ✅ "Beim Trennen"
- **Weiter**

**Aktion:**
- URL: `fahrtenbuch://end`
- ✅ "Vor Ausführen nicht fragen"
- **Fertig**

---

## Testen

### Test 1: Manuelle Bluetooth-Verbindung
1. Deaktiviere Bluetooth
2. Aktiviere Bluetooth → Auto verbindet sich
3. → Fahrtenbuch-App sollte sich öffnen und Fahrt starten

### Test 2: Im Auto
1. Steige ins Auto (iPhone verbindet sich automatisch)
2. → Fahrt startet
3. Steige aus (Bluetooth trennt sich)
4. → Fahrt endet

---

## Manuelle URL-Verwendung

Du kannst die URLs auch manuell aufrufen (z.B. in Safari):

**Fahrt starten:**
```
fahrtenbuch://start
```

**Fahrt beenden:**
```
fahrtenbuch://end
```

---

## Troubleshooting

### "URL kann nicht geöffnet werden"
→ App ist nicht installiert oder URL Scheme nicht registriert

### Automation wird nicht ausgelöst
→ Prüfe: "Vor Ausführen nicht fragen" ist aktiviert
→ Prüfe: Richtiges Bluetooth-Gerät ausgewählt

### Fahrt startet doppelt
→ Prüfe: Nur EINE Automation für "Verbinden"
→ App verhindert Doppel-Starts automatisch

---

## Weitere Möglichkeiten

### Siri-Integration
"Hey Siri, starte Fahrt" → Kurzbefehl mit `fahrtenbuch://start`

### Widget
Kurzbefehl auf Home-Screen platzieren für manuelles Starten

### Standort-basiert
Alternative: Automation basierend auf "Verlasse Ort" (z.B. Zuhause)

---

## Deaktivieren

Automation deaktivieren:
1. Kurzbefehle-App → **Automation**
2. Automation antippen
3. Toggle oben rechts ausschalten

---

**Bei Problemen:** Debug-Modus in Fahrtenbuch-App aktivieren (Settings → Developer) um zu sehen, wann URLs aufgerufen werden.
