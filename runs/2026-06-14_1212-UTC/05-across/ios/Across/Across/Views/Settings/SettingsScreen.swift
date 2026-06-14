import SwiftUI
import SwiftData

/// Settings: persisted solving prefs, theme, Pro, data actions, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false

    @Query private var progress: [PuzzleProgress]
    @Query private var results: [DailyResult]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var statusMessage: String?

    private var solvedCount: Int { progress.filter { $0.completed }.count }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                solvingSection
                themeSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset all progress?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & load sample history", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears every saved grid, time, and streak.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Across Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .archive } label: {
                    HStack {
                        Label("Unlock Across Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Button("Restore Purchase") { paywallReason = .archive }
                    .font(Theme.rounded(14))
                Text("Free includes the daily puzzle plus \(Pro.freeArchiveLimit) from the archive.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Across Pro")
        }
    }

    // MARK: Solving prefs (>=3 functional persisted prefs)

    private var solvingSection: some View {
        Section {
            Toggle(isOn: $settings.autoAdvance) {
                Label("Auto-advance", systemImage: "arrow.right.to.line")
            }
            Toggle(isOn: $settings.skipFilled) {
                Label("Skip filled squares", systemImage: "forward.end")
            }
            Toggle(isOn: $settings.confirmReveal) {
                Label("Confirm before reveal", systemImage: "exclamationmark.shield")
            }
            Toggle(isOn: $settings.showTimer) {
                Label("Show timer", systemImage: "clock")
            }
            Toggle(isOn: $settings.pencilMode) {
                Label("Pencil mode", systemImage: "pencil")
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("Solving")
        } footer: {
            Text("Auto-advance moves to the next square as you type. Skip-filled jumps over completed answers when you change clues.")
        }
    }

    // MARK: Theme

    private var themeSection: some View {
        Section {
            ForEach(ThemePalette.allCases) { palette in
                Button {
                    selectPalette(palette)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(palette.title)
                                .font(Theme.rounded(16))
                                .foregroundStyle(Theme.ink)
                            Text(palette.subtitle)
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        if !Pro.paletteUnlocked(palette, isPro: isPro) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.inkFaint)
                        } else if settings.palette == palette {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
        } header: {
            Text("Board theme")
        } footer: {
            Text("Ink and High Contrast are part of Across Pro.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                loadSampleData()
            } label: {
                Label("Load sample data", systemImage: "square.and.arrow.down")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset progress", systemImage: "trash")
            }

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("\(solvedCount) puzzles solved · \(results.count) daily results saved. Everything lives on this device.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Across", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func selectPalette(_ palette: ThemePalette) {
        if Pro.paletteUnlocked(palette, isPro: isPro) {
            settings.palette = palette
            settings.syncPalette()
            Haptics.tap(settings.hapticsEnabled)
        } else {
            paywallReason = .theme
        }
    }

    private func loadSampleData() {
        SeedData.reseed(context: context)
        didSeed = true
        statusMessage = "Sample history loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func resetAndReseed() {
        SeedData.reseed(context: context)
        didSeed = true
        statusMessage = "Progress reset with sample data."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        didSeed = true
        statusMessage = "All progress erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
