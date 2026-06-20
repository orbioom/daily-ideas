import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsList: [PairSettings]
    @Query private var results: [PairResult]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showResetConfirm = false
    @State private var showProAlert = false

    private var settings: PairSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ZStack {
                PairTheme.background.ignoresSafeArea()

                List {
                    preferencesSection
                    proSection
                    dangerSection
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(PairTheme.accent)
                }
            }
            .alert("Unlock Pro", isPresented: $showProAlert) {
                Button("Unlock for $2.99") {
                    settings?.hasPro = true
                }
                Button("Restore Purchases") {
                    // In production: SKPaymentQueue.default().restoreCompletedTransactions()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Get Nature & Classic themes, Hard grid size, and Daily Challenge archive.\n\nOne-time purchase. No subscription.")
            }
            .alert("Reset All Stats?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) {
                    for result in results {
                        modelContext.delete(result)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your game history and statistics. This cannot be undone.")
            }
        }
    }

    private var preferencesSection: some View {
        Section {
            settingsRow {
                Toggle(isOn: Binding(
                    get: { settings?.soundEnabled ?? true },
                    set: { settings?.soundEnabled = $0 }
                )) {
                    Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                        .foregroundStyle(PairTheme.textPrimary)
                }
                .tint(PairTheme.accent)
            }

            settingsRow {
                Toggle(isOn: Binding(
                    get: { settings?.hapticEnabled ?? true },
                    set: { settings?.hapticEnabled = $0 }
                )) {
                    Label("Haptic Feedback", systemImage: "hand.tap.fill")
                        .foregroundStyle(PairTheme.textPrimary)
                }
                .tint(PairTheme.accent)
            }

            settingsRow {
                Toggle(isOn: Binding(
                    get: { settings?.colorBlindMode ?? false },
                    set: { settings?.colorBlindMode = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Color-Blind Mode", systemImage: "eye.fill")
                            .foregroundStyle(PairTheme.textPrimary)
                        Text("Adds shapes for distinction")
                            .font(.caption)
                            .foregroundStyle(PairTheme.textSecondary)
                    }
                }
                .tint(PairTheme.accent)
            }
        } header: {
            Text("Preferences")
                .foregroundStyle(PairTheme.textSecondary)
        }
        .listRowBackground(PairTheme.surface)
    }

    private var proSection: some View {
        Section {
            if settings?.hasPro == true {
                settingsRow {
                    HStack {
                        Label("Pro Unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(PairTheme.textPrimary)
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(PairTheme.accent)
                    }
                }
            } else {
                Button {
                    showProAlert = true
                } label: {
                    HStack {
                        Label("Unlock Pro — $2.99", systemImage: "star.fill")
                            .foregroundStyle(PairTheme.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(PairTheme.textSecondary)
                            .font(.caption)
                    }
                }
                .listRowBackground(PairTheme.accent.opacity(0.1))
            }
        } header: {
            Text("Pro")
                .foregroundStyle(PairTheme.textSecondary)
        } footer: {
            if settings?.hasPro != true {
                Text("One-time purchase. Unlocks Nature & Classic themes, Hard grid, and Daily Challenge archive.")
                    .foregroundStyle(PairTheme.textSecondary)
            }
        }
        .listRowBackground(PairTheme.surface)
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset All Stats", systemImage: "trash.fill")
            }
        } header: {
            Text("Data")
                .foregroundStyle(PairTheme.textSecondary)
        }
        .listRowBackground(PairTheme.surface)
    }

    private var aboutSection: some View {
        Section {
            settingsRow {
                HStack {
                    Label("Version", systemImage: "info.circle.fill")
                        .foregroundStyle(PairTheme.textPrimary)
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(PairTheme.textSecondary)
                }
            }
            settingsRow {
                HStack {
                    Label("Bundle ID", systemImage: "building.2.fill")
                        .foregroundStyle(PairTheme.textPrimary)
                    Spacer()
                    Text("com.orbioom.pair")
                        .font(.caption)
                        .foregroundStyle(PairTheme.textSecondary)
                }
            }
        } header: {
            Text("About")
                .foregroundStyle(PairTheme.textSecondary)
        }
        .listRowBackground(PairTheme.surface)
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [PairResult.self, PairSettings.self], inMemory: true)
}
