import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var resetDone = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                preferencesSection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
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

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
            Toggle("Show best-score chip", isOn: $settings.showBestOverlay)
            Toggle("Enable Undo control", isOn: $settings.swipeToUndoEnabled)

            Picker("New game board size", selection: Binding(
                get: { settings.defaultBoardSize },
                set: { newValue in
                    if Pro.boardSizeIsFree(newValue) || isPro {
                        settings.defaultBoardSize = newValue
                    } else {
                        paywallReason = .biggerBoards
                    }
                }
            )) {
                Text("4 × 4").tag(4)
                Text(isPro ? "5 × 5" : "5 × 5 (Pro)").tag(5)
                Text(isPro ? "6 × 6" : "6 × 6 (Pro)").tag(6)
            }

            Text("New games on the Play tab start at this size. Bigger boards are part of Tetra Pro.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var proSection: some View {
        Section("Tetra Pro") {
            if isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Tetra Pro (\(Pro.priceLabel))", systemImage: "square.grid.3x3.fill")
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button {
                showResetConfirm = true
            } label: {
                Label("Reset all games & history", systemImage: "trash")
                    .foregroundStyle(Theme.bad)
            }
            if resetDone {
                Text("All games and history cleared.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .confirmationDialog("Reset everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Erase all data", role: .destructive) {
                eraseAll()
                Haptics.warning(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your saved games, scores, stats, and achievements. This cannot be undone.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Tetra is a calm, ad-free take on the classic 2048 number-merge puzzle. Everything stays private on your device — no account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func eraseAll() {
        let savedDescriptor = FetchDescriptor<SavedGame>()
        for game in (try? modelContext.fetch(savedDescriptor)) ?? [] {
            modelContext.delete(game)
        }
        let recordDescriptor = FetchDescriptor<GameRecord>()
        for record in (try? modelContext.fetch(recordDescriptor)) ?? [] {
            modelContext.delete(record)
        }
        try? modelContext.save()
        resetDone = true
    }
}
