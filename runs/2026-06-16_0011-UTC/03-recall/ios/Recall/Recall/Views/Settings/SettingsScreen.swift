import SwiftUI
import SwiftData

/// Settings: persisted study prefs, Pro, data actions (sample/export/erase), About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var allDecks: [Deck]

    @State private var paywallReason: PaywallReason?
    @State private var showExport = false
    @State private var showAbout = false
    @State private var showResetConfirm = false
    @State private var statusMessage: String?

    private var activeDeckCount: Int { allDecks.filter { !$0.isArchived }.count }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                studySection
                appearanceSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showExport) {
                ExportView(text: ExportBuilder.buildCSV(decks: allDecks))
            }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset all data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Reload sample data", role: .destructive) { reloadSample() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces or clears all of your decks, cards, and review history.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Recall Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    HStack {
                        Label("Unlock Recall Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("\(activeDeckCount) of \(Pro.freeDeckLimit) free decks used")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Recall Pro")
        }
    }

    // MARK: Study prefs (>=3 functional persisted prefs)

    private var studySection: some View {
        Section {
            Stepper(value: $settings.dailyNewLimit, in: 0...100, step: 5) {
                HStack {
                    Label("New cards / day", systemImage: "sparkles")
                    Spacer()
                    Text("\(settings.boundedNewLimit())")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
            }
            Stepper(value: $settings.dailyReviewLimit, in: 10...500, step: 10) {
                HStack {
                    Label("Reviews / day", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Text("\(settings.boundedReviewLimit())")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
            }
            Picker(selection: $settings.defaultStudyModeRaw) {
                ForEach(ReviewMode.allCases) { m in
                    Text(m.display).tag(m.rawValue)
                }
            } label: {
                Label("Default study mode", systemImage: "play.rectangle")
            }
            Toggle(isOn: $settings.shuffleOrder) {
                Label("Shuffle study order", systemImage: "shuffle")
            }
        } header: {
            Text("Study")
        } footer: {
            Text("Limits apply per deck per day. Non-flip default modes require Recall Pro at launch.")
        }
    }

    private var appearanceSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            Picker(selection: $settings.appearanceRaw) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button { showExport = true } label: {
                Label("Export as CSV", systemImage: "square.and.arrow.up")
            }
            Button { loadSample() } label: {
                Label("Load sample data", systemImage: "tray.and.arrow.down")
            }
            Button(role: .destructive) { showResetConfirm = true } label: {
                Label("Reset data", systemImage: "trash")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Recall", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func loadSample() {
        // Only seed if empty; otherwise tell the user to reset first.
        if allDecks.isEmpty {
            SeedData.seed(context: context)
            statusMessage = "Sample data loaded."
        } else {
            statusMessage = "You already have decks — use Reset to reload samples."
        }
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func reloadSample() {
        SeedData.clearAll(context: context)
        SeedData.seed(context: context)
        statusMessage = "Sample data reloaded."
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        statusMessage = "All data erased."
        Haptics.success(enabled: settings.hapticsEnabled)
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
