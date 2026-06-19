import SwiftUI
import SwiftData

struct AddProgressionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ChordSettings.defaultKey) private var defaultKey = "C"
    @AppStorage(ChordSettings.defaultTempo) private var defaultTempo = 120

    @State private var title = ""
    @State private var keyName = "C"
    @State private var genre: ProgressionGenre = .pop
    @State private var tempo = 120
    @State private var notes = ""

    private let rootNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
                              "Db", "Eb", "Ab", "Bb"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Name this progression", text: $title)
                        .accessibilityLabel("Progression title")
                }

                Section("Setup") {
                    Picker("Key", selection: $keyName) {
                        ForEach(rootNotes, id: \.self) { n in Text(n).tag(n) }
                    }

                    Picker("Genre", selection: $genre) {
                        ForEach(ProgressionGenre.allCases, id: \.self) { g in
                            Label(g.rawValue, systemImage: g.icon).tag(g)
                        }
                    }

                    Stepper("Tempo: \(tempo) BPM", value: $tempo, in: 40...240, step: 5)
                        .accessibilityLabel("Tempo: \(tempo) beats per minute")
                }

                Section("Notes") {
                    TextField("Optional notes, lyrics, ideas…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Progression")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                keyName = defaultKey
                tempo = defaultTempo
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let progression = Progression(title: t, keyName: keyName, genre: genre, tempo: tempo, notes: notes)
        context.insert(progression)
        dismiss()
    }
}
