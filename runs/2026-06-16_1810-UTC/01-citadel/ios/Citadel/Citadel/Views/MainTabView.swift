import SwiftUI

/// The primary tab container: Play, Stats, Rules, Settings.
struct MainTabView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            GameView()
                .tabItem {
                    Label("Play", systemImage: "suit.spade.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            RulesView()
                .tabItem {
                    Label("Rules", systemImage: "book.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Theme.accent)
    }
}

/// Shown only if SwiftData is fundamentally unavailable. A calm recoverable message.
struct StorageUnavailableView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Storage Unavailable")
                .font(.title2.weight(.semibold))
            Text("Citadel couldn't open its game storage. Please restart the app. Your settings are safe.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}
