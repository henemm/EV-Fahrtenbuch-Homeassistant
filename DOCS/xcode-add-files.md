# Neue Dateien zu Xcode hinzufügen

## Problem gelöst: NSManagedObject + Neues Abrechnungsmodell

### ✅ Was behoben wurde:

1. **Core Data Fehler** ("An NSManagedObject of class 'Trip' must have a valid NSEntityDescription")
   - `@objc(Trip)` entfernt aus Trip+CoreDataClass.swift
   - Besseres Debug-Logging in PersistenceController

2. **Neues Abrechnungsmodell** (Batterie-Prozent statt kWh):
   - **Winter-Tarif** (Nov-März): 0,40 € pro Batterie-%
   - **Sommer-Tarif** (Apr-Okt): 0,20 € pro Batterie-%
   - Automatische Tarif-Erkennung basierend auf Fahrt-Datum
   - Anpassbar in Settings

3. **Export-Funktion** für Monatsabrechnung:
   - CSV-Export (für Excel)
   - Text-Report (übersichtliche Abrechnung)
   - Share-Button im Monats-Header

### 📦 Neue Dateien (müssen zu Xcode hinzugefügt werden):

1. `ViewModels/ExportService.swift` - Export-Logik
2. `Views/Components/ActivityViewController.swift` - Share Sheet

## Xcode: Neue Dateien hinzufügen

**In Xcode:**

1. **Project Navigator** öffnen (⌘ + 1)

2. Rechtsklick auf **"HomeAssistentFahrtenbuch"** Ordner
   → **"Add Files to HomeAssistentFahrtenbuch..."**

3. Navigiere zu: `ios/HomeAssistentFahrtenbuch/ViewModels/`
   → Wähle **ExportService.swift**
   → ✓ Copy items if needed: **NEIN** (schon am richtigen Ort)
   → ✓ Create groups
   → Add

4. Rechtsklick auf **"Views/Components"** Ordner
   → **"Add Files to HomeAssistentFahrtenbuch..."**
   → Navigiere zu: `ios/HomeAssistentFahrtenbuch/Views/Components/`
   → Wähle **ActivityViewController.swift**
   → ✓ Copy items if needed: **NEIN**
   → ✓ Create groups
   → Add

5. **Build** (⌘ + B) → sollte jetzt erfolgreich sein

---

## Neue Features testen

### 1. Abrechnung nach Batterie-Prozent

**In der App:**
- Settings → **Abrechnung**-Sektion
- Siehst du: Winter-Tarif (0,40 €/%) und Sommer-Tarif (0,20 €/%)
- Anpassbar für deine Bedürfnisse

**Bei jeder Fahrt:**
- Zeigt Verbrauch in **Batterie-%** (nicht mehr kWh)
- Zeigt Tarif: "Winter: 0,40 €/%" oder "Sommer: 0,20 €/%"
- Kosten = Batterie-% × Tarif

### 2. Monatsabrechnung exportieren

**In Fahrten-Liste:**
- Bei jedem Monat siehst du oben rechts ein **Export-Icon** (Pfeil nach oben)
- Klick darauf → Share Sheet öffnet sich
- Wähle:
  - **"Save to Files"** → Speichert CSV + TXT
  - **"Mail"** → Verschickt Abrechnung per E-Mail
  - **"WhatsApp"** → Teilt Abrechnung

**Dateien:**
- `Abrechnung_XXX.txt` - Übersichtliche Text-Abrechnung
- `Fahrtenbuch_XXX.csv` - Excel-kompatibel

---

## Vorschlag: Weitere Verbesserungen

### Sofort umsetzbar:
- [ ] "Abrechnung senden an..." Button (direkt E-Mail an feste Adresse)
- [ ] Monatliches Limit einstellen (warnt wenn überschritten)
- [ ] Notiz-Feld pro Fahrt (z.B. "Einkauf", "Zur Arbeit")

### Später:
- [ ] Automatische Kategorisierung (Wochentag → Arbeit, Wochenende → Privat)
- [ ] Jahres-Übersicht mit Chart
- [ ] PDF-Export mit Logo/Header

Welche Features wären für deinen Sohn am hilfreichsten?
