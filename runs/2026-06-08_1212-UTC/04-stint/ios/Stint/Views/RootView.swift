import SwiftUI
import SwiftData

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    private var appearance: AppearanceMode { AppearanceMode(rawValue: appearanceRaw) ?? .system }

    var body: some View {
        Group {
            if hasOnboarded { MainTabView() } else { OnboardingView() }
        }
        .tint(Color.accentColor)
        .preferredColorScheme(appearance.colorScheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
            EntriesView()
                .tabItem { Label("Entries", systemImage: "list.bullet.rectangle") }
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "folder.fill") }
            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.pie.fill") }
        }
    }
}
