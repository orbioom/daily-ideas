import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("defaultTeamA") private var defaultTeamA = "Home"
    @AppStorage("defaultTeamB") private var defaultTeamB = "Away"
    @AppStorage("defaultQuarterMinutes") private var defaultQuarterMinutes = 10
    @AppStorage("defaultTimeouts") private var defaultTimeouts = 5
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @Query private var games: [HoopGame]
    @Environment(\.modelContext) private var modelContext
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()

                List {
                    // Defaults Section
                    Section {
                        LabeledContent("Home Team Name") {
                            TextField("Home", text: $defaultTeamA)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(HoopTheme.teamAColor)
                        }
                        LabeledContent("Away Team Name") {
                            TextField("Away", text: $defaultTeamB)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(HoopTheme.teamBColor)
                        }
                    } header: {
                        Text("Default Team Names")
                    }
                    .listRowBackground(HoopTheme.cardBg)

                    Section {
                        Picker("Quarter Length", selection: $defaultQuarterMinutes) {
                            Text("8 minutes").tag(8)
                            Text("10 minutes").tag(10)
                            Text("12 minutes").tag(12)
                        }

                        Stepper("Timeouts per Team: \(defaultTimeouts)", value: $defaultTimeouts, in: 3...7)
                    } header: {
                        Text("Default Game Settings")
                    }
                    .listRowBackground(HoopTheme.cardBg)

                    // Haptics
                    Section {
                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                            .tint(HoopTheme.orange)
                    } header: {
                        Text("Feedback")
                    }
                    .listRowBackground(HoopTheme.cardBg)

                    // History
                    Section {
                        HStack {
                            Text("Games Saved")
                            Spacer()
                            Text("\(games.count)")
                                .foregroundColor(HoopTheme.subtleText)
                        }

                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Label("Clear All History", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .disabled(games.isEmpty)
                    } header: {
                        Text("History")
                    }
                    .listRowBackground(HoopTheme.cardBg)

                    // About
                    Section {
                        LabeledContent("App", value: "Hoop")
                        LabeledContent("Version", value: "1.0")
                        LabeledContent("Developer", value: "Orbioom")
                    } header: {
                        Text("About")
                    }
                    .listRowBackground(HoopTheme.cardBg)
                }
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Clear all game history?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) {
                    clearAllGames()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(games.count) saved games. This cannot be undone.")
            }
        }
    }

    private func clearAllGames() {
        for game in games {
            modelContext.delete(game)
        }
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
