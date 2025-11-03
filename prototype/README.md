# Prototyp: Home Assistant API Test

Dieser Prototyp validiert den Zugriff auf Škoda Enyaq-Daten über die Home Assistant API.

## Setup

### 1. Konfiguration erstellen

```bash
cd prototype
cp config.example.json config.json
```

### 2. Config ausfüllen

Siehe [DOCS/home-assistant-setup.md](../DOCS/home-assistant-setup.md) für detaillierte Anleitung:

- Token in Home Assistant erstellen
- Entity-IDs vom Enyaq finden
- In `config.json` eintragen

### 3. Dependencies installieren

```bash
pip install requests
```

## Verwendung

```bash
python ha_api_test.py
```

**Das Script kann:**
- Verbindung zu Home Assistant testen
- Aktuelle Batterie% und km-Stand abrufen
- Eine Fahrt simulieren (Start → Ende → Kosten berechnen)
- Fahrten in `trips.json` speichern

## Ausgabe-Beispiel

```
=== Enyaq Fahrtenbuch - Home Assistant API Test ===

Verbinde mit Home Assistant...
✓ Verbindung erfolgreich

=== Aktuelle Fahrzeugdaten ===
Batterie: 87%
Kilometerstand: 12543 km

=== Optionen ===
1. Fahrt simulieren (Start → Ende)
2. Nur aktuelle Daten anzeigen
3. Beenden

Wahl (1-3): 1

=== Simuliere Fahrt ===

📍 Fahrt START
  Zeit: 2025-11-02T10:30:00
  Batterie: 87%
  Kilometerstand: 12543 km

Drücke ENTER um Fahrt zu beenden...

🏁 Fahrt ENDE
  Zeit: 2025-11-02T11:15:00
  Batterie: 65%
  Kilometerstand: 12588 km

📊 Fahrt-Auswertung:
  Strecke: 45.0 km
  Batterieverbrauch: 22.0% (16.94 kWh)
  Verbrauch: 37.64 kWh/100km
  Kosten: 5.08 €

💾 Fahrt gespeichert in trips.json
```

## Dateien

- `ha_api_test.py` - Haupt-Script
- `config.json` - Deine Konfiguration (NICHT committen!)
- `config.example.json` - Template für Konfiguration
- `trips.json` - Gespeicherte Test-Fahrten
- `README.md` - Diese Datei

## Fehlerbehebung

**"Config-Datei nicht gefunden":**
→ `config.json` existiert nicht. Kopiere `config.example.json` und fülle sie aus.

**"Verbindungsfehler":**
→ Prüfe `ha_url` und `ha_token` in `config.json`

**"Entity nicht gefunden":**
→ Prüfe Entity-IDs in Home Assistant (siehe Setup-Anleitung)

## Nächste Schritte

Nach erfolgreichem Test:
1. Dokumentiere die exakten Entity-IDs
2. Prüfe Datenqualität (Genauigkeit, Update-Frequenz)
3. Start iOS-Implementierung mit gleicher API-Logik
