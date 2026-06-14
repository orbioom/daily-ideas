import SwiftUI
import SwiftData

/// App settings: gameplay prefs, haptics, theme (Pro), Pro/restore, About.
struct SettingsView: View {
    @AppStorage("isPro") private var isPro = false
    @AppStorage("flagModeDefault") private var flagModeDefault = false
    @AppStorage("questionMarks") private var questionMarks = false
    @AppStorage("haptics") private var haptics = true
    @AppStorage("confirmNewGame") private var confirmNewGame = true
    @AppStorage("noGuessDefault") private var noGuessDefault = false
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue

    @Environment(\.modelContext) private var context
    @State private var showPaywall = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                gameplaySection
                feedbackSection
                appearanceSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog("Reset all stats?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Delete all history", role: .destructive) { resetStats() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes your game history and daily results.")
            }
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Sapper Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Sapper Pro")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("No-guess mode, custom boards, themes, CSV export")
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        } header: {
            Text("Pro")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Gameplay

    private var gameplaySection: some View {
        Section {
            Toggle(isOn: $flagModeDefault) {
                settingLabel("Start in flag mode", "Open new boards with the flag tool active")
            }
            Toggle(isOn: $questionMarks) {
                settingLabel("Question marks", "Long-press cycles flag → question → clear")
            }
            Toggle(isOn: $confirmNewGame) {
                settingLabel("Confirm new game", "Ask before discarding an in-progress board")
            }
            // Safe-first-click is always on, but exposed for transparency.
            HStack {
                settingLabel("Safe first click", "Your first tap is never a mine")
                Spacer()
                Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
            }
            if isPro {
                Toggle(isOn: $noGuessDefault) {
                    settingLabel("No-guess by default", "Generate logic-solvable boards")
                }
                .tint(Theme.good)
            }
        } header: {
            Text("Gameplay")
        }
        .tint(Theme.accent)
        .listRowBackground(Theme.surface)
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Section {
            Toggle(isOn: $haptics) {
                settingLabel("Haptics", "Subtle taps on reveal, flag, win and loss")
            }
        } header: {
            Text("Feedback")
        }
        .tint(Theme.accent)
        .listRowBackground(Theme.surface)
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            Picker(selection: $appThemeRaw) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.title).tag(theme.rawValue)
                }
            } label: {
                settingLabel("Theme", isPro ? "Choose light, dark or system" : "Light, dark or system")
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all stats", systemImage: "trash")
            }
        } header: {
            Text("Data")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Sapper")
                    .font(Theme.rounded(15, .semibold))
                Text("A clean, ad-free Minesweeper with a true no-guess mode, a daily challenge and honest stats. Built by Orbioom.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.vertical, 4)
        } header: {
            Text("About")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Helpers

    private func settingLabel(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func resetStats() {
        let recs = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        for r in recs { context.delete(r) }
        let dailies = (try? context.fetch(FetchDescriptor<DailyResult>())) ?? []
        for d in dailies { context.delete(d) }
        try? context.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [GameRecord.self, SavedGame.self, DailyResult.self], inMemory: true)
}
