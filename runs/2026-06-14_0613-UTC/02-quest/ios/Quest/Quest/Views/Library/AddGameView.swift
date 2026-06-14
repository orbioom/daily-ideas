import SwiftUI
import SwiftData

/// Add a new game with validation. Used as a sheet from the Library.
struct AddGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var title = ""
    @State private var platform: Platform = .pc
    @State private var genre: Genre = .action
    @State private var status: GameStatus = .backlog
    @State private var storyHours = ""
    @State private var isFavorite = false
    @State private var showValidation = false

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool { !trimmedTitle.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Game title", text: $title)
                        .font(Theme.rounded(17))
                        .accessibilityLabel("Game title")
                    if showValidation && !isValid {
                        Label("A title is required.", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.danger)
                    }
                } header: {
                    Text("Title")
                }

                Section("Details") {
                    Picker("Platform", selection: $platform) {
                        ForEach(Platform.allCases) { p in
                            Label(p.label, systemImage: p.symbol).tag(p)
                        }
                    }
                    Picker("Genre", selection: $genre) {
                        ForEach(Genre.allCases) { g in
                            Label(g.label, systemImage: g.symbol).tag(g)
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(GameStatus.allCases) { s in
                            Label(s.label, systemImage: s.symbol).tag(s)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Length estimate")
                        Spacer()
                        TextField("0", text: $storyHours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                            .accessibilityLabel("Length estimate in hours")
                        Text("h").foregroundStyle(Theme.textSecondary)
                    }
                    Toggle("Favorite", isOn: $isFavorite)
                } header: {
                    Text("Optional")
                } footer: {
                    Text("Length helps the picker favor shorter games and powers your progress bar.")
                }
            }
            .navigationTitle("Add Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard isValid else {
            showValidation = true
            Haptics.play(.warning, enabled: settings.hapticsEnabled)
            return
        }
        let hours = Double(storyHours.replacingOccurrences(of: ",", with: ".")) ?? 0
        let game = Game(
            title: trimmedTitle,
            platform: platform,
            genre: genre,
            status: status,
            mainStoryHours: max(0, hours),
            dateCompleted: status == .completed ? .now : nil,
            isFavorite: isFavorite
        )
        modelContext.insert(game)
        try? modelContext.save()
        Haptics.play(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
