import SwiftUI

/// Settings: persisted gameplay & accessibility preferences, plus Pro / About rows.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.hardMode) private var hardMode: Bool = false
    @AppStorage(PrefKey.highContrastColors) private var highContrast: Bool = false
    @AppStorage(PrefKey.hapticsEnabled) private var haptics: Bool = true
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                LexBackground()
                Form {
                    gameplaySection
                    accessibilitySection
                    proSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var gameplaySection: some View {
        Section {
            Toggle(isOn: $hardMode) {
                settingLabel("Hard mode", "Revealed hints must be reused", systemImage: "flame.fill")
            }
            .tint(LexTheme.green)
        } header: {
            Text("Gameplay")
        } footer: {
            Text("Hard mode applies to new guesses. It can be turned on or off any time.")
        }
        .listRowBackground(LexTheme.cardSurface(scheme))
    }

    private var accessibilitySection: some View {
        Section {
            Toggle(isOn: $highContrast) {
                settingLabel("High-contrast colors", "Orange & blue instead of green & yellow", systemImage: "eye.fill")
            }
            .tint(LexTheme.green)

            Toggle(isOn: $haptics) {
                settingLabel("Haptics", "Subtle taps on key actions", systemImage: "hand.tap.fill")
            }
            .tint(LexTheme.green)
        } header: {
            Text("Accessibility")
        }
        .listRowBackground(LexTheme.cardSurface(scheme))
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    settingLabel("Lexicon Pro", "All features unlocked", systemImage: "checkmark.seal.fill")
                    Spacer()
                    Text("Active")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LexTheme.green)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        settingLabel("Unlock Lexicon Pro", "Full archive, 6-letter words & more", systemImage: "crown.fill")
                        Spacer()
                        Text("$2.99").foregroundStyle(LexTheme.secondaryText(scheme))
                        Image(systemName: "chevron.right").font(.caption.weight(.bold))
                            .foregroundStyle(LexTheme.secondaryText(scheme))
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Pro")
        }
        .listRowBackground(LexTheme.cardSurface(scheme))
    }

    private var aboutSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    settingLabel("Restore Purchase", "Already bought Pro?", systemImage: "arrow.clockwise")
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                        .foregroundStyle(LexTheme.secondaryText(scheme))
                }
            }
            .buttonStyle(.plain)

            HStack {
                settingLabel("Version", nil, systemImage: "info.circle")
                Spacer()
                Text("1.0").foregroundStyle(LexTheme.secondaryText(scheme))
            }
        } header: {
            Text("About")
        } footer: {
            Text("Lexicon is ad-free and works fully offline. Made by Orbioom.")
        }
        .listRowBackground(LexTheme.cardSurface(scheme))
    }

    private func settingLabel(_ title: String, _ subtitle: String?, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(LexTheme.green)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(LexTheme.primaryText(scheme))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(LexTheme.secondaryText(scheme))
                }
            }
        }
    }
}
