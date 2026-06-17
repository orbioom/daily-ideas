import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context

    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(PrefKey.leftHandedToolbar) private var leftHanded: Bool = false
    @AppStorage(PrefKey.feltTheme) private var feltRaw: String = FeltTheme.emerald.rawValue
    @AppStorage(PrefKey.cardBackStyle) private var backRaw: String = CardBackStyle.lattice.rawValue
    @AppStorage(PrefKey.showTimer) private var showTimer: Bool = true
    @AppStorage(PrefKey.animationsEnabled) private var animationsEnabled: Bool = true
    @AppStorage(PrefKey.autoFlip) private var autoFlip: Bool = true
    @AppStorage(PrefKey.confirmNewGame) private var confirmNewGame: Bool = true

    @State private var showingPaywall = false
    @State private var showingProResetConfirm = false
    @State private var showingResetStatsConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Table
                Section("Table") {
                    Picker("Felt theme", selection: $feltRaw) {
                        ForEach(FeltTheme.allCases) { felt in
                            HStack {
                                Text(felt.rawValue)
                                if felt.requiresPro && !isPro {
                                    Image(systemName: "lock.fill")
                                }
                            }
                            .tag(felt.rawValue)
                        }
                    }
                    .onChange(of: feltRaw) { _, newValue in
                        // Gate Pro felts: revert if a non-Pro user picks one.
                        if let felt = FeltTheme(rawValue: newValue), felt.requiresPro && !isPro {
                            feltRaw = FeltTheme.emerald.rawValue
                            showingPaywall = true
                        }
                    }
                    .accessibilityHint("Sapphire and Wine require Spindle Pro")

                    Picker("Card back", selection: $backRaw) {
                        ForEach(CardBackStyle.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                }

                // MARK: Gameplay
                Section("Gameplay") {
                    Toggle("Show timer", isOn: $showTimer)
                        .tint(SpindleTheme.emerald)
                    Toggle("Auto-flip exposed cards", isOn: $autoFlip)
                        .tint(SpindleTheme.emerald)
                        .accessibilityHint("Newly revealed cards turn face-up automatically")
                    Toggle("Confirm before new game", isOn: $confirmNewGame)
                        .tint(SpindleTheme.emerald)
                    Toggle("Animations", isOn: $animationsEnabled)
                        .tint(SpindleTheme.emerald)
                        .accessibilityHint("Reduce Motion is always respected regardless of this setting")
                }

                // MARK: Controls
                Section("Controls") {
                    Toggle("Left-handed toolbar", isOn: $leftHanded)
                        .tint(SpindleTheme.emerald)
                        .accessibilityHint("Moves game actions to the left side of the bar")
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .tint(SpindleTheme.emerald)
                        .accessibilityHint("Subtle vibration on moves and wins")
                }

                // MARK: Pro
                Section("Spindle Pro") {
                    if isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(SpindleTheme.emeraldDeep)
                        Button("Return to free (demo)", role: .destructive) {
                            showingProResetConfirm = true
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Label("Unlock Spindle Pro", systemImage: "crown")
                                Spacer()
                                Text("$2.99").foregroundStyle(SpindleTheme.secondaryText(scheme))
                            }
                        }
                    }
                }

                // MARK: Data
                Section("Data") {
                    Button("Reset stats", role: .destructive) {
                        showingResetStatsConfirm = true
                    }
                }

                // MARK: About
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Made by", value: "Orbioom")
                    Text("Spindle is an ad-free, calm Spider Solitaire with deterministic Daily Deals, three suit modes and a felt you can make your own.")
                        .font(.footnote)
                        .foregroundStyle(SpindleTheme.secondaryText(scheme))
                }

                Section {
                    Text("Spindle is a relaxation game. There is no real-money wagering, and Daily Deals are for fun and personal best-chasing only.")
                        .font(.footnote)
                        .foregroundStyle(SpindleTheme.secondaryText(scheme))
                } header: {
                    Text("Disclaimer")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .alert("Return to free?", isPresented: $showingProResetConfirm) {
                Button("Return to free", role: .destructive) { isPro = false }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This demo toggle removes Pro so you can see the free limits again.")
            }
            .alert("Reset stats?", isPresented: $showingResetStatsConfirm) {
                Button("Reset", role: .destructive) { resetStats() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your game history. Your saved game in progress is kept.")
            }
        }
    }

    private func resetStats() {
        do {
            try context.delete(model: GameResult.self)
            try context.save()
        } catch {
            // Non-fatal: leave existing data if the bulk delete fails.
        }
        Haptics.warning()
    }
}
