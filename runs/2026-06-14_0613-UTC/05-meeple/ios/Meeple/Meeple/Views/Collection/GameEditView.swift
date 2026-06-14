import SwiftUI
import SwiftData

/// Add a new game (game == nil) or edit an existing one.
struct GameEditView: View {
    let game: BoardGame?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var title = ""
    @State private var designer = ""
    @State private var minPlayers = 2
    @State private var maxPlayers = 4
    @State private var playTime = 60
    @State private var weight = 2.5
    @State private var year = 2020
    @State private var status: CollectionStatus = .owned
    @State private var rating = 0
    @State private var notes = ""

    @State private var error: String?

    private var isEditing: Bool { game != nil }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var valid: Bool { !trimmedTitle.isEmpty && maxPlayers >= minPlayers }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Title", text: $title)
                    TextField("Designer", text: $designer)
                    Picker("Status", selection: $status) {
                        ForEach(CollectionStatus.allCases) { s in Text(s.label).tag(s) }
                    }
                }
                Section("Players & time") {
                    Stepper("Min players: \(minPlayers)", value: $minPlayers, in: 1...12)
                        .onChange(of: minPlayers) { _, new in if maxPlayers < new { maxPlayers = new } }
                    Stepper("Max players: \(maxPlayers)", value: $maxPlayers, in: minPlayers...20)
                    Stepper("Play time: \(playTime) min", value: $playTime, in: 5...600, step: 5)
                }
                Section("Details") {
                    VStack(alignment: .leading) {
                        Text("Weight (complexity): \(settings.showWeightAs.render(weight))")
                            .font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
                        Slider(value: $weight, in: 1...5, step: 0.1).tint(Theme.accent)
                            .accessibilityLabel("Weight")
                            .accessibilityValue(String(format: "%.1f out of 5", weight))
                    }
                    Stepper("Year: \(String(year))", value: $year, in: 1900...2030)
                    VStack(alignment: .leading) {
                        Text("Rating").font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
                        StarRatingView(rating: $rating)
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
                }
                if let error {
                    Text(error).font(Theme.rounded(13)).foregroundStyle(Theme.danger)
                }
            }
            .navigationTitle(isEditing ? "Edit Game" : "Add Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!valid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let game else { return }
        title = game.title
        designer = game.designer
        minPlayers = game.minPlayers
        maxPlayers = game.maxPlayers
        playTime = game.playTimeMin
        weight = game.weight
        year = game.yearPublished
        status = game.status
        rating = game.rating
        notes = game.notes
    }

    private func save() {
        guard valid else {
            error = trimmedTitle.isEmpty ? "Please enter a title." : "Max players must be ≥ min players."
            Haptics.warning(settings.hapticsEnabled)
            return
        }
        if let game {
            game.title = trimmedTitle
            game.designer = designer.trimmingCharacters(in: .whitespaces)
            game.minPlayers = minPlayers
            game.maxPlayers = max(minPlayers, maxPlayers)
            game.playTimeMin = playTime
            game.weight = min(5, max(1, weight))
            game.yearPublished = year
            game.status = status
            game.rating = rating
            game.notes = notes
            game.coverHue = BoardGame.hue(for: trimmedTitle)
        } else {
            let g = BoardGame(
                title: trimmedTitle,
                designer: designer.trimmingCharacters(in: .whitespaces),
                minPlayers: minPlayers, maxPlayers: max(minPlayers, maxPlayers),
                playTimeMin: playTime, weight: min(5, max(1, weight)),
                yearPublished: year, status: status, rating: rating, notes: notes
            )
            context.insert(g)
        }
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
