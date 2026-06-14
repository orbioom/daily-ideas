import SwiftUI
import SwiftData

/// Top-level tab navigation: Home, Daily, Stats, Settings.
struct RootView: View {
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Play", systemImage: "square.grid.3x3.fill") }

            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
        .preferredColorScheme((AppTheme(rawValue: appThemeRaw) ?? .system).colorScheme)
    }
}

/// User-selectable color scheme preference.
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [GameRecord.self, SavedGame.self, DailyResult.self], inMemory: true)
}
