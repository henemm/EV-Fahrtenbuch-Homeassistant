//
//  HomeAssistentFahrtenbuchApp.swift
//  HomeAssistent Fahrtenbuch
//
//  App Entry Point
//

import SwiftUI

@main
struct HomeAssistentFahrtenbuchApp: App {

    let persistenceController = PersistenceController.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(deepLinkHandler)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
                }
        }
    }
}
