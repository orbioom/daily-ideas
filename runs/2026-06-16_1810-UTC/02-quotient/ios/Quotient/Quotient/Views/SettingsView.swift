import SwiftUI
import SwiftData

/// App settings: gameplay preferences, accessibility-friendly toggles, Pro
/// management, theme picker, and About. All prefs persist via @AppStorage.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Functional persisted preferences.
    @AppStorage("highlightConflicts") private var highlightConflicts = true
    @AppStorage("highlightRelated") private var highlightRelated = true
    @AppStorage("autoRemoveNotes") private var autoRemoveNotes = true
    @AppStorage("checkMistakes") private var checkMistakes = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("showTimer") private var showTimer = true
    @AppStorage("mistakeLimit") private var mistakeLimit = 0
    @AppStorage("isPro") private var isPro = false
    @AppStorage("accentTheme") private var accentThemeRaw = AccentTheme.indigo.rawValue

    @State private var showingPaywall = false
    @State private var showingResetConfirm = false

    private var accentTheme: AccentTheme {
        AccentTheme(rawValue: accentThemeRaw) ?? .indigo
    }

    var body: some View {
        NavigationStack {
            Form {
                gameplaySection
                appearanceSection
                feedbackSection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .alert("Reset all stats?", isPresented: $showingResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetStats() }
            } message: {
                Text("This permanently deletes your solve history, streaks, and saved games. This can't be undone.")
            }
        }
    }

    private var gameplaySection: some View {
        Section {
            Toggle("Highlight conflicts", isOn: $highlightConflicts)
                .accessibilityHint("Marks cells that break a row, column, or cage rule")
            Toggle("Highlight row, column & cage", isOn: $highlightRelated)
                .accessibilityHint("Tints cells related to your selection")
            Toggle("Auto-remove candidate notes", isOn: $autoRemoveNotes)
                .accessibilityHint("Clears pencil marks affected by a placed number")
            Toggle("Check mistakes", isOn: $checkMistakes)
                .accessibilityHint("Counts a mistake when a placed value is wrong")
        } header: {
            Text("Gameplay")
        } footer: {
            Text("These change how the board assists you while solving.")
        }
        .tint(Theme.accent)
    }

    private var appearanceSection: some View {
        Section {
            Toggle("Show timer", isOn: $showTimer)
            Picker("Accent theme", selection: $accentThemeRaw) {
                ForEach(AccentTheme.allCases) { theme in
                    HStack {
                        Circle().fill(theme.color).frame(width: 16, height: 16)
                        Text(theme.displayName + (theme.isPremium && !isPro ? " (Pro)" : ""))
                    }
                    .tag(theme.rawValue)
                }
            }
            .onChange(of: accentThemeRaw) { _, newValue in
                let theme = AccentTheme(rawValue: newValue) ?? .indigo
                if theme.isPremium && !isPro {
                    // Revert to indigo and offer the paywall.
                    accentThemeRaw = AccentTheme.indigo.rawValue
                    showingPaywall = true
                }
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Extra accent themes are included with Quotient Pro.")
        }
        .tint(Theme.accent)
    }

    private var feedbackSection: some View {
        Section {
            Toggle("Haptics", isOn: $haptics)
                .accessibilityHint("Subtle vibration on key actions")
            Picker("Mistake limit", selection: $mistakeLimit) {
                Text("Off").tag(0)
                Text("3").tag(3)
                Text("5").tag(5)
                Text("10").tag(10)
            }
        } header: {
            Text("Feedback")
        } footer: {
            Text("A mistake limit shows a gentle warning once reached — you can always keep playing.")
        }
        .tint(Theme.accent)
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Quotient Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Active")
                        .foregroundStyle(Theme.success)
                        .font(.subheadline.weight(.semibold))
                }
                Button("Restore / Manage") { showingPaywall = true }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Quotient Pro", systemImage: "crown")
                        Spacer()
                        Text("$2.99")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        } header: {
            Text("Quotient Pro")
        }
        .tint(Theme.accent)
    }

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Label("Reset stats & saved games", systemImage: "trash")
            }
        } header: {
            Text("Data")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Accent", value: Theme.accentHex)
            Text("Quotient is a calm, ad-free Calcudoku puzzle with a real generator and a uniqueness-checking solver.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        } header: {
            Text("About")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func resetStats() {
        do {
            try modelContext.delete(model: PuzzleResult.self)
            try modelContext.delete(model: SavedGame.self)
            try modelContext.save()
        } catch {
            // Non-fatal: if the bulk delete fails we simply leave data intact.
        }
    }
}
