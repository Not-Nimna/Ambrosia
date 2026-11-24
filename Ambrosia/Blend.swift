//
//  Blend.swift
//  Ambrosia
//
//  Created by Nimna Wijedasa on 2026-11-23.
//

import SwiftUI
import Charts

/// A single scent note and how strongly it presents (0–100).
struct FragranceNote: Identifiable {
    let name: String
    let intensity: Double

    var id: String { name }
}

/// A reusable horizontal bar chart of scent notes and their intensities.
/// Note names sit in a left-hand column with the bars to their right.
struct Blend: View {
    let notes: [FragranceNote]
    var domain: ClosedRange<Double> = 0...100
    var barColor: Color? = nil
    var rowHeight: CGFloat = 44
    var cornerRadius: CGFloat = 6

    var body: some View {
        Chart(notes) { note in
            BarMark(
                x: .value("Intensity", note.intensity),
                y: .value("Note", note.name)
            )
            .foregroundStyle(barColor.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.tint))
            .cornerRadius(cornerRadius)
        }
        // Axis labels form the left column; the plot area (bars) starts to their right.
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis(.hidden)
        .chartXScale(domain: domain)
        .frame(height: CGFloat(notes.count) * rowHeight)
    }
}

#Preview {
    Blend(notes: [
        FragranceNote(name: "Citrus", intensity: 80),
        FragranceNote(name: "Floral", intensity: 60),
        FragranceNote(name: "Woody", intensity: 70)
    ])
    .padding()
}
