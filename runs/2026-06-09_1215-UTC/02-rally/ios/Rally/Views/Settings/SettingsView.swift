import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var matches: [Match]
    @Query private var players: [Player]

    @AppStorage("rally.haptics") private var haptics = true
    @AppStorage("rally.defaultSport") private var defaultSport = Sport.pickleball.rawValue
    @AppStorage("rally.defaultPointsToWin") private var defaultPoints = 11
    @AppStorage("rally.winByTwoDefault") private var defaultWinByTwo = true
    @AppStorage("rally.onboarded") private var onboarded = true

    @State private var showDeleteConfirm = false
    @State private var showResetOnboarding = false

    private var sport: Sport { Sport(rawValue: defaultSport) ?? .pickleball }
    private var completed: Int { matches.filter { $0.isComplete }.count }

    var body: some View {
        Form {
            Section("Defaults for new matches") {
                Picker("Default sport", selection: $defaultSport) {
                    ForEach(Sport.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("Points to win", selection: $defaultPoints) {
                    ForEach(sport.pointOptions, id: \.self) { Text("\($0)").tag($0) }
                }
                Toggle("Win by two", isOn: $defaultWinByTwo)
            }

            Section("Feel") {
                Toggle("Haptics", isOn: $haptics)
            } footer: {
                Text("Subtle taps on points, games, and saves.")
            }

            Section("Your data") {
                LabeledContent("Players", value: "\(players.count)")
                LabeledContent("Matches logged", value: "\(completed)")
            }

            Section("Rally Pro") {
                LabeledContent("Status", value: "Free")
            } footer: {
                Text("The free app logs unlimited matches during early access. Rally Pro will unlock advanced stats and full rating history as a one-time purchase.")
            }

            Section {
                Button {
                    Haptics.tap(); showResetOnboarding = true
                } label: {
                    Label("Replay intro", systemImage: "arrow.counterclockwise")
                }
                Button(role: .destructive) {
                    Haptics.warning(); showDeleteConfirm = true
                } label: {
                    Label("Delete all data", systemImage: "trash")
                }
            } footer: {
                Text("Everything stays on this device. Deleting removes every player and match.")
            }

            Section {
                LabeledContent("Rally", value: "1.0")
            } footer: {
                Text("Conjured, not just coded. A private, native racket-sports tracker by Orbioom.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .onChange(of: defaultSport) { _, _ in
            // Keep points-to-win valid for the chosen sport.
            if !sport.pointOptions.contains(defaultPoints) {
                defaultPoints = sport.defaultPointsToWin
            }
        }
        .confirmationDialog("Delete all data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes every player and match. This can't be undone.")
        }
        .confirmationDialog("Replay the intro?", isPresented: $showResetOnboarding, titleVisibility: .visible) {
            Button("Show intro") { onboarded = false }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll see the welcome screens again. Your data is kept.")
        }
    }

    private func deleteAll() {
        for m in matches { context.delete(m) }
        for p in players { context.delete(p) }
        try? context.save()
        Haptics.warning()
    }
}
