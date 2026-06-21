import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsList: [DraughtsSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var showProAlert = false

    private var settings: DraughtsSettings {
        if let s = settingsList.first { return s }
        let s = DraughtsSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DraughtsTheme.background.ignoresSafeArea()

                List {
                    gameplaySection
                    appearanceSection
                    feedbackSection
                    proSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .tint(DraughtsTheme.gold)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DraughtsTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .alert("Draughts Pro", isPresented: $showProAlert) {
            Button("Purchase — $2.99") { purchasePro() }
            Button("Restore Purchases") { restorePurchases() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Unlock Draughts Pro for $2.99 — a one-time purchase. Ad-free forever with all future features included.")
        }
    }

    // MARK: - Sections

    private var gameplaySection: some View {
        Section {
            Picker("Difficulty", selection: Bindable(settings).difficulty) {
                ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                    Text(diff.displayName).tag(diff.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(DraughtsTheme.cardBackground)

            Toggle("Play as Red", isOn: Bindable(settings).humanPlaysRed)
                .tint(DraughtsTheme.gold)
                .foregroundStyle(DraughtsTheme.text)
                .listRowBackground(DraughtsTheme.cardBackground)
        } header: {
            sectionHeader("Gameplay")
        } footer: {
            Text("Red moves first. Changing sides takes effect on the next game.")
                .foregroundStyle(DraughtsTheme.text.opacity(0.45))
                .font(.caption)
        }
    }

    private var appearanceSection: some View {
        Section {
            HStack {
                Text("Board Style")
                    .foregroundStyle(DraughtsTheme.text)
                Spacer()
                Text("Classic Wood")
                    .foregroundStyle(DraughtsTheme.text.opacity(0.55))
            }
            .listRowBackground(DraughtsTheme.cardBackground)
        } header: {
            sectionHeader("Appearance")
        }
    }

    private var feedbackSection: some View {
        Section {
            Toggle("Haptics", isOn: Bindable(settings).hapticsEnabled)
                .tint(DraughtsTheme.gold)
                .foregroundStyle(DraughtsTheme.text)
                .listRowBackground(DraughtsTheme.cardBackground)

            Toggle("Sound Effects", isOn: Bindable(settings).soundEnabled)
                .tint(DraughtsTheme.gold)
                .foregroundStyle(DraughtsTheme.text)
                .listRowBackground(DraughtsTheme.cardBackground)
        } header: {
            sectionHeader("Feedback")
        }
    }

    private var proSection: some View {
        Section {
            Button {
                if settings.isPro {
                    // Already pro — do nothing
                } else {
                    showProAlert = true
                }
            } label: {
                HStack {
                    Label(
                        settings.isPro ? "Draughts Pro — Unlocked ✓" : "Unlock Draughts Pro",
                        systemImage: "crown.fill"
                    )
                    .foregroundStyle(DraughtsTheme.gold)

                    Spacer()

                    if !settings.isPro {
                        Text("$2.99")
                            .font(.subheadline.bold())
                            .foregroundStyle(DraughtsTheme.gold)
                    }
                }
            }
            .listRowBackground(DraughtsTheme.cardBackground)
        } header: {
            sectionHeader("Pro")
        } footer: {
            Text("One-time purchase. Ad-free and includes all future features.")
                .foregroundStyle(DraughtsTheme.text.opacity(0.45))
                .font(.caption)
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(DraughtsTheme.text)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(DraughtsTheme.text.opacity(0.55))
            }
            .listRowBackground(DraughtsTheme.cardBackground)

            HStack {
                Text("Bundle ID")
                    .foregroundStyle(DraughtsTheme.text)
                Spacer()
                Text("com.orbioom.draughts")
                    .font(.caption)
                    .foregroundStyle(DraughtsTheme.text.opacity(0.55))
            }
            .listRowBackground(DraughtsTheme.cardBackground)

            Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
                .foregroundStyle(DraughtsTheme.gold)
                .listRowBackground(DraughtsTheme.cardBackground)

            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                .foregroundStyle(DraughtsTheme.gold)
                .listRowBackground(DraughtsTheme.cardBackground)
        } header: {
            sectionHeader("About")
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.uppercaseSmallCaps())
            .foregroundStyle(DraughtsTheme.gold.opacity(0.80))
    }

    private func purchasePro() {
        // In production this would call StoreKit 2.
        // For now mark as purchased directly.
        settings.isPro = true
        try? modelContext.save()
    }

    private func restorePurchases() {
        // In production, call AppStore.sync() via StoreKit 2.
        // Placeholder: nothing to restore in current build.
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [DraughtsSettings.self], inMemory: true)
}
