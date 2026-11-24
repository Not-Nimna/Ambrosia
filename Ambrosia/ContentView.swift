//
//  ContentView.swift
//  Ambrosia
//
//  Created by Nimna Wijedasa on 2026-11-21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // Bottom nav bar: Home (left), Search (center), Profile (right).
        TabView {
            Tab("Home", systemImage: "house") {
                homeView
            }

            Tab("Search", systemImage: "magnifyingglass") {
                Text("Search")
            }

            Tab("Profile", systemImage: "person") {
                Text("Profile")
            }
        }
    }

    // Placeholder content; replace with data from the fragrance dataset.
    private var homeView: some View {
        FragranceDetailView(
            name: "Fragrance Name",
            imageName: nil,
            description: "A description of the fragrance goes here. Describe its character, mood, and when it is best worn.",
            notes: [
                FragranceNote(name: "Citrus", intensity: 80),
                FragranceNote(name: "Floral", intensity: 60),
                FragranceNote(name: "Woody", intensity: 70),
                FragranceNote(name: "Musk", intensity: 40),
                FragranceNote(name: "Amber", intensity: 55)
            ]
        )
    }
}

#Preview {
    ContentView()
}
