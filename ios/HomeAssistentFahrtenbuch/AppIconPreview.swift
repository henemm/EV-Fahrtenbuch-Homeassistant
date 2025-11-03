//
//  AppIconPreview.swift
//  HomeAssistent Fahrtenbuch
//
//  Temporary file to generate App Icon
//  1. Open in Xcode
//  2. Canvas → Run Preview (⌥⌘↩)
//  3. Right-click Preview → "Export Preview..."
//  4. Save as PNG (1024x1024)
//

import SwiftUI

@available(iOS 17.0, *)
struct AppIconPreview: View {
    var body: some View {
        ZStack {
            // Green Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.8, blue: 0.4),  // Helles Grün
                    Color(red: 0.1, green: 0.6, blue: 0.3)   // Dunkleres Grün
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Car Icon (weiß)
            Image(systemName: "car.fill")
                .font(.system(size: 512, weight: .regular))
                .foregroundStyle(.white)
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 226.9, style: .continuous)) // iOS App Icon Radius
    }
}

@available(iOS 17.0, *)
#Preview("App Icon - 1024x1024") {
    AppIconPreview()
        .frame(width: 1024, height: 1024)
}
