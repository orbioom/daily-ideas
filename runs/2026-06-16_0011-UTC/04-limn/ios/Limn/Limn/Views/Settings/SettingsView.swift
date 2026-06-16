import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var resetDone = false
    @State private var sampleLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                gameplaySection
                proSection
                dataSection
                helpSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var gameplaySection: some View {
        Section("Gameplay") {
            Toggle("Assist mode (flag mistakes)", isOn: $settings.assistMode)
            Toggle("Show mistakes counter", isOn: $settings.showMistakes)
            Toggle("Auto-cross completed lines", isOn: $settings.autoCrossCompletedLines)
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)

            Picker("Default tap action", selection: Binding(
                get: { settings.defaultTapMode },
                set: { settings.defaultTapMode = $0 }
            )) {
                ForEach(TapMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("Assist warns you the instant you fill a wrong cell. Auto-cross fills X marks across any row or column whose clue you've satisfied.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var proSection: some View {
        Section("Limn Pro") {
            if isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Limn Pro (\(Pro.priceLabel))", systemImage: "square.grid.3x3.fill")
                }
            }
            Button("Restore purchase") { paywallReason = .general }
                .foregroundStyle(Theme.accent)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button {
                SeedData.insertSampleData(context: modelContext)
                sampleLoaded = true
                Haptics.success(enabled: settings.hapticsEnabled)
            } label: {
                Label("Load sample data", systemImage: "wand.and.stars")
            }
            if sampleLoaded {
                Text("Sample solves and daily history added.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }

            Button {
                showResetConfirm = true
            } label: {
                Label("Reset all progress", systemImage: "trash")
                    .foregroundStyle(Theme.bad)
            }
            if resetDone {
                Text("All progress cleared.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        }
        .confirmationDialog("Reset everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Erase all progress", role: .destructive) {
                eraseAll()
                Haptics.warning(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your solves, saved games, stats, and daily streak. This cannot be undone.")
        }
    }

    private var helpSection: some View {
        Section("Help") {
            NavigationLink {
                HowToPlayView()
            } label: {
                Label("How to Play", systemImage: "book.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Limn is a calm, ad-free nonogram (picross) game with a real logic solver. Every puzzle is solvable by pure deduction. Everything stays private on your device — no account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func eraseAll() {
        for game in (try? modelContext.fetch(FetchDescriptor<SavedGame>())) ?? [] {
            modelContext.delete(game)
        }
        for record in (try? modelContext.fetch(FetchDescriptor<PuzzleRecord>())) ?? [] {
            modelContext.delete(record)
        }
        for daily in (try? modelContext.fetch(FetchDescriptor<DailyResult>())) ?? [] {
            modelContext.delete(daily)
        }
        try? modelContext.save()
        resetDone = true
        sampleLoaded = false
    }
}
