import SwiftUI

struct EditMediaView: View {
    @Bindable var entry: MediaEntry
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var year: Int
    @State private var genreRaw: String
    @State private var posterEmoji: String
    @State private var runtimeMinutes: Int

    init(entry: MediaEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _year = State(initialValue: entry.year)
        _genreRaw = State(initialValue: entry.genreRaw)
        _posterEmoji = State(initialValue: entry.posterEmoji)
        _runtimeMinutes = State(initialValue: entry.runtimeMinutes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    Picker("Genre", selection: $genreRaw) {
                        ForEach(MediaGenre.allCases, id: \.self) {
                            Text($0.rawValue).tag($0.rawValue)
                        }
                    }
                    Stepper("Year: \(year)", value: $year, in: 1900...2030)
                }

                Section("Poster") {
                    let emojis = ["🎬","🎭","🎥","📽️","🎞️","📺","🎦","🌟","⭐️","🏆","🎯","🎪","💫","🎊"]
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 10) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title3)
                                .padding(6)
                                .background(posterEmoji == emoji ? Theme.gold.opacity(0.25) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { posterEmoji = emoji }
                        }
                    }
                }

                Section("Runtime") {
                    Stepper("\(runtimeMinutes) minutes", value: $runtimeMinutes, in: 1...600, step: 5)
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        entry.title = trimmed
                        entry.year = year
                        entry.genreRaw = genreRaw
                        entry.posterEmoji = posterEmoji
                        entry.runtimeMinutes = runtimeMinutes
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
