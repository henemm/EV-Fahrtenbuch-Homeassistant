#!/usr/bin/env python3
"""
Home Assistant API Test für Enyaq Fahrtenbuch
Testet Zugriff auf Batterie- und Kilometerstand
"""

import json
import requests
from datetime import datetime
from pathlib import Path


class HomeAssistantClient:
    """Client für Home Assistant REST API"""

    def __init__(self, config_path="config.json"):
        """Lädt Konfiguration"""
        self.config = self._load_config(config_path)
        self.base_url = self.config["ha_url"].rstrip("/")
        self.headers = {
            "Authorization": f"Bearer {self.config['ha_token']}",
            "Content-Type": "application/json",
        }

    def _load_config(self, config_path):
        """Lädt config.json"""
        path = Path(config_path)
        if not path.exists():
            raise FileNotFoundError(
                f"Config-Datei nicht gefunden: {config_path}\n"
                f"Bitte config.example.json kopieren und anpassen!"
            )
        with open(path) as f:
            return json.load(f)

    def test_connection(self):
        """Testet Verbindung zu Home Assistant"""
        print("Verbinde mit Home Assistant...")
        try:
            response = requests.get(
                f"{self.base_url}/api/",
                headers=self.headers,
                timeout=10
            )
            response.raise_for_status()
            print("✓ Verbindung erfolgreich")
            return True
        except requests.exceptions.RequestException as e:
            print(f"✗ Verbindungsfehler: {e}")
            return False

    def get_entity_state(self, entity_id):
        """Liest aktuellen Zustand einer Entity"""
        try:
            response = requests.get(
                f"{self.base_url}/api/states/{entity_id}",
                headers=self.headers,
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            return {
                "value": data["state"],
                "unit": data.get("attributes", {}).get("unit_of_measurement", ""),
                "last_updated": data["last_updated"],
                "friendly_name": data.get("attributes", {}).get("friendly_name", entity_id)
            }
        except requests.exceptions.RequestException as e:
            print(f"✗ Fehler beim Abrufen von {entity_id}: {e}")
            return None

    def get_vehicle_data(self):
        """Liest alle relevanten Fahrzeug-Daten"""
        battery = self.get_entity_state(self.config["entities"]["battery_level"])
        odometer = self.get_entity_state(self.config["entities"]["odometer"])

        return {
            "timestamp": datetime.now().isoformat(),
            "battery_percent": battery["value"] if battery else None,
            "battery_unit": battery["unit"] if battery else None,
            "odometer_km": odometer["value"] if odometer else None,
            "odometer_unit": odometer["unit"] if odometer else None,
        }

    def simulate_trip(self):
        """Simuliert eine Fahrt (Start + Ende)"""
        print("\n=== Simuliere Fahrt ===")

        print("\n📍 Fahrt START")
        start_data = self.get_vehicle_data()
        self._print_vehicle_data(start_data, "START")

        input("\nDrücke ENTER um Fahrt zu beenden...")

        print("\n🏁 Fahrt ENDE")
        end_data = self.get_vehicle_data()
        self._print_vehicle_data(end_data, "ENDE")

        # Berechne Verbrauch
        self._calculate_trip(start_data, end_data)

        # Speichere Fahrt
        trip = {
            "start": start_data,
            "end": end_data
        }
        self._save_trip(trip)

    def _print_vehicle_data(self, data, label):
        """Gibt Fahrzeugdaten formatiert aus"""
        print(f"  Zeit: {data['timestamp']}")
        print(f"  Batterie: {data['battery_percent']}{data['battery_unit']}")
        print(f"  Kilometerstand: {data['odometer_km']} {data['odometer_unit']}")

    def _calculate_trip(self, start, end):
        """Berechnet Verbrauch und Kosten"""
        try:
            battery_used = float(start["battery_percent"]) - float(end["battery_percent"])
            distance = float(end["odometer_km"]) - float(start["odometer_km"])

            # Verbrauch in kWh
            battery_capacity = self.config.get("battery_capacity_kwh", 77)
            kwh_used = (battery_used / 100) * battery_capacity

            # Kosten
            cost_per_kwh = self.config.get("cost_per_kwh", 0.30)
            total_cost = kwh_used * cost_per_kwh

            print(f"\n📊 Fahrt-Auswertung:")
            print(f"  Strecke: {distance:.1f} km")
            print(f"  Batterieverbrauch: {battery_used:.1f}% ({kwh_used:.2f} kWh)")
            print(f"  Verbrauch: {(kwh_used / distance * 100):.2f} kWh/100km")
            print(f"  Kosten: {total_cost:.2f} €")

        except (ValueError, TypeError) as e:
            print(f"\n⚠️  Konnte Verbrauch nicht berechnen: {e}")

    def _save_trip(self, trip):
        """Speichert Fahrt in JSON"""
        trips_file = Path("trips.json")

        # Lade bestehende Fahrten
        trips = []
        if trips_file.exists():
            with open(trips_file) as f:
                trips = json.load(f)

        # Füge neue Fahrt hinzu
        trips.append(trip)

        # Speichere
        with open(trips_file, "w") as f:
            json.dump(trips, f, indent=2)

        print(f"\n💾 Fahrt gespeichert in {trips_file}")


def main():
    """Haupt-Funktion"""
    print("=== Enyaq Fahrtenbuch - Home Assistant API Test ===\n")

    # Client initialisieren
    try:
        client = HomeAssistantClient()
    except FileNotFoundError as e:
        print(f"\n❌ {e}")
        return

    # Verbindung testen
    if not client.test_connection():
        return

    # Aktuelle Daten abrufen
    print("\n=== Aktuelle Fahrzeugdaten ===")
    data = client.get_vehicle_data()
    print(f"Batterie: {data['battery_percent']}{data['battery_unit']}")
    print(f"Kilometerstand: {data['odometer_km']} {data['odometer_unit']}")

    # Menü
    print("\n=== Optionen ===")
    print("1. Fahrt simulieren (Start → Ende)")
    print("2. Nur aktuelle Daten anzeigen")
    print("3. Beenden")

    choice = input("\nWahl (1-3): ").strip()

    if choice == "1":
        client.simulate_trip()
    elif choice == "2":
        # Bereits oben angezeigt
        pass
    else:
        print("Beendet.")


if __name__ == "__main__":
    main()
