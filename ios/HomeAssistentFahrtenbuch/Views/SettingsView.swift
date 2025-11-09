//
//  SettingsView.swift
//  HomeAssistent Fahrtenbuch
//
//  Einstellungen-Screen
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                // Demo-Modus (für App Store Review)
                Section {
                    Toggle(isOn: $settings.demoMode) {
                        Label("Demo-Modus", systemImage: "wand.and.stars")
                    }
                    .tint(.purple)

                    if settings.demoMode {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.purple)
                            Text("App verwendet simulierte Daten")
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Testing")
                } footer: {
                    Text("Im Demo-Modus werden keine echten API-Calls durchgeführt. Ideal für App Store Review oder Screenshots.")
                        .font(.caption)
                }

                // Home Assistant
                Section {
                    TextField("URL", text: $settings.homeAssistantURL)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    SecureField("Token", text: $settings.homeAssistantToken)
                        .textContentType(.password)

                    TextField("Batterie Entity-ID", text: $settings.batteryEntityId)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    TextField("Kilometerstand Entity-ID", text: $settings.odometerEntityId)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                } header: {
                    Label("Home Assistant", systemImage: "house.fill")
                } footer: {
                    Text("Siehe Dokumentation für Details zum Token und den Entity-IDs")
                        .font(.caption)
                }

                // Verbindungstest
                Section {
                    Button {
                        Task {
                            await viewModel.testConnection()
                        }
                    } label: {
                        HStack {
                            if viewModel.isTestingConnection {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "network")
                            }

                            Text("Verbindung testen")
                        }
                    }
                    .disabled(!viewModel.canTestConnection || viewModel.isTestingConnection)

                    // Test-Ergebnis
                    if let result = viewModel.connectionTestResult {
                        switch result {
                        case .success(let data):
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Verbindung erfolgreich", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)

                                HStack {
                                    Text("Batterie:")
                                    Spacer()
                                    Text("\(Int(data.batteryPercent))%")
                                        .fontWeight(.semibold)
                                }

                                HStack {
                                    Text("Kilometerstand:")
                                    Spacer()
                                    Text("\(Int(data.odometerKm)) km")
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.subheadline)

                        case .failure(let error):
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.subheadline)
                        }
                    }
                }

                // Abrechnungs-Einstellungen
                Section {
                    TextField("Fahrzeugname", text: $settings.vehicleName)

                    HStack {
                        Text("Winter-Tarif")
                        Spacer()
                        TextField("€/%", value: $settings.costPerPercentWinter, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("€/%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Sommer-Tarif")
                        Spacer()
                        TextField("€/%", value: $settings.costPerPercentSummer, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("€/%")
                            .foregroundStyle(.secondary)
                    }

                } header: {
                    Label("Abrechnung", systemImage: "eurosign.circle.fill")
                } footer: {
                    Text("Winter (Nov-März): \(String(format: "%.2f", settings.costPerPercentWinter)) € pro Batterie-Prozent\nSommer (Apr-Okt): \(String(format: "%.2f", settings.costPerPercentSummer)) € pro Batterie-Prozent")
                        .font(.caption)
                }

                // Gefährliche Aktionen
                Section {
                    Button(role: .destructive) {
                        viewModel.resetSettings()
                    } label: {
                        Label("Alle Einstellungen zurücksetzen", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Gefährliche Aktionen")
                } footer: {
                    Text("Setzt alle Einstellungen auf Standardwerte zurück. Fahrten bleiben erhalten.")
                        .font(.caption)
                }

                // Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Dokumentation", systemImage: "book.fill")
                    }
                } header: {
                    Text("Über")
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    SettingsView()
}
