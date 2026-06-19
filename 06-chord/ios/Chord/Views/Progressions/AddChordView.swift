import SwiftUI
import SwiftData

struct AddChordView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var progression: Progression
    @State private var engine = ChordEngine()

    @State private var rootNote = "C"
    @State private var quality: ChordQuality = .major
    @State private var duration: BeatDuration = .four
    @State private var lyricHint = ""
    @State private var useSuggestions = false

    private let rootNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
                              "Db", "Eb", "Ab", "Bb"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Suggested for Key of \(progression.keyName)") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(engine.suggestedChords(forKey: progression.keyName), id: \.root) { suggestion in
                                Button {
                                    rootNote = suggestion.root
                                    quality = suggestion.quality
                                } label: {
                                    let name = suggestion.quality == .major ? suggestion.root : "\(suggestion.root)\(suggestion.quality.rawValue)"
                                    Text(name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(rootNote == suggestion.root && quality == suggestion.quality ? .white : ChordTheme.teal)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            rootNote == suggestion.root && quality == suggestion.quality
                                                ? ChordTheme.teal
                                                : ChordTheme.teal.opacity(0.12),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                Section("Chord") {
                    Picker("Root Note", selection: $rootNote) {
                        ForEach(rootNotes, id: \.self) { n in Text(n).tag(n) }
                    }
                    Picker("Quality", selection: $quality) {
                        ForEach(ChordQuality.allCases, id: \.self) { q in
                            Text(q.displayName).tag(q)
                        }
                    }
                }

                Section("Duration") {
                    Picker("Duration", selection: $duration) {
                        ForEach(BeatDuration.allCases, id: \.self) { d in
                            Text(d.displayName).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Lyric Hint") {
                    TextField("Optional lyric or note for this chord", text: $lyricHint)
                }

                Section {
                    let name = quality == .major ? rootNote : "\(rootNote)\(quality.rawValue)"
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text(name)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(ChordTheme.qualityColor(quality))
                            Text(quality.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(duration.displayName)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Add Chord")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let position = progression.chords.count
        let slot = ChordSlot(rootNote: rootNote, quality: quality,
                             duration: duration, position: position, lyricHint: lyricHint)
        context.insert(slot)
        progression.chords.append(slot)
        progression.modifiedDate = Date()
        dismiss()
    }
}
