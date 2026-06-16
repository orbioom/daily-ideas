import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false
    @State private var showRestored = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                gameplaySection
                feedbackSection
                proSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Purchases restored", isPresented: $showRestored) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Seek Pro is now unlocked on this device.")
            }
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

            Picker("Highlight color", selection: Binding(
                get: { settings.highlightTheme },
                set: { newValue in
                    if newValue.isPro && !pro.isPro {
                        showPaywall = true
                    } else {
                        settings.highlightTheme = newValue
                    }
                }
            )) {
                ForEach(HighlightTheme.allCases) { theme in
                    HStack {
                        Circle().fill(theme.color).frame(width: 14, height: 14)
                        Text(theme.rawValue + (theme.isPro && !pro.isPro ? " (Pro)" : ""))
                    }
                    .tag(theme)
                }
            }
        }
    }

    private var gameplaySection: some View {
        Section {
            Picker("Default difficulty", selection: Binding(
                get: { settings.defaultDifficulty },
                set: { settings.defaultDifficulty = $0 }
            )) {
                ForEach(Difficulty.allCases) { diff in
                    Text(diff.rawValue).tag(diff)
                }
            }
            Toggle("Allow diagonals", isOn: $settings.allowDiagonals)
            Toggle("Allow reverse words", isOn: $settings.allowReverse)
        } header: {
            Text("Gameplay")
        } footer: {
            Text("Diagonals and reverse words apply on Medium and Hard puzzles where supported.")
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
            Toggle("Sound effects", isOn: $settings.soundEnabled)
        }
    }

    private var proSection: some View {
        Section("Seek Pro") {
            if pro.isPro {
                HStack {
                    Label("Pro unlocked", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Seek Pro — \(pro.priceLabel)", systemImage: "crown.fill")
                }
                Button {
                    pro.restore()
                    showRestored = true
                } label: {
                    Label("Restore Purchase", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Packs")
                Spacer()
                Text("\(WordPackLibrary.all.count) themed").foregroundStyle(Theme.inkSoft)
            }
            Text("Seek is a calm, ad-free word search. No tracking, no pop-ups — just you and the grid.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
    }
}
