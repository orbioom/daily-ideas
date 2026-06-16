import SwiftUI
import SwiftData

/// Settings: persisted preferences, Pro management, and About.
struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKeys.autoMoveEnabled) private var autoMoveEnabled = true
    @AppStorage(SettingsKeys.confirmNewGame) private var confirmNewGame = true
    @AppStorage(SettingsKeys.leftHandLayout) private var leftHandLayout = false
    @AppStorage(SettingsKeys.feltStyle) private var feltRaw = FeltStyle.emerald.rawValue
    @AppStorage("isPro") private var isPro = false

    @State private var showPaywall = false
    @State private var showResetConfirm = false

    private var selectedFelt: FeltStyle { FeltStyle(rawValue: feltRaw) ?? .emerald }

    var body: some View {
        NavigationStack {
            Form {
                gameplaySection
                appearanceSection
                proSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog(
                "Reset statistics?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete all stats", role: .destructive) { resetStats() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your game history. This can't be undone.")
            }
        }
    }

    // MARK: - Gameplay

    private var gameplaySection: some View {
        Section {
            Toggle(isOn: $hapticsEnabled) {
                settingLabel("Haptics", "Gentle taps as you play", "iphone.radiowaves.left.and.right")
            }
            .accessibilityHint("Turns vibration feedback on or off")

            Toggle(isOn: $autoMoveEnabled) {
                settingLabel("Tap to send home", "Tapping a ready card moves it to its foundation", "arrow.up.to.line")
            }

            Toggle(isOn: $confirmNewGame) {
                settingLabel("Confirm new game", "Ask before abandoning a game in progress", "exclamationmark.bubble")
            }

            Toggle(isOn: $leftHandLayout) {
                settingLabel("Left-hand layout", "Free cells on the left, foundations on the right", "hand.point.left")
            }
        } header: {
            Text("Gameplay")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            ForEach(FeltStyle.allCases) { style in
                Button {
                    selectFelt(style)
                } label: {
                    HStack(spacing: 12) {
                        feltSwatch(style)
                        Text(style.displayName)
                            .foregroundStyle(.primary)
                        if style.requiresPro && !isPro {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.gold)
                                .accessibilityHidden(true)
                        }
                        Spacer()
                        if selectedFelt == style {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .accessibilityLabel("\(style.displayName) felt")
                .accessibilityValue(selectedFelt == style ? "Selected" : (style.requiresPro && !isPro ? "Locked, requires Pro" : ""))
            }
        } header: {
            Text("Felt theme")
        } footer: {
            Text("Extra felt colors are part of Citadel Pro.")
        }
    }

    @ViewBuilder
    private func feltSwatch(_ style: FeltStyle) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(colorScheme == .dark ? style.darkFelt() : style.lightFelt())
            .frame(width: 34, height: 24)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Theme.gold)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Citadel Pro active")
                            .font(.body.weight(.semibold))
                        Text("Thank you for supporting calm, ad-free play.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Theme.gold)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Citadel Pro")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Numbered deals, unlimited undo, more themes, full stats")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
            }
        } header: {
            Text("Citadel Pro")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Text("Reset statistics")
            }
        } header: {
            Text("About")
        } footer: {
            Text("Citadel is a calm, ad-free FreeCell. Deal numbers follow the classic catalog. Not affiliated with Microsoft. Made with care by Orbioom.")
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingLabel(_ title: String, _ subtitle: String, _ symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func selectFelt(_ style: FeltStyle) {
        if style.requiresPro && !isPro {
            showPaywall = true
            return
        }
        feltRaw = style.rawValue
    }

    private func resetStats() {
        do {
            try modelContext.delete(model: GameResult.self)
            try modelContext.save()
        } catch {
            // Calm no-op: if deletion fails, stats simply remain. No crash.
        }
    }
}
