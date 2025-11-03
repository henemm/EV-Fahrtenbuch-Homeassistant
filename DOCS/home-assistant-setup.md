# Home Assistant Setup - Token & Entity IDs abrufen

## 1. Langlebigen Zugriffstoken erstellen

**Schritt-für-Schritt:**

1. Öffne deine Home Assistant Instanz im Browser (z.B. `https://deine-instanz.ui.nabu.casa`)
2. Klicke unten links auf deinen **Benutzernamen** (Avatar)
3. Scrolle runter zum Bereich **"Sicherheit"**
4. Unter **"Langlebige Zugriffstoken"** klicke auf **"Token erstellen"**
5. Gib einen Namen ein (z.B. "Fahrtenbuch App")
6. **WICHTIG:** Kopiere den Token SOFORT und speichere ihn sicher!
   - Der Token wird nur EINMAL angezeigt
   - Du kannst ihn nicht später nochmal abrufen

**Token-Format:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (sehr langer String)

---

## 2. Entity IDs vom Enyaq finden

**Methode 1 - Über Developer Tools (empfohlen):**

1. In Home Assistant: Öffne **Einstellungen** → **Geräte & Dienste**
2. Suche nach **"Škoda"** oder **"Enyaq"**
3. Klicke auf das Gerät → Zeigt alle verfügbaren Entities an
4. Notiere dir die Entity-IDs für:
   - Batteriestand: z.B. `sensor.enyaq_battery_level` oder `sensor.skoda_enyaq_battery_level`
   - Kilometerstand: z.B. `sensor.enyaq_odometer` oder `sensor.skoda_enyaq_mileage`

**Methode 2 - Über Developer Tools > Zustände:**

1. In Home Assistant: **Developer Tools** → **Zustände**
2. Suche nach "enyaq" oder "skoda"
3. Alle Entities mit aktuellem Wert werden angezeigt
4. Kopiere die Entity-IDs, die du brauchst

---

## 3. Konfiguration für Prototyp

Erstelle die Datei `prototype/config.json` (siehe `config.example.json` als Vorlage):

```json
{
  "ha_url": "https://deine-instanz.ui.nabu.casa",
  "ha_token": "DEIN_LANGLEBIGER_TOKEN",
  "entities": {
    "battery_level": "sensor.enyaq_battery_level",
    "odometer": "sensor.enyaq_odometer"
  }
}
```

**Hinweise:**
- `ha_url`: Deine Home Assistant Cloud URL (OHNE `/api` am Ende)
- `ha_token`: Der langlebige Token aus Schritt 1
- `entities`: Die exakten Entity-IDs aus Schritt 2

---

## 4. Test-Befehle

**Installation der Abhängigkeiten:**
```bash
cd prototype
pip install requests
```

**Prototyp ausführen:**
```bash
python ha_api_test.py
```

**Erwartete Ausgabe:**
```
Verbinde mit Home Assistant...
✓ Verbindung erfolgreich
Batterie: 87%
Kilometerstand: 12543 km
```
