import SwiftUI
import SwiftData

struct AddMediaView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var mediaType: MediaType = .movie
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var genre: MediaGenre = .drama
    @State private var status: WatchStatus = .watchlist
    @State private var posterEmoji = "🎬"
    @State private var runtimeMinutes = 100
    @State private var seasonCount = 1
    @State private var episodesPerSeason = 10
    @State private var showEmojiPicker = false

    private let movieEmojis = ["🎬","🎭","🎥","📽️","🎞️","🎦","🎊","🎪","🌟","⭐️","🏆","🎯"]
    private let showEmojis  = ["📺","🎭","🎬","📡","🌟","⭐️","🏆","🎯","🎪","🎥","💫","🎊"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Title")

                    Picker("Type", selection: $mediaType) {
                        ForEach(MediaType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Media type")

                    Picker("Genre", selection: $genre) {
                        ForEach(MediaGenre.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityLabel("Genre")

                    Stepper("Year: \(year)", value: $year, in: 1900...2030)
                        .accessibilityLabel("Year: \(year)")
                }

                Section("Poster") {
                    let emojis = mediaType == .movie ? movieEmojis : showEmojis
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title2)
                                .padding(8)
                                .background(
                                    posterEmoji == emoji
                                        ? Theme.gold.opacity(0.25)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { posterEmoji = emoji }
                                .accessibilityLabel("Poster emoji \(emoji)")
                                .accessibilityAddTraits(posterEmoji == emoji ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                if mediaType == .movie {
                    Section("Runtime") {
                        Stepper("\(runtimeMinutes) minutes", value: $runtimeMinutes, in: 1...600, step: 5)
                            .accessibilityLabel("Runtime: \(runtimeMinutes) minutes")
                    }
                } else {
                    Section("Seasons & Episodes") {
                        Stepper("\(seasonCount) season\(seasonCount == 1 ? "" : "s")", value: $seasonCount, in: 1...30)
                            .accessibilityLabel("\(seasonCount) seasons")
                        Stepper("\(episodesPerSeason) episodes each", value: $episodesPerSeason, in: 1...100)
                            .accessibilityLabel("\(episodesPerSeason) episodes per season")
                        Stepper("Episode runtime: \(runtimeMinutes) min", value: $runtimeMinutes, in: 1...120, step: 5)
                            .accessibilityLabel("Episode runtime: \(runtimeMinutes) minutes")
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(WatchStatus.allCases, id: \.self) {
                            Label($0.rawValue, systemImage: $0.icon).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Watch status")
                }
            }
            .navigationTitle("Add \(mediaType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityHint("Save this entry to your library")
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let entry = MediaEntry(
            title: trimmed,
            mediaType: mediaType,
            year: year,
            genre: genre,
            posterEmoji: posterEmoji,
            status: status,
            runtimeMinutes: runtimeMinutes
        )
        ctx.insert(entry)

        if mediaType == .show {
            for s in 1...seasonCount {
                let season = Season(seasonNumber: s)
                season.entry = entry
                ctx.insert(season)
                for e in 1...episodesPerSeason {
                    let ep = Episode(episodeNumber: e)
                    ep.season = season
                    ctx.insert(ep)
                }
            }
        }

        if status == .watched && mediaType == .movie {
            entry.watchedDate = Date()
        }

        dismiss()
    }
}
