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

    @State private var votes = NoteVotes()
    @State private var isVoting = false
    /// Slider positions while the user is voting, keyed by note name.
    @State private var draft: [String: Double] = [:]

    /// Working copy of the votes while editing; committed on submit, discarded on cancel.
    @State private var editVotes = NoteVotes()
    @State private var isAddingNote = false
    @State private var newNoteName = ""

    /// Notes with the default intensities blended with community votes.
    private var displayedNotes: [FragranceNote] { displayedNotes(for: votes) }

    private func displayedNotes(for source: NoteVotes) -> [FragranceNote] {
        source.visibleNotes(from: notes).map {
            FragranceNote(name: $0.name, intensity: source.blendedIntensity(for: $0))
        }
    }

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
                    if isVoting {
                        voteSliders
                    } else {
                        Blend(notes: displayedNotes)
                    }
                    voteControls
                }
            }
            .padding()
        }
        .onAppear { votes = NoteVotes.load(for: name) }
    }

    /// Draggable sliders replacing the bars while the user votes.
    private var voteSliders: some View {
        VStack(spacing: 12) {
            ForEach(displayedNotes(for: editVotes)) { note in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Button {
                            editVotes.remove(note.name)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(note.name)")

                        Text(note.name)
                        Spacer()
                        Text(Int(draft[note.name] ?? note.intensity), format: .number)
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Slider(
                        value: Binding(
                            get: { draft[note.name] ?? note.intensity },
                            set: { draft[note.name] = $0 }
                        ),
                        in: 0...100
                    )
                    .accessibilityLabel("\(note.name) intensity")
                }
            }

            Button {
                newNoteName = ""
                isAddingNote = true
            } label: {
                Label("Add Note", systemImage: "plus.circle.fill")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .alert("New Note", isPresented: $isAddingNote) {
                TextField("Note name", text: $newNoteName)
                Button("Cancel", role: .cancel) {}
                Button("Add") { editVotes.add(note: newNoteName, existing: notes) }
            }
        }
    }

    private var voteControls: some View {
        HStack {
            if isVoting {
                Button("Cancel", role: .cancel) { isVoting = false }
                    .buttonStyle(.bordered)
                Button("Submit Vote") { submitVote() }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("Vote") {
                    editVotes = votes
                    draft = Dictionary(uniqueKeysWithValues: displayedNotes.map { ($0.name, $0.intensity) })
                    isVoting = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func submitVote() {
        for note in editVotes.visibleNotes(from: notes) {
            if let value = draft[note.name] {
                editVotes.add(value, for: note.name)
            }
        }
        votes = editVotes
        votes.save(for: name)
        isVoting = false
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

/// Community votes for a fragrance's notes, stored locally.
/// The default intensity acts as `priorWeight` virtual votes, so it fades in
/// influence as real votes accumulate and the community average takes over.
struct NoteVotes: Codable {
    static let priorWeight = 10.0

    private var sums: [String: Double] = [:]
    private var counts: [String: Int] = [:]
    /// Notes users added that the fragrance doesn't ship with.
    private var customNotes: [String] = []
    /// Default notes users removed.
    private var hiddenNotes: Set<String> = []

    init() {}

    // Custom decoding so data saved before notes could be added/removed still loads.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sums = try c.decodeIfPresent([String: Double].self, forKey: .sums) ?? [:]
        counts = try c.decodeIfPresent([String: Int].self, forKey: .counts) ?? [:]
        customNotes = try c.decodeIfPresent([String].self, forKey: .customNotes) ?? []
        hiddenNotes = try c.decodeIfPresent(Set<String>.self, forKey: .hiddenNotes) ?? []
    }

    /// Default notes minus removed ones, plus user-added notes (starting at a neutral 50).
    func visibleNotes(from defaults: [FragranceNote]) -> [FragranceNote] {
        defaults.filter { !hiddenNotes.contains($0.name) }
            + customNotes.map { FragranceNote(name: $0, intensity: 50) }
    }

    mutating func remove(_ note: String) {
        if let index = customNotes.firstIndex(of: note) {
            customNotes.remove(at: index)
        } else {
            hiddenNotes.insert(note)
        }
    }

    /// Adds a note, restoring it if it was a removed default; ignores blanks and duplicates.
    mutating func add(note: String, existing defaults: [FragranceNote]) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let known = visibleNotes(from: defaults).map(\.name)
        guard !known.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        if let match = defaults.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            hiddenNotes.remove(match.name)
        } else {
            customNotes.append(trimmed)
        }
    }

    mutating func add(_ value: Double, for note: String) {
        sums[note, default: 0] += value
        counts[note, default: 0] += 1
    }

    func blendedIntensity(for note: FragranceNote) -> Double {
        let count = Double(counts[note.name] ?? 0)
        let sum = sums[note.name] ?? 0
        return (note.intensity * Self.priorWeight + sum) / (Self.priorWeight + count)
    }

    private static func key(for fragrance: String) -> String { "noteVotes.\(fragrance)" }

    static func load(for fragrance: String) -> NoteVotes {
        guard let data = UserDefaults.standard.data(forKey: key(for: fragrance)),
              let votes = try? JSONDecoder().decode(NoteVotes.self, from: data) else { return NoteVotes() }
        return votes
    }

    func save(for fragrance: String) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key(for: fragrance))
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
