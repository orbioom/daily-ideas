import SwiftUI
import SwiftData

/// Persisted preferences + Pro management + How to Play + about.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @State private var showPaywall = false
    @State private var showHowTo = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                gameplaySection
                tileThemeSection
                proSection
                helpSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView(reason: .general) }
            .sheet(isPresented: $showHowTo) { HowToPlayView() }
            .alert("Reset statistics?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { resetStats() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your game history, daily results, and any saved game. Settings and Pro are kept.")
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
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(Theme.surface)
    }

    private var gameplaySection: some View {
        Section("Gameplay") {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
            Toggle(isOn: $settings.showFreeHints) {
                Label("Highlight free tiles", systemImage: "sparkle.magnifyingglass")
            }
            Toggle(isOn: $settings.confirmOnRestart) {
                Label("Confirm before restart", systemImage: "arrow.clockwise")
            }
        }
        .tint(Theme.accent)
        .listRowBackground(Theme.surface)
    }

    private var tileThemeSection: some View {
        Section {
            ForEach(TileTheme.allCases) { theme in
                Button {
                    if theme.isPro && !isPro {
                        showPaywall = true
                    } else {
                        settings.tileThemeRaw = theme.rawValue
                    }
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.backColor)
                            .frame(width: 30, height: 30)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.hairline, lineWidth: 1))
                        Text(theme.label).foregroundStyle(Theme.ink)
                        Spacer()
                        if theme.isPro && !isPro {
                            Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint).font(.system(size: 13))
                        } else if settings.tileThemeRaw == theme.rawValue {
                            Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                        }
                    }
                }
                .accessibilityLabel("\(theme.label) tile theme\(theme.isPro && !isPro ? ", locked" : "")")
            }
        } header: {
            Text("Tile theme")
        } footer: {
            Text("Jade and Midnight themes are part of Lantern Pro.")
        }
        .listRowBackground(Theme.surface)
    }

    private var proSection: some View {
        Section("Lantern Pro") {
            if isPro {
                Label("Pro unlocked — thank you", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Lantern Pro", systemImage: "lightbulb.max.fill")
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(Pro.priceLabel).foregroundStyle(Theme.inkSoft)
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint).font(.system(size: 13))
                    }
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var helpSection: some View {
        Section("Help") {
            Button {
                showHowTo = true
            } label: {
                Label("How to Play", systemImage: "questionmark.circle")
                    .foregroundStyle(Theme.ink)
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset statistics", systemImage: "trash")
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version").foregroundStyle(Theme.ink)
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
            Text("Lantern is an ad-free, one-time-unlock game of Mahjong solitaire. No accounts, no pop-ups, no data selling.")
                .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
        } header: {
            Text("About")
        }
        .listRowBackground(Theme.surface)
    }

    private func resetStats() {
        delete(GameRecord.self)
        delete(DailyResult.self)
        delete(SavedGame.self)
        try? modelContext.save()
    }

    private func delete<T: PersistentModel>(_ type: T.Type) {
        let descriptor = FetchDescriptor<T>()
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }
}
