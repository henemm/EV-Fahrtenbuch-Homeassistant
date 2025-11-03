#!/usr/bin/env python3
"""
Schneller Test - zeigt nur aktuelle Fahrzeugdaten
(Nicht-interaktiv, gut für automatisierte Tests)
"""

import json
import requests
from datetime import datetime
from pathlib import Path


def load_config():
    """Lädt config.json"""
    with open("config.json") as f:
        return json.load(f)


def get_entity_state(config, entity_id):
    """Liest aktuellen Zustand einer Entity"""
    base_url = config["ha_url"].rstrip("/")
    headers = {
        "Authorization": f"Bearer {config['ha_token']}",
        "Content-Type": "application/json",
    }

    response = requests.get(
        f"{base_url}/api/states/{entity_id}",
        headers=headers,
        timeout=10
    )
    response.raise_for_status()
    data = response.json()

    return {
        "value": data["state"],
        "unit": data.get("attributes", {}).get("unit_of_measurement", ""),
        "friendly_name": data.get("attributes", {}).get("friendly_name", entity_id),
        "last_updated": data["last_updated"]
    }


def main():
    """Haupt-Funktion"""
    print("🚗 Enyaq Fahrtenbuch - Quick Test\n")

    # Config laden
    config = load_config()

    # Daten abrufen
    battery = get_entity_state(config, config["entities"]["battery_level"])
    odometer = get_entity_state(config, config["entities"]["odometer"])

    # Ausgabe
    print(f"📊 Aktuelle Fahrzeugdaten:")
    print(f"  🔋 Batterie: {battery['value']}{battery['unit']}")
    print(f"  📍 Kilometerstand: {odometer['value']} {odometer['unit']}")
    print(f"  🕐 Letztes Update: {battery['last_updated']}")
    print()

    # Potentielle Fahrt berechnen (Beispiel)
    battery_capacity = config.get("battery_capacity_kwh", 77)
    cost_per_kwh = config.get("cost_per_kwh", 0.30)

    # Beispiel: 20% Verbrauch
    example_usage_percent = 20
    example_kwh = (example_usage_percent / 100) * battery_capacity
    example_cost = example_kwh * cost_per_kwh

    print(f"💡 Beispiel-Berechnung (20% Verbrauch):")
    print(f"  Verbrauch: {example_kwh:.2f} kWh")
    print(f"  Kosten: {example_cost:.2f} €")
    print(f"  (bei {cost_per_kwh:.2f} €/kWh)")


if __name__ == "__main__":
    try:
        main()
    except FileNotFoundError:
        print("❌ config.json nicht gefunden!")
    except requests.exceptions.RequestException as e:
        print(f"❌ API-Fehler: {e}")
    except Exception as e:
        print(f"❌ Fehler: {e}")
