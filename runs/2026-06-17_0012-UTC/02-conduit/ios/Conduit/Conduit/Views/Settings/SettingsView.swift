import SwiftUI
import SwiftData

/// Settings with persisted, functional preferences plus Pro and About.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Persisted preferences.
    @AppStorage("colorBlindMode") private var colorBlindMode: Bool = false
    @AppStorage("thickGrid") private var thickGrid: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("animationsEnabled") private var animationsEnabled: Bool = true
    @AppStorage("highlightCompleted") private var highlightCompleted: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("confirmReset") private var confirmReset: Bool = true
    @AppStorage("isPro") private var isPro: Bool = false

    @State private var showPaywall = false
    @State private var showResetDataConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                gameplaySection
                accessibilitySection
                feedbackSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(ConduitTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            if isPro {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Conduit Pro active").font(.headline)
                        Text("All packs, archive, palettes and charts unlocked.")
                            .font(.caption).foregroundStyle(ConduitTheme.secondaryText(scheme))
                    }
                } icon: {
                    Image(systemName: "crown.fill").foregroundStyle(ConduitTheme.accent)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Conduit Pro", systemImage: "crown.fill")
                }
            }
        } header: {
            Text("Conduit Pro")
        }
    }

    // MARK: - Gameplay

    private var gameplaySection: some View {
        Section("Gameplay") {
            Toggle(isOn: $showTimer) {
                settingLabel("Show timer", "Display the elapsed time while playing.")
            }
            Toggle(isOn: $highlightCompleted) {
                settingLabel("Highlight completed pipes", "Add a glow to fully connected colors.")
            }
            Toggle(isOn: $confirmReset) {
                settingLabel("Confirm before reset", "Ask before clearing a board.")
            }
            Picker(selection: $thickGrid) {
                Text("Subtle").tag(false)
                Text("Bold").tag(true)
            } label: {
                settingLabel("Grid lines", "Choose how prominent the grid appears.")
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        Section("Accessibility") {
            Toggle(isOn: $colorBlindMode) {
                settingLabel("Color-blind mode", "Show letter labels on endpoint dots.")
            }
            .disabled(!isPro)
            if !isPro {
                Button {
                    showPaywall = true
                } label: {
                    Label("Color-blind palette is a Pro feature", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                }
            }
            Toggle(isOn: $animationsEnabled) {
                settingLabel("Animations", reduceMotion
                             ? "System Reduce Motion is on — celebratory motion stays off."
                             : "Enable celebratory motion on a solve.")
            }
            .disabled(reduceMotion)
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle(isOn: $hapticsEnabled) {
                settingLabel("Haptics", "Vibrate on snaps, connections, and wins.")
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showResetDataConfirm = true
            } label: {
                Label("Reset all progress", systemImage: "trash")
            }
            .alert("Reset all progress?", isPresented: $showResetDataConfirm) {
                Button("Reset", role: .destructive) { resetAllProgress() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This clears every solved level, daily result, and saved board. Pro stays unlocked.")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(ConduitTheme.secondaryText(scheme))
            }
            HStack {
                Text("Puzzles")
                Spacer()
                Text("\(PuzzleBank.all.count)").foregroundStyle(ConduitTheme.secondaryText(scheme))
            }
            NavigationLink {
                AboutView()
            } label: {
                Label("About Conduit", systemImage: "info.circle")
            }
        }
    }

    // MARK: - Helpers

    private func settingLabel(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(subtitle).font(.caption).foregroundStyle(ConduitTheme.secondaryText(scheme))
        }
    }

    private func resetAllProgress() {
        if let rows = try? modelContext.fetch(FetchDescriptor<PuzzleProgress>()) {
            for row in rows {
                row.solved = false
                row.perfect = false
                row.bestMoves = 0
                row.bestSeconds = 0
                row.lastPlayed = .distantPast
            }
        }
        if let dailies = try? modelContext.fetch(FetchDescriptor<DailyResult>()) {
            for d in dailies { modelContext.delete(d) }
        }
        ProgressStore.clearSavedBoards(in: modelContext)
        try? modelContext.save()
    }
}

/// A simple About screen.
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.system(size: 56))
                    .foregroundStyle(ConduitTheme.accent)
                    .accessibilityHidden(true)
                Text("Conduit").font(.largeTitle.weight(.bold))
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                Text("A calm, ad-free connect puzzle. Drag colored pipes to link every pair and fill the whole board.")
                    .font(.body)
                    .foregroundStyle(ConduitTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                ConduitCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to play").font(.headline)
                            .foregroundStyle(ConduitTheme.primaryText(scheme))
                        bullet("Drag from a colored dot to its matching dot.")
                        bullet("Pipes cannot cross — crossing another color erases it back.")
                        bullet("Win by connecting all pairs AND filling every cell.")
                        bullet("Stuck? Tap Hint to reveal one full color.")
                    }
                }
            }
            .padding(16)
        }
        .background(ConduitTheme.appBackground(scheme).ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 6)
                .foregroundStyle(ConduitTheme.accent)
            Text(text).font(.subheadline).foregroundStyle(ConduitTheme.secondaryText(scheme))
        }
    }
}
