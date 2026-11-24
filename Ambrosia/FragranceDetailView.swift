//
//  FragranceDetailView.swift
//  Ambrosia
//
//  Created by Nimna Wijedasa on 2026-11-23.
//

import SwiftUI

/// A reusable detail page for a single fragrance.
/// Feed it a name, image, description, and notes (e.g. from a dataset) to display any perfume.
struct FragranceDetailView: View {
    let name: String
    /// Asset catalog name of the fragrance PNG; a placeholder is shown when `nil`.
    var imageName: String? = nil
    var description: String
    var notes: [FragranceNote]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(name)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .center)

                imageArea

                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    Text(description)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    Blend(notes: notes)
                }
            }
            .padding()
        }
    }

    /// Area for the fragrance PNG; shows a placeholder until an image is provided.
    private var imageArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.quaternary)

            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 280)
        .accessibilityLabel("Image of \(name)")
    }
}

#Preview {
    FragranceDetailView(
        name: "Fragrance Name",
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
