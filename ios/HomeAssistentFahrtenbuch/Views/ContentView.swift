//
//  ContentView.swift
//  HomeAssistent Fahrtenbuch
//
//  Root View mit Tab-Navigation
//

import SwiftUI

struct ContentView: View {

    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        TabView {
            // Fahrten
            TripsListView(settings: settings)
                .tabItem {
                    Label("Fahrten", systemImage: "list.bullet")
                }

            // Einstellungen
            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gear")
                }
                .badge(settings.isConfigured ? nil : "!")
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
